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

	local tooltipData = C_TooltipInfo.GetInventoryItem("player", slotID)
	if tooltipData and tooltipData.lines then
		for _, line in ipairs(tooltipData.lines) do
			if line.leftText then
				local track, current, max = ParseUpgradeLine(line.leftText)
				if track then
					row.track, row.rank, row.maxRank = track, current, max
					break
				end
			end
		end
	end
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
