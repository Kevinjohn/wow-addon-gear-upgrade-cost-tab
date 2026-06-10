local _, ns = ...

-- The upgrade line ("Upgrade Level: Champion 5/6") is only exposed through
-- tooltip data; there is no general API for it while the upgrade vendor UI
-- is closed. We derive a match pattern from Blizzard's own format string so
-- it keeps working across locales, with a plain-text fallback.
local upgradePattern -- nil = not built yet, false = global string unavailable
-- For each capture in upgradePattern, the format argument it renders:
-- 1 = track name (%s), 2 = current rank, 3 = max rank. Derived rather than
-- assumed because positional locales ("%2$d/%3$d %1$s") may both move and
-- renumber the specifiers, including printing max before current.
local upgradeCaptureArgs

local function BuildUpgradePattern()
	local format = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING
	if type(format) ~= "string" then
		return false
	end
	-- Record each specifier's explicit argument index ("%2$d" -> 2) or,
	-- when unnumbered, its sequential position.
	local args, autoIndex = {}, 0
	for index in format:gmatch("%%(%d*)%$?[sd]") do
		autoIndex = autoIndex + 1
		args[#args + 1] = tonumber(index) or autoIndex
	end
	upgradeCaptureArgs = args
	-- Swap format specifiers for placeholders, escape Lua pattern magic
	-- characters, then turn the placeholders into captures.
	format = format:gsub("%%%d*%$?s", "\001"):gsub("%%%d*%$?d", "\002")
	format = format:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	format = format:gsub("\001", "(.-)"):gsub("\002", "(%%d+)")
	return "^%s*" .. format .. "%s*$"
end

-- Strips any "Label:" prefix at the last colon; returns the remaining name
-- only when it maps to a known track.
local function KnownTrackFromCapture(capture)
	local candidate = strtrim(capture:match("[^:]*$"))
	if candidate ~= "" and ns.GetTrackInfo(candidate) then
		return candidate
	end
	return nil
end

-- True when the string's final character is a 3-or-4-byte UTF-8 sequence
-- (lead byte >= 0xE0) — the CJK range. Latin is 1-2 bytes and Cyrillic 2,
-- so both stay excluded.
local function EndsInCJK(text)
	for index = #text, 1, -1 do
		local byte = text:byte(index)
		if byte < 128 then
			return false -- ASCII tail
		elseif byte >= 192 then
			return byte >= 224 -- found the final character's lead byte
		end
		-- 128-191 is a UTF-8 continuation byte; keep walking back
	end
	return false
end

local function ParseUpgradeLine(text)
	if upgradePattern == nil then
		upgradePattern = BuildUpgradePattern()
	end

	if upgradePattern then
		local captures = { text:match(upgradePattern) }
		if captures[1] ~= nil and #captures == #upgradeCaptureArgs then
			-- Route each capture back to the argument it rendered.
			local byArg = {}
			for index, capture in ipairs(captures) do
				byArg[upgradeCaptureArgs[index]] = capture
			end
			local track = byArg[1]
			local current, max = tonumber(byArg[2]), tonumber(byArg[3])
			if track and not tonumber(track) and current and max then
				return strtrim(track), current, max
			end
		end
	end

	-- Fallback: "... Champion 5/6". The name capture allows any characters
	-- ("%a" is ASCII-only, which would reject "Vétéran" or "Ветеран"), with
	-- a leading "Upgrade Level:"-style prefix stripped at the last colon.
	-- Only trusted when the name maps to a known track, so lines like
	-- durability or set counts can't false-match. The plain find skips the
	-- vast majority of lines at memchr speed; the match itself is anchored
	-- because an unanchored leading "(.-)" makes every non-matching line an
	-- O(n^2) scan for identical results (the lazy capture already absorbs
	-- any prefix). No-break spaces (some locales use U+00A0/U+202F around
	-- the colon) are folded to plain spaces first, since neither %s nor
	-- strtrim treats them as whitespace, and the fullwidth colon U+FF1A
	-- (zhCN/zhTW prefixes: "升级：") to ":" so the prefix strip sees it.
	if not text:find("/", 1, true) then
		return nil
	end
	local normalized = text:gsub("\194\160", " "):gsub("\226\128\175", " "):gsub("\239\188\154", ":")
	local track, current, max = normalized:match("^(.-)%s+(%d+)/(%d+)%s*$")
	local known = track and KnownTrackFromCapture(track)
	if known then
		return known, tonumber(current), tonumber(max)
	end
	-- CJK tooltips can fuse the name straight to the rank (zhTW's legacy
	-- lines read "等級提升：精兵1/8"). Allowed only when the name ends in
	-- a CJK character, so Latin or Cyrillic text fused to digits
	-- ("Veteran2/6") still can't false-match.
	track, current, max = normalized:match("^(.-)(%d+)/(%d+)%s*$")
	if track then
		local candidate = KnownTrackFromCapture(track)
		if candidate and EndsInCJK(candidate) then
			return candidate, tonumber(current), tonumber(max)
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

-- "Warbound until equipped" items are hidden from the bag lists unless the
-- "Include Warbound items" checkbox opts in: upgrading one soulbinds it
-- (the vendor's CONFIRM_UPGRADE_ITEM_BIND dialog says so). Both globals
-- verified against live enUS GlobalStrings 2026-06:
-- ITEM_ACCOUNTBOUND_UNTIL_EQUIP is the line shown while the item sits
-- warbound in a bag, ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP the "will bind this
-- way" variant.
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

-- Inventory slots whose equipped item is a set ("tier") piece worth
-- protecting: it belongs to an item set (ns.IsSetItem in Data.lua, with
-- the history of stronger legs that failed in-game testing) AND is
-- itself on an upgrade track — that is what scopes the filter to gear
-- the player is actually progressing (current or previous season) while
-- truly-legacy tier, which no current crest can upgrade, suppresses
-- nothing. GetItemInfo is safe inside the heuristic: every rebuild path
-- preloads equipped items via ContinuableContainer first.
function ns.GetEquippedTierSlots()
	local tierSlots = {}
	for _, slotEntry in ipairs(ns.SLOTS) do
		local itemLink = GetInventoryItemLink("player", slotEntry.inv)
		if itemLink and ns.IsSetItem(itemLink)
			and ParseUpgradeFromTooltip(C_TooltipInfo.GetInventoryItem("player", slotEntry.inv)) then
			tierSlots[slotEntry.inv] = true
		end
	end
	return tierSlots
end

local function ScanBagSlot(bag, slot, mode, options, tierSlots)
	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if not itemLink then
		return nil
	end
	-- Cheap filter first: only equippable items in slots we track can
	-- qualify, and GetItemInfoInstant needs no server round-trip.
	local equipLoc = select(4, C_Item.GetItemInfoInstant(itemLink))
	local invSlots = equipLoc and ns.EQUIP_LOC_SLOTS[equipLoc]
	if not invSlots then
		return nil
	end
	local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
	local track, rank, maxRank = ParseUpgradeFromTooltip(tooltipData)
	if not track then
		return nil -- not on an upgrade track
	end

	local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	itemLevel = itemLevel and math.floor(itemLevel + 0.5) or nil
	local watermark = ns.GetSlotMaxItemLevel(itemLink, equipLoc)
	local costs = ns.GetBagUpgradeCosts(ns.GetTrackInfo(track), rank, maxRank, mode, itemLevel, watermark)
	if not costs then
		return nil
	end

	-- The user-facing filters run LAST, on items that would otherwise be
	-- listed, so the second return value identifies exactly the rows the
	-- filters hid (and the section each would have landed in). That lets
	-- the UI say "hidden by your filters" instead of a false "nothing to
	-- upgrade" when a section comes back empty.
	local route = costs.nextIsFree and "free" or "crest"

	-- Quality filter: uncommon and rare gear is hidden unless opted in via
	-- the dropdown checkboxes. Epic and above always shows, and nothing
	-- below uncommon carries an upgrade track. GetContainerItemInfo is
	-- local data, no server round-trip.
	local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
	local quality = containerInfo and containerInfo.quality
	if (quality == Enum.ItemQuality.Uncommon and not options.includeUncommon)
		or (quality == Enum.ItemQuality.Rare and not options.includeRare) then
		return nil, route
	end

	-- Warbound filter: "Warbound until equipped" gear stays shareable
	-- across the warband only until someone upgrades it, so it is hidden
	-- unless opted in via the dropdown checkbox.
	if not options.includeWarbound and IsWarboundUntilEquipped(tooltipData) then
		return nil, route
	end

	-- "Prioritise tier": slots holding an equipped class-set piece keep
	-- their set bonus, so bag candidates for them are noise. Multi-slot
	-- locations (rings, trinkets, weapons) would only hide when EVERY slot
	-- they could occupy holds a set piece — in practice never, since class
	-- sets occupy single-slot locations.
	if tierSlots then
		local allTier = true
		for _, invSlot in ipairs(invSlots) do
			if not tierSlots[invSlot] then
				allTier = false
				break
			end
		end
		if allTier then
			return nil, route
		end
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
-- crestRows (crests; unknown tracks land here with "?" costs). The third
-- return counts the upgradeable rows the user's filters hid from each
-- section ({ free = n, crest = n }), so an empty section can say why.
-- options carries the saved bag filters (includeUncommon, includeRare,
-- includeWarbound, prioritiseTier); the UI passes its SavedVariables table
-- directly. Nil keys mean a caller without saved settings, so they get the
-- documented defaults: nil include* keys already read as "hide", and
-- nil prioritiseTier is explicitly defaulted ON below — otherwise such a
-- caller would get a quality-filtered-but-tier-unfiltered mix that
-- matches neither the defaults nor unfiltered output.
function ns.BuildBagRows(mode, options)
	options = options or {}
	local prioritiseTier = options.prioritiseTier
	if prioritiseTier == nil then
		prioritiseTier = true
	end
	-- Resolved once per scan, not per item: it walks every equipped slot.
	local tierSlots = prioritiseTier and ns.GetEquippedTierSlots() or nil
	local freeRows, crestRows = {}, {}
	local hidden = { free = 0, crest = 0 }
	for bag = FIRST_BAG, LAST_BAG do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local row, hiddenRoute = ScanBagSlot(bag, slot, mode, options, tierSlots)
			if row then
				local rows = row.nextIsFree and freeRows or crestRows
				rows[#rows + 1] = row
			elseif hiddenRoute then
				hidden[hiddenRoute] = hidden[hiddenRoute] + 1
			end
		end
	end
	SortBagRows(freeRows)
	SortBagRows(crestRows)
	return freeRows, crestRows, hidden
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
