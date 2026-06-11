local _, ns = ...

-- Default (enUS/enGB) strings. The other Locales/*.lua files overwrite a
-- subset of these keys, so any string they miss falls back to English.
-- The __index metamethod turns a typo'd key into visible text ("COL_SLOT")
-- instead of a SetText(nil) error.
-- EQUIPPED and COL_ILVL reuse Blizzard's own localized globals (EQUIPPED,
-- ITEM_LEVEL_ABBR), so they are correct in every locale for free and stay
-- consistent with the rest of the client UI; locale files must not
-- override them.
ns.L = setmetatable({
	TAB_TITLE = "Gear Upgrades",
	EQUIPPED = EQUIPPED or "Equipped",
	IN_BAG = "In Bag (crest required)",
	IN_BAG_EMPTY = "Nothing in your bags needs crests to upgrade right now.",
	FREE_UPGRADES = "In Bag (next upgrade free)",
	FREE_UPGRADES_EMPTY = "Nothing in your bags can be upgraded for gold alone right now.",
	-- Shown instead of the empty notes when upgradeable items exist but
	-- the dropdown filters hid every one of them.
	FILTERED_EMPTY = "Upgradeable items here are hidden by your filters.",
	COST_MODE_BASE = "Base costs",
	COST_MODE_DISCOUNT = "Discount aware",
	COST_MODE_DISCOUNT_TIP = "Halves crest costs for tracks with the warband \"... of the Dawn\" achievement, and marks upgrades below your slot high-watermark as free (gold only).",
	-- The cost-mode dropdown's pixel width; locales with longer option
	-- labels (ruRU) override it so the selected text doesn't ellipsize.
	COST_MODE_WIDTH = 130,
	-- %s receives Blizzard's localized quality name (ITEM_QUALITY2_DESC
	-- etc.) already wrapped in its quality color, so locales translate only
	-- the sentence frame.
	INCLUDE_QUALITY_FMT = "Include %s items",
	PRIORITISE_TIER = "Prioritise tier",
	PRIORITISE_TIER_TIP = "Hides bag items for slots where you have a class set (tier) piece equipped, since replacing those would break your set bonus.",
	-- Not built from INCLUDE_QUALITY_FMT: several locales' frames read
	-- "items of quality %s", which is wrong for a bind type. Each locale
	-- translates the whole label using its client's Warbound/Soulbound
	-- terms (ITEM_ACCOUNTBOUND / ITEM_SOULBOUND, verified live
	-- GlobalStrings 2026-06-11); the tooltip rationale mirrors the
	-- vendor's own CONFIRM_UPGRADE_ITEM_BIND warning.
	INCLUDE_WARBOUND = "Include Warbound items",
	INCLUDE_WARBOUND_TIP = "Warbound items are hidden by default because upgrading one causes it to become soulbound.",
	-- Toggles the crest-totals footer below the lists.
	SHOW_CRESTS = "Show my crests",
	COL_SLOT = "Slot",
	COL_ILVL = ITEM_LEVEL_ABBR or "iLvl",
	COL_UPGRADE = "Upgrade",
	COL_NEXT = "Next",
	COL_MAX = "To 6/6",
	FREE = "Free",
	DASH = "\226\128\148", -- em dash
	UNKNOWN_COST = "?",
}, { __index = function(_, key) return tostring(key) end })

-- Localized tooltip track name -> canonical ns.TRACKS key ("Veterano" ->
-- "Veteran"). English tooltips already use the canonical names, so the
-- default map is empty; ns.GetTrackInfo falls back to the raw name.
-- Non-English maps carry both the runtime names (SharedString db2 rows
-- 970-978, the strings C_Item.GetItemUpgradeInfo feeds into
-- ITEM_UPGRADE_TOOLTIP_FORMAT_STRING) and the legacy baked tooltip lines
-- (ItemNameDescription db2), which differ in several locales.
ns.L.TRACK_NAMES = {}

-- achievementID -> the name GetAchievementInfo returns on this client.
-- The discount-aware mode only trusts an achievement ID when the in-game
-- name matches, so a locale without these entries degrades to "no
-- discount" (with a one-time chat warning), never to wrong costs. English
-- clients compare against ns.TRACKS' achievementName, so the default map
-- is empty.
ns.L.ACHIEVEMENT_NAMES = {}
