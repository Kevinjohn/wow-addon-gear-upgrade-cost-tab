local _, ns = ...
if GetLocale() ~= "zhTW" then return end

-- Traditional Chinese. Game terms (紋章 = crest, 戰隊 = warband) follow
-- Blizzard's own zhTW localization, verified against 12.0.5.67823 client
-- data (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "裝備升級"
L.IN_BAG = "背包（需要紋章）"
L.IN_BAG_EMPTY = "目前背包裡沒有需要紋章升級的裝備。"
L.FREE_UPGRADES = "背包（下次升級免費）"
L.FREE_UPGRADES_EMPTY = "目前背包裡沒有只用金幣就能升級的裝備。"
L.COST_MODE_BASE = "基本花費"
L.COST_MODE_DISCOUNT = "計入折扣"
L.COST_MODE_DISCOUNT_TIP = "對應戰隊成就已完成的升級路線紋章花費減半，並將低於部位最高紀錄的升級標記為免費（僅金幣）。"
L.INCLUDE_QUALITY_FMT = "包含%s物品"
L.PRIORITISE_TIER = "優先職業套裝"
L.PRIORITISE_TIER_TIP = "若某部位已裝備職業套裝物品，則隱藏該部位的背包物品，以免替換後失去套裝效果。"
L.INCLUDE_WARBOUND = "包含戰隊綁定物品"
L.INCLUDE_WARBOUND_TIP = "戰隊綁定物品預設隱藏：升級後將變為靈魂綁定。"
L.SHOW_CRESTS = "顯示我的紋章"
L.FILTERED_EMPTY = "此處有可升級物品被篩選條件隱藏。"
L.COL_SLOT = "部位"
L.COL_UPGRADE = "升級"
L.COL_NEXT = "下一級"
L.COL_MAX = "至6/6"
L.FREE = "免費"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Two verified shapes, both from 12.0.5.67823 client data (2026-06-10):
-- the runtime names (SharedString db2 rows 970-978) and the legacy baked
-- lines (ItemNameDescription db2), which agree except Myth — "神話"
-- runtime vs "傳奇" legacy. The legacy lines also use the fullwidth colon
-- U+FF1A and fuse the name to the rank ("等級提升：精兵1/8"); the parser
-- handles both.
L.TRACK_NAMES = {
	["冒險者"] = "Adventurer",
	["精兵"] = "Veteran",
	["勇士"] = "Champion",
	["英雄"] = "Hero",
	["神話"] = "Myth",
	-- Legacy baked form for Myth only
	["傳奇"] = "Myth",
}

-- achievementID -> zhTW name, exact strings from the 12.0.5.67823
-- Achievement db2. Myth's achievement is "黎明傳奇" — Blizzard reused the
-- legacy "傳奇" wording, not the runtime track name "神話".
L.ACHIEVEMENT_NAMES = {
	[61809] = "黎明冒險者",
	[42767] = "黎明精兵",
	[42768] = "黎明勇士",
	[42769] = "黎明英雄",
	[42770] = "黎明傳奇",
}
