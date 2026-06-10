local _, ns = ...

-- User-facing strings live in Locales/*.lua (enUS loads first as the
-- fallback table); this file only consumes ns.L.

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
	-- "Off Hand" (not SECONDARYHANDSLOT's "Secondary Hand"): matches the bag
	-- rows' label for the same slot and fits the narrow slot column.
	{ inv = INVSLOT_OFFHAND, label = INVTYPE_WEAPONOFFHAND },
}

-- Maps an item's equip location (4th return of C_Item.GetItemInfoInstant) to
-- the equipped slot(s) it competes with, for the watermark fallback below.
ns.EQUIP_LOC_SLOTS = {
	INVTYPE_HEAD = { INVSLOT_HEAD },
	INVTYPE_NECK = { INVSLOT_NECK },
	INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
	INVTYPE_CLOAK = { INVSLOT_BACK },
	INVTYPE_CHEST = { INVSLOT_CHEST },
	INVTYPE_ROBE = { INVSLOT_CHEST },
	INVTYPE_WRIST = { INVSLOT_WRIST },
	INVTYPE_HAND = { INVSLOT_HAND },
	INVTYPE_WAIST = { INVSLOT_WAIST },
	INVTYPE_LEGS = { INVSLOT_LEGS },
	INVTYPE_FEET = { INVSLOT_FEET },
	INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
	INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
	INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
	INVTYPE_2HWEAPON = { INVSLOT_MAINHAND },
	INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
	INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND },
	INVTYPE_HOLDABLE = { INVSLOT_OFFHAND },
	INVTYPE_SHIELD = { INVSLOT_OFFHAND },
	INVTYPE_RANGED = { INVSLOT_MAINHAND },
	INVTYPE_RANGEDRIGHT = { INVSLOT_MAINHAND },
}

-- Display-label overrides for bag rows. The INVTYPE_* globals are the
-- default labels; INVTYPE_HOLDABLE's "Held In Off-hand" is too wide for the
-- slot column, so borrow the weapon variant's "Off Hand" (still localized).
ns.EQUIP_LOC_LABEL_OVERRIDES = {
	INVTYPE_HOLDABLE = INVTYPE_WEAPONOFFHAND,
}

-- Midnight (12.0) upgrade tracks. All values below are from third-party
-- guides (June 2026) and MUST be sanity-checked in game against the upgrade
-- vendor; they are isolated here so corrections are one-line edits.
--   crestCurrencyID: the track's Dawncrest currency. Adventurer=3383 per
--     Wowhead (3339 proved invalid in-game: no icon); Veteran/Champion/Hero
--     confirmed working in-game 2026-06; Myth untested until we have gear.
--   costPerRank: flat crests per upgrade rank (reported 20 for all slots).
--   achievementID: warband "X of the Dawn" achievement that halves costs.
--     IDs and names verified against the 12.0.5.67823 Achievement db2
--     (wago.tools, 2026-06-10): 61809 "Adventurer of the Dawn", 42767
--     "Veteran of the Dawn", 42768 "Champion of the Dawn", 42769 "Hero of
--     the Dawn", 42770 "Myth of the Dawn". achievementName still guards
--     against ID reshuffles by requiring the in-game name (translated via
--     L.ACHIEVEMENT_NAMES on non-English clients) to match before applying.
ns.TRACKS = {
	Adventurer = { maxRank = 6, crestCurrencyID = 3383, costPerRank = 20, achievementID = 61809, achievementName = "Adventurer of the Dawn" },
	Veteran    = { maxRank = 6, crestCurrencyID = 3341, costPerRank = 20, achievementID = 42767, achievementName = "Veteran of the Dawn" },
	Champion   = { maxRank = 6, crestCurrencyID = 3343, costPerRank = 20, achievementID = 42768, achievementName = "Champion of the Dawn" },
	Hero       = { maxRank = 6, crestCurrencyID = 3345, costPerRank = 20, achievementID = 42769, achievementName = "Hero of the Dawn" },
	Myth       = { maxRank = 6, crestCurrencyID = 3347, costPerRank = 20, achievementID = 42770, achievementName = "Myth of the Dawn" },
}

-- Approximate item levels gained per upgrade rank, used only to compare the
-- next rank against the slot high-watermark in discount-aware mode.
-- VERIFY IN-GAME: tracks span ~13 item levels over 5 steps in Midnight.
ns.ILVL_PER_RANK = 3

-- Track names arrive from the tooltip in the client's language; ns.TRACKS
-- is keyed by the canonical enUS names, so translate before the lookup.
function ns.GetTrackInfo(trackName)
	if not trackName then
		return nil
	end
	return ns.TRACKS[ns.L.TRACK_NAMES[trackName] or trackName]
end

local discountCache = {}
function ns.ClearDiscountCache()
	wipe(discountCache)
end

-- Not part of discountCache: that one is wiped on every discount-aware
-- rebuild, and the warning below must fire at most once per session.
local warnedNameMismatch = {}

-- True when the track's warband discount achievement is verified and earned.
function ns.IsTrackDiscounted(trackInfo)
	local achievementID = trackInfo.achievementID
	if not achievementID then
		return false
	end
	if discountCache[achievementID] == nil then
		local ok, _, name, _, completed = pcall(GetAchievementInfo, achievementID)
		-- GetAchievementInfo returns the client-language name, so compare
		-- against the locale's translation, keyed by achievement ID so the
		-- lookup can't be orphaned by edits to the enUS display name.
		local expectedName = ns.L.ACHIEVEMENT_NAMES[achievementID] or trackInfo.achievementName
		local nameMatches = ok and name and expectedName
			and name:find(expectedName, 1, true) ~= nil
		-- An earned achievement failing the name guard means OUR data is
		-- wrong (bad ID or bad translation) and the user would silently pay
		-- full price in discount-aware mode; say so once so it gets reported
		-- instead of looking like the discount was never earned.
		if ok and completed and not nameMatches and not warnedNameMismatch[achievementID] then
			warnedNameMismatch[achievementID] = true
			print(("|cffff7f00GearUpgradeCostTab:|r achievement %d is earned but its name (%s) doesn't match the expected %q - discount disabled for this track, please report this."):format(
				achievementID, tostring(name), tostring(expectedName)))
		end
		discountCache[achievementID] = (nameMatches and completed) or false
	end
	return discountCache[achievementID]
end

-- High-watermark for the item's slot, if the API cooperates. Signature per
-- warcraft.wiki.gg (12.0.1): takes an ItemInfo (we pass the item link) and
-- returns characterHighWatermark, accountHighWatermark. The values' exact
-- semantics are still unverified in game, so everything stays guarded.
function ns.GetHighWatermark(itemLink)
	local getWatermark = C_ItemUpgrade and C_ItemUpgrade.GetHighWatermarkForItem
	if type(getWatermark) ~= "function" or not itemLink then
		return nil
	end
	local ok, characterWatermark, accountWatermark = pcall(getWatermark, itemLink)
	if not ok then
		return nil
	end
	local best = math.max(tonumber(characterWatermark) or 0, tonumber(accountWatermark) or 0)
	return best > 0 and best or nil
end

-- Best-known "maximum item level for this slot": the watermark API when it
-- works, otherwise (and at minimum) the highest item level currently equipped
-- in the slot(s) this item could occupy. Equipping raises the real watermark,
-- so the equipped fallback can only under-estimate, never falsely mark free.
function ns.GetSlotMaxItemLevel(itemLink, equipLoc)
	local best = ns.GetHighWatermark(itemLink) or 0
	for _, invSlot in ipairs(ns.EQUIP_LOC_SLOTS[equipLoc] or {}) do
		local equippedLink = GetInventoryItemLink("player", invSlot)
		local itemLevel = equippedLink and C_Item.GetDetailedItemLevelInfo(equippedLink)
		if itemLevel then
			best = math.max(best, math.floor(itemLevel + 0.5))
		end
	end
	return best > 0 and best or nil
end

-- True when the item belongs to an item set (setID, GetItemInfo return
-- 16) — runtime-verified 2026-06-10: the equipped tier helm 250024
-- returns setID 1980 from its item link. This is the set-membership half
-- of "is this a tier piece"; the caller adds "is on an upgrade track"
-- (Scanner's GetEquippedTierSlots), and together they implement the
-- contract: an equipped set piece the player is actively upgrading
-- protects its slot. Class-lock legs were tried and DROPPED after
-- in-game testing: C_Item.IsItemSpecificToPlayerClass — Blizzard's own
-- Great Vault class-set check — returned FALSE in game for that same
-- helm passed as an item link despite the item being class-locked in the
-- 12.0.5.67823 db2 (AllowableClass=1024), and a tooltip "Classes: ..."
-- line match would swap one unverified dependency for another. An
-- expansionID == LE_EXPANSION_LEVEL_CURRENT leg was also rejected: that
-- constant tracks the CLIENT, not the gear (flips at prepatch, rejects
-- previous-season tier, deprecated family). Without a class leg,
-- non-class sets on a crest track could qualify (PvP appearance sets,
-- world-drop bonus sets); suppressing those slots still matches the
-- filter's intent of protecting equipped sets, and the checkbox turns it
-- off. Crafted sets never qualify (recrafting, not crest tracks), nor do
-- the four "set look" off-slots (no setID). Missing data (uncached item)
-- counts as not a set: wrongly hiding upgrade rows is worse than showing
-- extra ones.
function ns.IsSetItem(itemLink)
	return (select(16, C_Item.GetItemInfo(itemLink))) ~= nil
end

-- Returns { maxed = true } when fully upgraded, nil for unknown tracks, or
-- { nextCost, totalCost, nextIsFree } in crests of the track's Dawncrest.
-- maxRank parsed from the tooltip takes priority over the static table, so a
-- patch that changes rank counts degrades to wrong costs, not false "maxed".
function ns.GetCosts(trackInfo, rank, maxRank, mode, itemLink, itemLevel)
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
		local watermark = ns.GetHighWatermark(itemLink)
		if watermark and (itemLevel + ns.ILVL_PER_RANK) <= watermark then
			costs.nextIsFree = true
		end
	end
	return costs
end

-- Cost picture for an upgradeable bag item. A rank is gold-only ("free")
-- while its resulting item level stays within the slot's watermark. Returns
-- nil when there is nothing to upgrade (no rank info or already maxed),
-- otherwise:
--   nextIsFree: the next rank costs gold only
--   freeRanks:  how many ranks from here are gold-only
--   nextCost / crestTotal: crests for the next rank / for all ranks to max,
--     counting watermark-covered ranks as zero (nil when track unknown)
function ns.GetBagUpgradeCosts(trackInfo, rank, maxRank, mode, itemLevel, watermark)
	if not (rank and maxRank) then
		return nil
	end
	local remaining = maxRank - rank
	if remaining <= 0 then
		return nil -- already fully upgraded
	end

	local freeRanks = 0
	if itemLevel and watermark then
		freeRanks = math.floor((watermark - itemLevel) / ns.ILVL_PER_RANK)
		freeRanks = math.max(0, math.min(freeRanks, remaining))
	end

	local costs = { nextIsFree = freeRanks > 0, freeRanks = freeRanks }
	if trackInfo then
		local perRank = trackInfo.costPerRank
		if mode == "discount" and ns.IsTrackDiscounted(trackInfo) then
			perRank = math.ceil(perRank * 0.5)
		end
		costs.nextCost = costs.nextIsFree and 0 or perRank
		costs.crestTotal = (remaining - freeRanks) * perRank
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
