local _, ns = ...

-- The upgrade line ("Upgrade Level: Champion 5/6") is only exposed through
-- tooltip data; there is no general API for it while the upgrade vendor UI
-- is closed. We derive a match pattern from Blizzard's own format string so
-- it keeps working across locales, with a plain-text fallback.
local upgradePattern -- nil = not built yet, false = global string unavailable

local function BuildUpgradePattern()
	local format = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING
	if type(format) ~= "string" then
		return false
	end
	-- Swap format specifiers for placeholders, escape Lua pattern magic
	-- characters, then turn the placeholders into captures.
	format = format:gsub("%%%d*%$?s", "\001"):gsub("%%%d*%$?d", "\002")
	format = format:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	format = format:gsub("\001", "(.-)"):gsub("\002", "(%%d+)")
	return "^%s*" .. format .. "%s*$"
end

local function ParseUpgradeLine(text)
	if upgradePattern == nil then
		upgradePattern = BuildUpgradePattern()
	end

	if upgradePattern then
		local a, b, c = text:match(upgradePattern)
		if a then
			-- Locales may reorder the captures; the non-numeric one is the
			-- track name, the numeric ones are current/max rank in order.
			local numbers, track = {}, nil
			for _, capture in ipairs({ a, b, c }) do
				local number = tonumber(capture)
				if number then
					numbers[#numbers + 1] = number
				else
					track = capture
				end
			end
			if track and #numbers == 2 then
				return strtrim(track), numbers[1], numbers[2]
			end
		end
	end

	-- Fallback: "... Champion 5/6". Only trusted when the captured name is a
	-- known track, so lines like durability or set counts can't false-match.
	local track, current, max = text:match("([%a%s]+)%s+(%d+)/(%d+)%s*$")
	if track then
		track = strtrim(track)
		if ns.TRACKS[track] then
			return track, tonumber(current), tonumber(max)
		end
	end
	return nil
end

-- Finds the upgrade line in tooltip data; returns track, rank, maxRank.
local function ParseUpgradeFromTooltip(tooltipData)
	if not (tooltipData and tooltipData.lines) then
		return nil
	end
	for _, line in ipairs(tooltipData.lines) do
		if line.leftText then
			local track, current, max = ParseUpgradeLine(line.leftText)
			if track then
				return track, current, max
			end
		end
	end
	return nil
end

-- Builds one row of display data for an equipped slot, or nil if empty.
local function ScanEquippedSlot(slotEntry)
	local slotID = slotEntry.inv
	local itemLink = GetInventoryItemLink("player", slotID)
	if not itemLink then
		return nil
	end

	local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	local row = {
		slotID = slotID,
		label = slotEntry.label,
		itemLink = itemLink,
		-- Round: scaled items can report fractional levels, and the
		-- watermark comparison in Data.lua assumes whole numbers.
		itemLevel = itemLevel and math.floor(itemLevel + 0.5) or nil,
	}

	row.track, row.rank, row.maxRank = ParseUpgradeFromTooltip(C_TooltipInfo.GetInventoryItem("player", slotID))
	return row
end

function ns.BuildEquippedRows()
	local rows = {}
	for _, slotEntry in ipairs(ns.SLOTS) do
		local row = ScanEquippedSlot(slotEntry)
		if row then
			rows[#rows + 1] = row
		end
	end
	return rows
end

------------------------------------------------------------------------------
-- Bag scanning (the "Free Upgrades" section)
------------------------------------------------------------------------------

-- Carried bags: backpack (0), four equipped bags (1-4), reagent bag (5).
-- Gear never sits in the reagent bag, but scanning it is cheap and avoids
-- caring whether one is equipped.
local FIRST_BAG = 0
local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5

-- INVSLOT id -> position in ns.SLOTS, so bag rows sort in paper-doll order.
local slotOrder
local function GetSortOrder(equipLoc)
	if not slotOrder then
		slotOrder = {}
		for index, slotEntry in ipairs(ns.SLOTS) do
			slotOrder[slotEntry.inv] = index
		end
	end
	local invSlots = ns.EQUIP_LOC_SLOTS[equipLoc]
	return (invSlots and slotOrder[invSlots[1]]) or math.huge
end

-- Display name straight from the link, keeping its quality color code.
local function ItemNameFromLink(itemLink)
	local name = itemLink:match("%[(.-)%]")
	if not name then
		return itemLink
	end
	local color = itemLink:match("^(|c[^|]+)")
	return color and (color .. name .. "|r") or name
end

-- "Warbound until equipped" items are excluded from all lists (user choice;
-- may become a toggle later). Both globals verified against live enUS
-- GlobalStrings 2026-06: ITEM_ACCOUNTBOUND_UNTIL_EQUIP is the line shown
-- while the item sits warbound in a bag, ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP
-- the "will bind this way" variant.
local function IsWarboundUntilEquipped(tooltipData)
	if not (tooltipData and tooltipData.lines) then
		return false
	end
	for _, line in ipairs(tooltipData.lines) do
		local text = line.leftText
		if text and (text == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or text == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP) then
			return true
		end
	end
	return false
end

local function ScanBagSlot(bag, slot, mode)
	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if not itemLink then
		return nil
	end
	-- Cheap filter first: only equippable items in slots we track can
	-- qualify, and GetItemInfoInstant needs no server round-trip.
	local equipLoc = select(4, C_Item.GetItemInfoInstant(itemLink))
	if not (equipLoc and ns.EQUIP_LOC_SLOTS[equipLoc]) then
		return nil
	end
	local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
	local track, rank, maxRank = ParseUpgradeFromTooltip(tooltipData)
	if not track then
		return nil -- not on an upgrade track
	end
	if IsWarboundUntilEquipped(tooltipData) then
		return nil
	end

	local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	itemLevel = itemLevel and math.floor(itemLevel + 0.5) or nil
	local watermark = ns.GetSlotMaxItemLevel(itemLink, equipLoc)
	local costs = ns.GetBagUpgradeCosts(ns.GetTrackInfo(track), rank, maxRank, mode, itemLevel, watermark)
	if not costs then
		return nil
	end

	return {
		isBagRow = true,
		bag = bag,
		slot = slot,
		itemLink = itemLink,
		name = ItemNameFromLink(itemLink),
		-- The INVTYPE_* globals hold localized display names ("Finger",
		-- "One-Hand", ...) keyed by the equip-location token itself.
		slotLabel = ns.EQUIP_LOC_LABEL_OVERRIDES[equipLoc] or _G[equipLoc],
		itemLevel = itemLevel,
		track = track,
		rank = rank,
		maxRank = maxRank,
		nextIsFree = costs.nextIsFree,
		nextCost = costs.nextCost,
		crestTotal = costs.crestTotal,
		sortOrder = GetSortOrder(equipLoc),
	}
end

-- Paper-doll slot order, then highest item level first.
local function SortBagRows(rows)
	table.sort(rows, function(a, b)
		if a.sortOrder ~= b.sortOrder then
			return a.sortOrder < b.sortOrder
		end
		if a.itemLevel ~= b.itemLevel then
			return (a.itemLevel or 0) > (b.itemLevel or 0)
		end
		return a.name < b.name
	end)
end

-- Scans carried bags once and splits upgradeable items into two EXCLUSIVE
-- lists, routed by what the next rank costs: freeRows (gold-only) or
-- crestRows (crests; unknown tracks land here with "?" costs).
function ns.BuildBagRows(mode)
	local freeRows, crestRows = {}, {}
	for bag = FIRST_BAG, LAST_BAG do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local row = ScanBagSlot(bag, slot, mode)
			if row then
				local rows = row.nextIsFree and freeRows or crestRows
				rows[#rows + 1] = row
			end
		end
	end
	SortBagRows(freeRows)
	SortBagRows(crestRows)
	return freeRows, crestRows
end

-- Registers every bag item with the loader so item data is cached before
-- BuildFreeUpgradeRows reads tooltips and item levels.
function ns.AddBagContinuables(container)
	for bag = FIRST_BAG, LAST_BAG do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			if C_Container.GetContainerItemLink(bag, slot) then
				container:AddContinuable(Item:CreateFromBagAndSlot(bag, slot))
			end
		end
	end
end
