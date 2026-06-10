local _, ns = ...
if GetLocale() ~= "zhCN" then return end

-- Simplified Chinese. Game terms (纹章 = crest, 战团 = warband) follow
-- Blizzard's own zhCN localization, verified against 12.0.5.67823 client
-- data (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "装备升级"
L.IN_BAG = "背包（需要纹章）"
L.IN_BAG_EMPTY = "目前背包里没有需要纹章升级的装备。"
L.FREE_UPGRADES = "背包（下次升级免费）"
L.FREE_UPGRADES_EMPTY = "目前背包里没有仅用金币就能升级的装备。"
L.COST_MODE_BASE = "基础消耗"
L.COST_MODE_DISCOUNT = "计入折扣"
L.COST_MODE_DISCOUNT_TIP = "对应战团成就已完成的升级路线纹章消耗减半，并将低于部位最高纪录的升级标记为免费（仅金币）。"
L.COL_SLOT = "部位"
L.COL_UPGRADE = "升级"
L.COL_NEXT = "下一级"
L.COL_MAX = "至6/6"
L.FREE = "免费"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Chinese runtime names (SharedString db2 rows 970-978) and the legacy
-- baked lines (ItemNameDescription db2) use the same words, both verified
-- against 12.0.5.67823 client data 2026-06-10. The line prefix "升级："
-- uses the fullwidth colon U+FF1A, which the parser folds before
-- stripping.
L.TRACK_NAMES = {
	["冒险者"] = "Adventurer",
	["老兵"] = "Veteran",
	["勇士"] = "Champion",
	["英雄"] = "Hero",
	["神话"] = "Myth",
}

-- achievementID -> zhCN name, exact strings from the 12.0.5.67823
-- Achievement db2 (Champion's "黎明勇士" against the others' "曙光" prefix
-- is Blizzard's inconsistency, not a typo).
L.ACHIEVEMENT_NAMES = {
	[61809] = "曙光冒险者",
	[42767] = "曙光老兵",
	[42768] = "黎明勇士",
	[42769] = "曙光英雄",
	[42770] = "曙光神话",
}
