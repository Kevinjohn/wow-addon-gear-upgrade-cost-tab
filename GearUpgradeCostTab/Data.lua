local _, ns = ...

-- enUS-first strings; gathered here so localization can be added later.
ns.L = {
	TAB_TITLE = "Gear Upgrades",
	EQUIPPED = "Equipped",
	IN_BAG = "In Bag",
	IN_BAG_PLACEHOLDER = "Bag scanning is coming in a future update.",
	COST_MODE_BASE = "Base costs",
	COST_MODE_DISCOUNT = "Discount aware",
	COST_MODE_DISCOUNT_TIP = "Halves crest costs for tracks with the warband \"... of the Dawn\" achievement, and marks upgrades below your slot high-watermark as free (gold only).",
	COL_SLOT = "Slot",
	COL_ILVL = "iLvl",
	COL_UPGRADE = "Upgrade",
	COL_NEXT = "Next",
	COL_MAX = "To 6/6",
	FREE = "Free",
	DASH = "\226\128\148", -- em dash
	UNKNOWN_COST = "?",
}

-- Equipped slots in the order requested (paper-doll order).
-- Labels use Blizzard's localized global strings. Both ring slots and both
-- trinket slots share a localized base name, so we number them.
-- Off-hand weapons and shields are the same inventory slot (17).
-- Shirt (4) and tabard (19) are intentionally excluded; no ranged slot exists.
ns.SLOTS = {
	{ inv = INVSLOT_HEAD, label = HEADSLOT },
	{ inv = INVSLOT_NECK, label = NECKSLOT },
	{ inv = INVSLOT_SHOULDER, label = SHOULDERSLOT },
	{ inv = INVSLOT_BACK, label = BACKSLOT },
	{ inv = INVSLOT_CHEST, label = CHESTSLOT },
	{ inv = INVSLOT_WRIST, label = WRISTSLOT },
	{ inv = INVSLOT_HAND, label = HANDSSLOT },
	{ inv = INVSLOT_WAIST, label = WAISTSLOT },
	{ inv = INVSLOT_LEGS, label = LEGSSLOT },
	{ inv = INVSLOT_FEET, label = FEETSLOT },
	{ inv = INVSLOT_FINGER1, label = FINGER0SLOT .. " 1" },
	{ inv = INVSLOT_FINGER2, label = FINGER0SLOT .. " 2" },
	{ inv = INVSLOT_TRINKET1, label = TRINKET0SLOT .. " 1" },
	{ inv = INVSLOT_TRINKET2, label = TRINKET0SLOT .. " 2" },
	{ inv = INVSLOT_MAINHAND, label = MAINHANDSLOT },
	{ inv = INVSLOT_OFFHAND, label = SECONDARYHANDSLOT },
}

-- Midnight (12.0) upgrade tracks. All values below are from third-party
-- guides (June 2026) and MUST be sanity-checked in game against the upgrade
-- vendor; they are isolated here so corrections are one-line edits.
--   crestCurrencyID: the track's Dawncrest currency. Adventurer=3383 per
--     Wowhead (3339 proved invalid in-game: no icon); Veteran/Champion/Hero
--     confirmed working in-game 2026-06; Myth untested until we have gear.
--   costPerRank: flat crests per upgrade rank (reported 20 for all slots).
--   achievementID: warband "X of the Dawn" achievement that halves costs.
--     IDs are unverified; achievementName guards against a wrong ID by
--     requiring the in-game achievement name to match before applying.
ns.TRACKS = {
	Adventurer = { maxRank = 6, crestCurrencyID = 3383, costPerRank = 20, achievementID = 61809, achievementName = "Adventurer of the Dawn" },
	Veteran    = { maxRank = 6, crestCurrencyID = 3341, costPerRank = 20, achievementID = nil,   achievementName = "Veteran of the Dawn" },
	Champion   = { maxRank = 6, crestCurrencyID = 3343, costPerRank = 20, achievementID = nil,   achievementName = "Champion of the Dawn" },
	Hero       = { maxRank = 6, crestCurrencyID = 3345, costPerRank = 20, achievementID = nil,   achievementName = "Hero of the Dawn" },
	Myth       = { maxRank = 6, crestCurrencyID = 3347, costPerRank = 20, achievementID = nil,   achievementName = "Myth of the Dawn" },
}

-- Approximate item levels gained per upgrade rank, used only to compare the
-- next rank against the slot high-watermark in discount-aware mode.
-- VERIFY IN-GAME: tracks span ~13 item levels over 5 steps in Midnight.
ns.ILVL_PER_RANK = 3

function ns.GetTrackInfo(trackName)
	return trackName and ns.TRACKS[trackName] or nil
end

local discountCache = {}
function ns.ClearDiscountCache()
	wipe(discountCache)
end

-- True when the track's warband discount achievement is verified and earned.
function ns.IsTrackDiscounted(trackInfo)
	local achievementID = trackInfo.achievementID
	if not achievementID then
		return false
	end
	if discountCache[achievementID] == nil then
		local ok, _, name, _, completed = pcall(GetAchievementInfo, achievementID)
		local nameMatches = ok and name and trackInfo.achievementName
			and name:find(trackInfo.achievementName, 1, true) ~= nil
		discountCache[achievementID] = (nameMatches and completed) or false
	end
	return discountCache[achievementID]
end

-- Account high-watermark for the equipped item, if the API is available.
-- C_ItemUpgrade.GetHighWatermarkForItem semantics are unverified for 12.0;
-- everything is guarded so discount mode degrades to achievement-only.
function ns.GetHighWatermark(slotID)
	local getWatermark = C_ItemUpgrade and C_ItemUpgrade.GetHighWatermarkForItem
	if type(getWatermark) ~= "function" then
		return nil
	end
	local location = ItemLocation:CreateFromEquipmentSlot(slotID)
	if not location or not C_Item.DoesItemExist(location) then
		return nil
	end
	local ok, characterWatermark, accountWatermark = pcall(getWatermark, location)
	if not ok then
		return nil
	end
	return accountWatermark or characterWatermark
end

-- Returns { maxed = true } when fully upgraded, nil for unknown tracks, or
-- { nextCost, totalCost, nextIsFree } in crests of the track's Dawncrest.
-- maxRank parsed from the tooltip takes priority over the static table, so a
-- patch that changes rank counts degrades to wrong costs, not false "maxed".
function ns.GetCosts(trackInfo, rank, maxRank, mode, slotID, itemLevel)
	if not trackInfo or not rank then
		return nil
	end
	local remaining = (maxRank or trackInfo.maxRank) - rank
	if remaining <= 0 then
		return { maxed = true }
	end

	local perRank = trackInfo.costPerRank
	if mode == "discount" and ns.IsTrackDiscounted(trackInfo) then
		perRank = math.ceil(perRank * 0.5)
	end

	local costs = { nextCost = perRank, totalCost = perRank * remaining }
	if mode == "discount" and itemLevel then
		local watermark = ns.GetHighWatermark(slotID)
		if watermark and (itemLevel + ns.ILVL_PER_RANK) <= watermark then
			costs.nextIsFree = true
		end
	end
	return costs
end

-- "20 <crest icon>" via Blizzard's formatter; falls back to the bare number
-- while the crest currency IDs above are unverified (GetCurrencyString
-- returns "" for unknown currency IDs).
function ns.FormatCost(amount, trackInfo)
	if not amount then
		return ""
	end
	local currencyID = trackInfo and trackInfo.crestCurrencyID
	if currencyID then
		local currencyString = GetCurrencyString(currencyID, amount)
		if currencyString ~= "" then
			return currencyString
		end
	end
	return tostring(amount)
end
