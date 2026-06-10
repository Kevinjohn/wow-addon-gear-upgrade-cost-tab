local _, ns = ...
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

-- Spanish (shared by European esES and Latin American esMX; the few keys
-- where the two translations diverge are overridden for esMX at the
-- bottom). Game terms (blasón = crest, banda guerrera = warband) follow
-- Blizzard's own esES localization, verified against 12.0.5.67823 client
-- data (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Mejoras"
L.IN_BAG = "En las bolsas (requiere blasones)"
L.IN_BAG_EMPTY = "Ahora mismo nada en tus bolsas necesita blasones para mejorarse."
L.FREE_UPGRADES = "En las bolsas (siguiente mejora gratis)"
L.FREE_UPGRADES_EMPTY = "Ahora mismo nada en tus bolsas puede mejorarse solo con oro."
L.COST_MODE_BASE = "Costes base"
L.COST_MODE_DISCOUNT = "Con descuentos"
L.COST_MODE_DISCOUNT_TIP = "Reduce a la mitad el coste en blasones de las vías cuyo logro de banda guerrera correspondiente ya se haya conseguido y marca como gratis (solo oro) las mejoras por debajo del récord de la ranura."
L.INCLUDE_QUALITY_FMT = "Incluir objetos de calidad %s"
L.PRIORITISE_TIER = "Priorizar el conjunto de clase"
L.PRIORITISE_TIER_TIP = "Oculta los objetos de las bolsas para las ranuras en las que llevas equipada una pieza de conjunto de clase (tier), ya que sustituirla rompería la bonificación de conjunto."
L.INCLUDE_WARBOUND = "Incluir objetos ligados a la banda guerrera"
L.INCLUDE_WARBOUND_TIP = "Los objetos ligados a la banda guerrera se ocultan por defecto, porque al mejorarlos quedan ligados a un solo personaje."
L.FILTERED_EMPTY = "Tus filtros ocultan aquí objetos mejorables."
L.COL_SLOT = "Ranura"
L.COL_UPGRADE = "Mejora"
L.COL_NEXT = "Siguiente"
L.COL_MAX = "A 6/6"
L.FREE = "Gratis"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Two verified shapes, both from 12.0.5.67823 client data (2026-06-10):
-- the runtime names are CAPITALIZED (SharedString db2 rows 970-978:
-- "Veterano"), while the legacy baked lines are lowercase
-- (ItemNameDescription db2: "Nivel de mejora: veterano 1/8"). esMX shares
-- both sets verbatim.
L.TRACK_NAMES = {
	-- Runtime forms (SharedString)
	["Aventurero"] = "Adventurer",
	["Veterano"] = "Veteran",
	["Campeón"] = "Champion",
	["Héroe"] = "Hero",
	["Mito"] = "Myth",
	-- Legacy baked lowercase forms (ItemNameDescription)
	["aventurero"] = "Adventurer",
	["veterano"] = "Veteran",
	["campeón"] = "Champion",
	["héroe"] = "Hero",
	["mito"] = "Myth",
}

-- achievementID -> esES name, exact strings from the 12.0.5.67823
-- Achievement db2 (the inconsistent "del alba"/"del Alba" capitalization
-- is Blizzard's, not a typo).
L.ACHIEVEMENT_NAMES = {
	[61809] = "Aventurero del alba",
	[42767] = "Veterano del alba",
	[42768] = "Campeón del Alba",
	[42769] = "Héroe del alba",
	[42770] = "Mito del alba",
}

if locale == "esMX" then
	-- esMX retranslates Hero's achievement; everything else matches esES
	-- byte for byte (verified against the esMX Achievement db2).
	L.ACHIEVEMENT_NAMES[42769] = "Adalid del alba"
end
