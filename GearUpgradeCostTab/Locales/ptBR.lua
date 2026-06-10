local _, ns = ...
local locale = GetLocale()
if locale ~= "ptBR" and locale ~= "ptPT" then return end

-- Portuguese (Brazilian ptBR; European ptPT clients use the same data).
-- Game terms (Brasão = crest, Bando de Guerra = warband) follow Blizzard's
-- own ptBR localization, verified against 12.0.5.67823 client data
-- (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Aprimoramentos"
L.IN_BAG = "Nas bolsas (exige brasões)"
L.IN_BAG_EMPTY = "Nada nas suas bolsas precisa de brasões para aprimorar no momento."
L.FREE_UPGRADES = "Nas bolsas (próximo aprimoramento grátis)"
L.FREE_UPGRADES_EMPTY = "Nada nas suas bolsas pode ser aprimorado só com ouro no momento."
L.COST_MODE_BASE = "Custos base"
L.COST_MODE_DISCOUNT = "Com descontos"
L.COST_MODE_DISCOUNT_TIP = "Reduz pela metade o custo em brasões das trilhas cuja conquista de Bando de Guerra correspondente já foi concluída e marca como grátis (só ouro) os aprimoramentos abaixo do recorde do compartimento."
L.INCLUDE_QUALITY_FMT = "Incluir itens de qualidade %s"
L.PRIORITISE_TIER = "Priorizar o conjunto de classe"
L.PRIORITISE_TIER_TIP = "Oculta itens das bolsas para os compartimentos em que uma peça do conjunto de classe (tier) está equipada, pois substituí-la quebraria o bônus de conjunto."
L.FILTERED_EMPTY = "Seus filtros estão ocultando itens aprimoráveis aqui."
L.COL_SLOT = "Slot"
L.COL_UPGRADE = "Aprimoramento"
L.COL_NEXT = "Próximo"
L.COL_MAX = "Até 6/6"
L.FREE = "Grátis"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Portuguese runtime names (SharedString db2 rows 970-978) and the legacy
-- baked lines (ItemNameDescription db2) use the same words, both verified
-- against 12.0.5.67823 client data 2026-06-10.
L.TRACK_NAMES = {
	["Aventureiro"] = "Adventurer",
	["Veterano"] = "Veteran",
	["Campeão"] = "Champion",
	["Herói"] = "Hero",
	["Mito"] = "Myth",
}

-- achievementID -> ptBR name, exact strings from the 12.0.5.67823
-- Achievement db2 (the inconsistent "da Aurora"/"da aurora" capitalization
-- is Blizzard's, not a typo).
L.ACHIEVEMENT_NAMES = {
	[61809] = "Aventureiro da Aurora",
	[42767] = "Veterano da aurora",
	[42768] = "Campeão da Aurora",
	[42769] = "Herói da aurora",
	[42770] = "Mito da aurora",
}
