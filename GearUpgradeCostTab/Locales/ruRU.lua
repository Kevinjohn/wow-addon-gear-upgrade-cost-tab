local _, ns = ...
if GetLocale() ~= "ruRU" then return end

-- Russian. Game terms (герб = crest, отряд = warband) follow Blizzard's own
-- ruRU localization, verified against 12.0.5.67823 client data (wago.tools
-- db2 + Ketho GlobalStrings) 2026-06-10; corrections from native speakers
-- are welcome. Anything missing here falls back to English via
-- Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Улучшения"
L.IN_BAG = "В сумках (нужны гербы)"
L.IN_BAG_EMPTY = "Сейчас в ваших сумках нет предметов, для улучшения которых нужны гербы."
L.FREE_UPGRADES = "В сумках (след. улучшение бесплатно)"
L.FREE_UPGRADES_EMPTY = "Сейчас в ваших сумках нет предметов, которые можно улучшить только за золото."
L.COST_MODE_BASE = "Базовая стоимость"
L.COST_MODE_DISCOUNT = "Со скидками"
L.COST_MODE_DISCOUNT_TIP = "Вдвое снижает стоимость в гербах для путей, по которым уже получено соответствующее достижение отряда, и помечает бесплатными (только золото) улучшения ниже рекорда ячейки."
-- "Базовая стоимость" ellipsizes in the default 130px dropdown.
L.COST_MODE_WIDTH = 170
L.INCLUDE_QUALITY_FMT = "Включать предметы качества «%s»"
L.PRIORITISE_TIER = "Приоритет классового комплекта"
L.PRIORITISE_TIER_TIP = "Скрывает предметы из сумок для ячеек, в которых надета часть классового комплекта (тира), — её замена нарушит бонус комплекта."
L.FILTERED_EMPTY = "Предметы, доступные для улучшения, скрыты здесь вашими фильтрами."
L.COL_SLOT = "Ячейка"
L.COL_UPGRADE = "Улучшение"
L.COL_NEXT = "След."
L.COL_MAX = "До 6/6"
L.FREE = "Беспл."

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Two verified shapes, both from 12.0.5.67823 client data (2026-06-10),
-- and they disagree on more than case: the runtime names (SharedString db2
-- rows 970-978) are capitalized and use "Защитник" (Champion) and
-- "Легенда" (Myth), while the legacy baked lines (ItemNameDescription db2)
-- are lowercase with "чемпион" and "легендарный герой". Map all of them.
L.TRACK_NAMES = {
	-- Runtime forms (SharedString)
	["Искатель приключений"] = "Adventurer",
	["Ветеран"] = "Veteran",
	["Защитник"] = "Champion",
	["Герой"] = "Hero",
	["Легенда"] = "Myth",
	-- Legacy baked lowercase forms (ItemNameDescription)
	["искатель приключений"] = "Adventurer",
	["ветеран"] = "Veteran",
	["чемпион"] = "Champion",
	["герой"] = "Hero",
	["легендарный герой"] = "Myth",
}

-- achievementID -> ruRU name, exact strings from the 12.0.5.67823
-- Achievement db2. These deliberately do NOT mirror the track names
-- (Blizzard's choice): Champion -> "Поборник зари", Myth -> "Сказания
-- зари".
L.ACHIEVEMENT_NAMES = {
	[61809] = "Искатель приключений зари",
	[42767] = "Ветеран зари",
	[42768] = "Поборник зари",
	[42769] = "Герой зари",
	[42770] = "Сказания зари",
}
