local _, ns = ...
if GetLocale() ~= "koKR" then return end

-- Korean. Game terms (문장 = crest, 전투부대 = warband) follow Blizzard's
-- own koKR localization, verified against 12.0.5.67823 client data
-- (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "장비 강화"
L.IN_BAG = "가방 (문장 필요)"
L.IN_BAG_EMPTY = "지금은 가방에 문장이 필요한 강화 대상이 없습니다."
L.FREE_UPGRADES = "가방 (다음 강화 무료)"
L.FREE_UPGRADES_EMPTY = "지금은 가방에 골드만으로 강화할 수 있는 아이템이 없습니다."
L.COST_MODE_BASE = "기본 비용"
L.COST_MODE_DISCOUNT = "할인 적용"
L.COST_MODE_DISCOUNT_TIP = "해당 전투부대 업적을 달성한 강화 단계의 문장 비용을 절반으로 표시하고, 부위 최고 기록보다 낮은 강화는 무료(골드만)로 표시합니다."
L.INCLUDE_QUALITY_FMT = "%s 등급 아이템 포함"
L.PRIORITISE_TIER = "직업 세트(티어) 우선"
L.PRIORITISE_TIER_TIP = "직업 세트(티어) 장비를 착용한 부위의 가방 아이템을 숨깁니다. 교체하면 세트 효과가 깨지기 때문입니다."
L.INCLUDE_WARBOUND = "전투귀속 아이템 포함"
L.INCLUDE_WARBOUND_TIP = "전투귀속 아이템은 기본적으로 숨겨집니다. 강화하면 캐릭터에 귀속되기 때문입니다."
L.SHOW_FULLY_UPGRADED = "최대 강화 장비 표시"
L.SHOW_FULLY_UPGRADED_TIP = "끄면 강화할 수 없는 착용 장비를 숨깁니다. 이미 최대로 강화된 장비와 강화 경로가 없는 장비 모두 해당합니다."
L.EQUIPPED_NONE_UPGRADEABLE = "지금은 착용 중인 장비 중에 강화할 수 있는 것이 없습니다."
L.SHOW_CRESTS = "내 문장 표시"
L.FILTERED_EMPTY = "강화 가능한 아이템이 필터로 숨겨져 있습니다."
L.COL_SLOT = "부위"
L.COL_UPGRADE = "강화"
L.COL_NEXT = "다음"
L.COL_MAX = "6/6까지"
L.FREE = "무료"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Korean runtime names (SharedString db2 rows 970-978) and the legacy
-- baked lines (ItemNameDescription db2) use the same words, both verified
-- against 12.0.5.67823 client data 2026-06-10; only the line prefix
-- differs ("레벨 강화:" live vs "강화 단계:" legacy), which the parser
-- handles.
L.TRACK_NAMES = {
	["모험가"] = "Adventurer",
	["노련가"] = "Veteran",
	["챔피언"] = "Champion",
	["영웅"] = "Hero",
	["신화"] = "Myth",
}

-- achievementID -> koKR name, exact strings from the 12.0.5.67823
-- Achievement db2. Champion's achievement is "여명의 용사" — Blizzard did
-- not reuse the track name "챔피언".
L.ACHIEVEMENT_NAMES = {
	[61809] = "여명의 모험가",
	[42767] = "여명의 노련가",
	[42768] = "여명의 용사",
	[42769] = "여명의 영웅",
	[42770] = "여명의 신화",
}
