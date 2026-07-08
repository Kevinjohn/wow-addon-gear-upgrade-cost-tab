-- Locale regression harness: mocks just enough of the WoW environment to
-- load the addon's Lua files, then checks per locale that
--   * the locale file loads and only overrides known enUS keys,
--   * the format-string-derived primary parser works — proven with a track
--     name no map contains, which the fallback path cannot return,
--   * EVERY track-name alias the locale ships (derived from the loaded
--     L.TRACK_NAMES, so this file can never drift from the locale files)
--     parses via the primary path AND the prefix-stripping fallback,
--     including no-break-space prefixes,
--   * each alias resolves to a canonical ns.TRACKS entry with correct
--     costs, and
--   * junk lines (durability, set counts, missing separators) never parse.
--
-- Run from the repo root:  lua tests/run.lua
-- (WoW runs Lua 5.1; the files under test avoid version-specific syntax, so
-- any Lua >= 5.1 works here.)

-- Root layout: the addon's Lua sits at the repo root, so files load with no
-- addon-subfolder prefix (Locales/enUS.lua, Data.lua, …).
local ADDON_DIR = ""

local failures, checks = {}, 0
local function check(ok, label)
	checks = checks + 1
	if not ok then
		failures[#failures + 1] = label
		io.write("FAIL  ", label, "\n")
	end
end

------------------------------------------------------------------------------
-- WoW environment mock
------------------------------------------------------------------------------

local mockState = {}

local function installWowGlobals(locale)
	-- Lua extensions
	_G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
	_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	_G.GetLocale = function() return locale end

	-- Inventory slot constants (values mirror the real client)
	local invSlots = {
		INVSLOT_HEAD = 1, INVSLOT_NECK = 2, INVSLOT_SHOULDER = 3,
		INVSLOT_CHEST = 5, INVSLOT_WAIST = 6, INVSLOT_LEGS = 7,
		INVSLOT_FEET = 8, INVSLOT_WRIST = 9, INVSLOT_HAND = 10,
		INVSLOT_FINGER1 = 11, INVSLOT_FINGER2 = 12,
		INVSLOT_TRINKET1 = 13, INVSLOT_TRINKET2 = 14,
		INVSLOT_BACK = 15, INVSLOT_MAINHAND = 16, INVSLOT_OFFHAND = 17,
	}
	for name, id in pairs(invSlots) do _G[name] = id end

	-- Slot label global strings (display-only in these tests)
	for _, name in ipairs({
		"HEADSLOT", "NECKSLOT", "SHOULDERSLOT", "BACKSLOT", "CHESTSLOT",
		"WRISTSLOT", "HANDSSLOT", "WAISTSLOT", "LEGSSLOT", "FEETSLOT",
		"FINGER0SLOT", "TRINKET0SLOT", "MAINHANDSLOT", "INVTYPE_WEAPONOFFHAND",
	}) do
		_G[name] = name
	end

	-- Blizzard global strings consumed by Locales/enUS.lua
	_G.EQUIPPED = "Equipped"
	_G.ITEM_LEVEL_ABBR = "iLvl"

	_G.NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
	_G.ITEM_ACCOUNTBOUND_UNTIL_EQUIP = "Warbound until equipped"
	_G.ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP = "Binds to your Warband until equipped"

	_G.GetAchievementInfo = function() return nil end
	_G.GetCurrencyString = function() return "" end
	_G.C_ItemUpgrade = {}

	-- One equipped head item whose tooltip is set per test case
	_G.GetInventoryItemLink = function(_, slotID)
		return slotID == invSlots.INVSLOT_HEAD and mockState.itemLink or nil
	end
	_G.C_Item = {
		GetDetailedItemLevelInfo = function() return mockState.itemLevel end,
		GetItemInfoInstant = function() return nil end,
	}
	_G.C_TooltipInfo = {
		GetInventoryItem = function()
			return { lines = mockState.tooltipLines }
		end,
		GetBagItem = function() return nil end,
	}
	_G.C_Container = {
		GetContainerNumSlots = function() return 0 end,
		GetContainerItemLink = function() return nil end,
	}
end

local function loadAddon(locale, localeFile)
	installWowGlobals(locale)
	local ns = {}
	local function run(path)
		local chunk = assert(loadfile(ADDON_DIR .. path))
		chunk("GearUpgradeCostTab", ns)
	end
	run("Locales/enUS.lua")
	if localeFile then
		run("Locales/" .. localeFile .. ".lua")
	end
	run("Data.lua")
	run("Scanner.lua")
	return ns
end

------------------------------------------------------------------------------
-- Fixtures: only data the addon cannot supply itself (see the fixtures file)
------------------------------------------------------------------------------

local LOCALE_DATA = {
	{ locale = "enUS", file = nil, formatString = "Upgrade Level: %s %d/%d" },
}
-- A broken fixtures file must fail the run loudly, not silently shrink the
-- suite to enUS-only, so no pcall here.
for _, entry in ipairs(dofile("tests/locale_fixtures.lua")) do
	LOCALE_DATA[#LOCALE_DATA + 1] = entry
end

-- Canonical track keys, taken from the loaded addon so a future track added
-- to ns.TRACKS is covered without touching the harness.
local function sortedTrackKeys(ns)
	local keys = {}
	for key in pairs(ns.TRACKS) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

-- canonical key -> sorted list of tooltip names that must resolve to it,
-- derived from the loaded locale's L.TRACK_NAMES. English tooltips carry
-- the canonical names themselves, so canonicals fill any gap.
local function aliasesByCanonical(ns)
	local map = {}
	for _, canonical in ipairs(sortedTrackKeys(ns)) do
		map[canonical] = {}
	end
	for localized, canonical in pairs(ns.L.TRACK_NAMES) do
		check(map[canonical] ~= nil,
			"TRACK_NAMES maps '" .. tostring(localized) .. "' to unknown track '" .. tostring(canonical) .. "'")
		if map[canonical] then
			table.insert(map[canonical], localized)
		end
	end
	for canonical, list in pairs(map) do
		if #list == 0 then
			table.insert(list, canonical)
		end
		table.sort(list)
	end
	return map
end

------------------------------------------------------------------------------
-- The tests
------------------------------------------------------------------------------

local function firstEquippedRow(ns)
	local rows = ns.BuildEquippedRows()
	return rows and rows[1] or nil
end

local FULLWIDTH_COLON = "\239\188\154" -- "：", used by zhCN/zhTW prefixes

-- Mirrors Scanner.lua's EndsInCJK: true when the final character is a
-- 3-or-4-byte UTF-8 sequence (lead byte >= 0xE0). CJK tooltips may fuse
-- the track name to the rank; Latin/Cyrillic ones never do.
local function endsInCJK(text)
	for index = #text, 1, -1 do
		local byte = text:byte(index)
		if byte < 128 then
			return false
		elseif byte >= 192 then
			return byte >= 224
		end
	end
	return false
end

local function buildLine(formatString, track, current, max)
	return (formatString:gsub("%%s", track):gsub("%%d", tostring(current), 1):gsub("%%d", tostring(max), 1))
end

-- enUS keys are the contract: locale files must not invent keys, or the
-- override would silently never be read. Computed once.
local baseKeys = {}
for key in pairs(loadAddon("enUS", nil).L) do
	baseKeys[key] = true
end

local function testLocale(entry)
	local tag = entry.locale
	local ns = loadAddon(entry.locale, entry.file)
	mockState.itemLink = "|cffa335ee|Hitem:229999::::::::80:::::|h[Test Helm]|h|r"
	mockState.itemLevel = 480

	for key in pairs(ns.L) do
		check(baseKeys[key], tag .. ": unknown L key '" .. tostring(key) .. "'")
	end
	for id, name in pairs(ns.L.ACHIEVEMENT_NAMES) do
		check(type(id) == "number" and type(name) == "string",
			tag .. ": ACHIEVEMENT_NAMES must map achievementID -> name, got " .. tostring(id))
	end
	for id, name in pairs(entry.expectAchievements or {}) do
		check(ns.L.ACHIEVEMENT_NAMES[id] == name,
			tag .. (": achievement %d should be %q"):format(id, name))
	end

	-- Primary path, isolated: the fallback can also parse lines whose name
	-- is a known track, so prove the format-string-derived pattern itself
	-- works with a name no map contains — only the primary path returns it.
	_G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING = entry.formatString
	mockState.tooltipLines = { { leftText = buildLine(entry.formatString, "Zzyzx", 2, 8) } }
	local unknownRow = firstEquippedRow(ns)
	check(unknownRow and unknownRow.track == "Zzyzx" and unknownRow.rank == 2 and unknownRow.maxRank == 8,
		tag .. ": primary-only parse of an unknown track")

	local aliases = aliasesByCanonical(ns)
	for _, canonical in ipairs(sortedTrackKeys(ns)) do
		for _, localized in ipairs(aliases[canonical]) do
			-- Primary path: line built from the locale's real format string
			local line = buildLine(entry.formatString, localized, 4, 6)
			mockState.tooltipLines = { { leftText = line } }
			local row = firstEquippedRow(ns)
			check(row and row.track == localized and row.rank == 4 and row.maxRank == 6,
				tag .. ": primary parse of '" .. line .. "'")

			-- Canonical resolution feeds every cost lookup
			local trackInfo = ns.GetTrackInfo(localized)
			check(trackInfo == ns.TRACKS[canonical], tag .. ": GetTrackInfo(" .. localized .. ")")
			if trackInfo and row then
				local costs = ns.GetCosts(trackInfo, row.rank, row.maxRank, "base")
				check(costs and costs.nextCost == 20 and costs.totalCost == 40,
					tag .. ": costs for " .. localized)
			end
		end
	end

	-- Fallback path: format string unavailable, parser must still match
	-- every alias — bare, behind a "Label:"-style prefix, and behind a
	-- no-break-space (U+00A0) prefix as some locales typeset colons. A
	-- fresh load is required because the derived pattern is cached.
	local nsFallback = loadAddon(entry.locale, entry.file)
	_G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING = nil
	for _, canonical in ipairs(sortedTrackKeys(nsFallback)) do
		for _, localized in ipairs(aliases[canonical]) do
			for _, line in ipairs({
				localized .. " 2/6",
				"Prefix Label: " .. localized .. " 2/6",
				"Pr\195\169fixe\194\160:\194\160" .. localized .. " 2/6",
				localized .. "\194\160" .. "2/6",
				"Prefix" .. FULLWIDTH_COLON .. " " .. localized .. " 2/6",
			}) do
				mockState.tooltipLines = { { leftText = line } }
				local row = firstEquippedRow(nsFallback)
				check(row and row.track == localized and row.rank == 2 and row.maxRank == 6,
					tag .. ": fallback parse of '" .. line .. "'")
			end
			-- A name fused to the rank with no separator: real for CJK
			-- locales (zhTW's legacy lines read "等級提升：精兵1/8"), so it
			-- must parse there — and ONLY there, so Latin/Cyrillic text
			-- fused to digits still can't false-match.
			for _, fusedLine in ipairs({
				localized .. "2/6",
				"Prefix" .. FULLWIDTH_COLON .. localized .. "2/6",
			}) do
				mockState.tooltipLines = { { leftText = fusedLine } }
				local fused = firstEquippedRow(nsFallback)
				if endsInCJK(localized) then
					check(fused and fused.track == localized and fused.rank == 2 and fused.maxRank == 6,
						tag .. ": fused CJK line parsed '" .. fusedLine .. "'")
				else
					check(fused and fused.track == nil,
						tag .. ": no-separator line rejected '" .. fusedLine .. "'")
				end
			end
		end
	end

	-- Junk must never parse as a track, on either path
	for _, junk in ipairs({ "Durability 100/120", "100/120", "Soulknife Battlegear (2/5)" }) do
		_G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING = entry.formatString
		mockState.tooltipLines = { { leftText = junk } }
		local row = firstEquippedRow(ns)
		check(row and row.track == nil, tag .. ": junk line rejected '" .. junk .. "'")
	end
end

-- Synthetic positional format strings exercise the pattern builder the way
-- koKR-style locales would: reordered specifiers, including the max rank
-- printed before the current rank.
local function testReorderedFormatStrings(formatString, line, rank, maxRank)
	local ns = loadAddon("enUS", nil)
	_G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING = formatString
	mockState.itemLink = "|cffa335ee|Hitem:229999|h[Test Helm]|h|r"
	mockState.itemLevel = 480
	mockState.tooltipLines = { { leftText = line } }
	local row = firstEquippedRow(ns)
	check(row and row.track == "Champion" and row.rank == rank and row.maxRank == maxRank,
		("synthetic: '%s' parses '%s' as %d/%d"):format(formatString, line, rank, maxRank))
end

-- ns.GetSlotMaxItemLevel: watermark API result vs. the equipped-item
-- fallback, including the two-item slots (rings, trinkets) where a level
-- only counts once BOTH slots hold an item at it (see Data.lua's
-- TWO_ITEM_EQUIP_LOCS comment for the bug this guards against).
local function testSlotMaxItemLevel()
	local ns = loadAddon("enUS", nil)

	-- Override installWowGlobals' single-head-item fixture with a
	-- configurable equipped[invSlot] = itemLevel map, keyed by inventory
	-- slot id (fingers 11/12, trinkets 13/14, head 1).
	local equipped = {}
	_G.GetInventoryItemLink = function(_, invSlot)
		return equipped[invSlot] and ("link" .. invSlot) or nil
	end
	_G.C_Item.GetDetailedItemLevelInfo = function(link)
		local invSlot = tonumber(link:match("^link(%d+)$"))
		return invSlot and equipped[invSlot]
	end

	local function setEquipped(t)
		equipped = t
	end

	local function setWatermark(value)
		_G.C_ItemUpgrade = value
			and { GetHighWatermarkForItem = function() return value, 0 end }
			or {}
	end

	setEquipped({ [INVSLOT_FINGER1] = 480, [INVSLOT_FINGER2] = 450 })
	setWatermark(nil)
	check(ns.GetSlotMaxItemLevel("ringlink", "INVTYPE_FINGER") == 450,
		"GetSlotMaxItemLevel: both rings equipped (480/450), no API -> lower (450)")

	setEquipped({ [INVSLOT_FINGER1] = 480 })
	check(ns.GetSlotMaxItemLevel("ringlink", "INVTYPE_FINGER") == nil,
		"GetSlotMaxItemLevel: only one ring equipped (480), no API -> nil")

	setEquipped({})
	check(ns.GetSlotMaxItemLevel("ringlink", "INVTYPE_FINGER") == nil,
		"GetSlotMaxItemLevel: no rings equipped, no API -> nil")

	setEquipped({ [INVSLOT_FINGER1] = 480, [INVSLOT_FINGER2] = 450 })
	setWatermark(470)
	check(ns.GetSlotMaxItemLevel("ringlink", "INVTYPE_FINGER") == 470,
		"GetSlotMaxItemLevel: rings 480/450, API returns 470 -> API wins (470)")

	setWatermark(nil)
	setEquipped({ [INVSLOT_TRINKET1] = 460, [INVSLOT_TRINKET2] = 440 })
	check(ns.GetSlotMaxItemLevel("trinketlink", "INVTYPE_TRINKET") == 440,
		"GetSlotMaxItemLevel: both trinkets equipped (460/440), no API -> lower (440)")

	setEquipped({ [INVSLOT_HEAD] = 480 })
	check(ns.GetSlotMaxItemLevel("headlink", "INVTYPE_HEAD") == 480,
		"GetSlotMaxItemLevel: single-slot head equipped (480), no API -> 480 (max rule unchanged)")

	setEquipped({})
	check(ns.GetSlotMaxItemLevel("headlink", "INVTYPE_HEAD") == nil,
		"GetSlotMaxItemLevel: single-slot head empty, no API -> nil")
end

for _, entry in ipairs(LOCALE_DATA) do
	testLocale(entry)
end
testReorderedFormatStrings("%2$d/%3$d: %1$s", "3/6: Champion", 3, 6)
testReorderedFormatStrings("%3$d/%2$d %1$s", "6/3 Champion", 3, 6)
testSlotMaxItemLevel()

io.write(("%d checks, %d failures\n"):format(checks, #failures))
if #failures > 0 then
	os.exit(1)
end
