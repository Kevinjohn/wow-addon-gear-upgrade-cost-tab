local _, ns = ...
if GetLocale() ~= "itIT" then return end

-- Italian. Game terms (Emblema = crest, Brigata = warband) follow
-- Blizzard's own itIT localization, verified against 12.0.5.67823 client
-- data (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Potenziamenti"
L.IN_BAG = "Nelle borse (servono emblemi)"
L.IN_BAG_EMPTY = "Al momento niente nelle tue borse richiede emblemi per essere potenziato."
L.FREE_UPGRADES = "Nelle borse (prossimo potenziamento gratuito)"
L.FREE_UPGRADES_EMPTY = "Al momento niente nelle tue borse può essere potenziato solo con l'oro."
L.COST_MODE_BASE = "Costi base"
L.COST_MODE_DISCOUNT = "Con sconti"
L.COST_MODE_DISCOUNT_TIP = "Dimezza i costi in emblemi dei percorsi la cui impresa di Brigata corrispondente è già stata completata e segna come gratuiti (solo oro) i potenziamenti sotto il primato dello slot."
L.INCLUDE_QUALITY_FMT = "Includi oggetti di qualità %s"
L.PRIORITISE_TIER = "Dai priorità al set di classe"
L.PRIORITISE_TIER_TIP = "Nasconde gli oggetti nelle borse per gli slot in cui è equipaggiato un pezzo del set di classe (tier), perché sostituirlo romperebbe il bonus del set."
L.INCLUDE_WARBOUND = "Includi oggetti vincolati alla Brigata"
L.INCLUDE_WARBOUND_TIP = "Gli oggetti vincolati alla Brigata sono nascosti per impostazione predefinita, perché potenziarli li vincola a un solo personaggio."
L.FILTERED_EMPTY = "I tuoi filtri nascondono qui oggetti potenziabili."
L.COL_SLOT = "Slot"
L.COL_UPGRADE = "Potenziamento"
L.COL_NEXT = "Prossimo"
L.COL_MAX = "A 6/6"
L.FREE = "Gratis"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Italian runtime names (SharedString db2 rows 970-978) and the legacy
-- baked lines (ItemNameDescription db2) use the same words, both verified
-- against 12.0.5.67823 client data 2026-06-10.
L.TRACK_NAMES = {
	["Avventuriero"] = "Adventurer",
	["Veterano"] = "Veteran",
	["Campione"] = "Champion",
	["Eroe"] = "Hero",
	["Mito"] = "Myth",
}

-- achievementID -> itIT name, exact strings from the 12.0.5.67823
-- Achievement db2: ASCII apostrophes (0x27, byte-verified) and the
-- lowercase "dell'alba" on Campione are Blizzard's, not typos.
L.ACHIEVEMENT_NAMES = {
	[61809] = "Avventuriero dell'Alba",
	[42767] = "Veterano dell'Alba",
	[42768] = "Campione dell'alba",
	[42769] = "Eroe dell'Alba",
	[42770] = "Mito dell'Alba",
}
