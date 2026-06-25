local _, ns = ...
if GetLocale() ~= "deDE" then return end

-- German. Game terms (Wappen = crest, Kriegsmeute = warband) follow
-- Blizzard's own deDE localization, verified against 12.0.5.67823 client
-- data (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Aufwertungen"
L.IN_BAG = "In den Taschen (Wappen nötig)"
L.IN_BAG_EMPTY = "Nichts in Euren Taschen benötigt derzeit Wappen zum Aufwerten."
L.FREE_UPGRADES = "In den Taschen (nächste Stufe gratis)"
L.FREE_UPGRADES_EMPTY = "Nichts in Euren Taschen kann derzeit allein für Gold aufgewertet werden."
L.COST_MODE_BASE = "Grundkosten"
L.COST_MODE_DISCOUNT = "Mit Rabatten"
L.COST_MODE_DISCOUNT_TIP = "Halbiert die Wappenkosten für Pfade, deren zugehöriger Kriegsmeuten-Erfolg bereits errungen wurde, und markiert Aufwertungen unterhalb der Bestmarke des Platzes als gratis (nur Gold)."
L.INCLUDE_QUALITY_FMT = "Gegenstände der Qualität %s einbeziehen"
L.PRIORITISE_TIER = "Klassenset priorisieren"
L.PRIORITISE_TIER_TIP = "Blendet Taschengegenstände für Plätze aus, in denen ein Teil des Klassensets (Tier) angelegt ist, da ein Austausch den Setbonus brechen würde."
L.INCLUDE_WARBOUND = "Kriegsmeutengebundene Gegenstände einbeziehen"
L.INCLUDE_WARBOUND_TIP = "Kriegsmeutengebundene Gegenstände sind standardmäßig ausgeblendet, da sie beim Aufwerten seelengebunden werden."
L.SHOW_FULLY_UPGRADED = "Voll aufgewertete Ausrüstung anzeigen"
L.SHOW_FULLY_UPGRADED_TIP = "Wenn deaktiviert, werden angelegte Gegenstände ausgeblendet, die Ihr nicht aufwerten könnt: voll aufgewertete ebenso wie solche ohne Aufwertungspfad."
L.EQUIPPED_NONE_UPGRADEABLE = "Nichts an Eurer angelegten Ausrüstung kann derzeit aufgewertet werden."
L.SHOW_CRESTS = "Meine Wappen anzeigen"
L.FILTERED_EMPTY = "Aufwertbare Gegenstände sind hier durch Eure Filter ausgeblendet."
L.COL_SLOT = "Platz"
L.COL_UPGRADE = "Aufwertung"
L.COL_NEXT = "Nächste"
L.COL_MAX = "Auf 6/6"
L.FREE = "Gratis"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- German runtime names (SharedString db2 rows 970-978) and the legacy
-- baked lines (ItemNameDescription db2) use the same words, both verified
-- against 12.0.5.67823 client data 2026-06-10; only the line prefix
-- differs ("Stufe aufwerten:" live vs "Aufwertungsgrad:" legacy), which
-- the parser handles.
L.TRACK_NAMES = {
	["Abenteurer"] = "Adventurer",
	["Veteran"] = "Veteran",
	["Champion"] = "Champion",
	["Held"] = "Hero",
	["Mythos"] = "Myth",
}

-- achievementID -> deDE name, exact strings from the 12.0.5.67823
-- Achievement db2 (Champion's "der Dämmerung" instead of "der
-- Morgendämmerung" is Blizzard's inconsistency, not a typo).
L.ACHIEVEMENT_NAMES = {
	[61809] = "Abenteurer der Morgendämmerung",
	[42767] = "Veteran der Morgendämmerung",
	[42768] = "Champion der Dämmerung",
	[42769] = "Held der Morgendämmerung",
	[42770] = "Mythos der Morgendämmerung",
}
