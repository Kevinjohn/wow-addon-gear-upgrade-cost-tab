local _, ns = ...
if GetLocale() ~= "frFR" then return end

-- French. Game terms (écu = crest, bataillon = warband) follow Blizzard's
-- own frFR localization, verified against 12.0.5.67823 client data
-- (wago.tools db2 + Ketho GlobalStrings) 2026-06-10; corrections from
-- native speakers are welcome. Anything missing here falls back to English
-- via Locales/enUS.lua.
local L = ns.L

L.TAB_TITLE = "Améliorations"
L.IN_BAG = "Dans les sacs (écus requis)"
L.IN_BAG_EMPTY = "Rien dans vos sacs ne nécessite d’écus pour être amélioré pour le moment."
L.FREE_UPGRADES = "Dans les sacs (prochaine amélioration gratuite)"
L.FREE_UPGRADES_EMPTY = "Rien dans vos sacs ne peut être amélioré avec de l’or seul pour le moment."
L.COST_MODE_BASE = "Coûts de base"
L.COST_MODE_DISCOUNT = "Avec remises"
L.COST_MODE_DISCOUNT_TIP = "Réduit de moitié le coût en écus des paliers dont le haut fait de bataillon correspondant est accompli, et marque comme gratuites (or seul) les améliorations sous le record de l’emplacement."
L.INCLUDE_QUALITY_FMT = "Inclure les objets de qualité %s"
L.PRIORITISE_TIER = "Prioriser l’ensemble de classe"
L.PRIORITISE_TIER_TIP = "Masque les objets des sacs pour les emplacements où une pièce d’ensemble de classe (tier) est équipée, car la remplacer briserait le bonus d’ensemble."
L.FILTERED_EMPTY = "Des objets améliorables sont masqués ici par vos filtres."
L.COL_SLOT = "Emplacement"
L.COL_UPGRADE = "Amélioration"
L.COL_NEXT = "Suivante"
L.COL_MAX = "Vers 6/6"
L.FREE = "Gratuit"

-- Tooltip track name -> canonical ns.TRACKS key. If a name here is wrong,
-- the row still renders with the tooltip's text but its costs show "?".
-- Two verified shapes, both from 12.0.5.67823 client data (2026-06-10):
-- the runtime names (SharedString db2 rows 970-978: "Vétéran", "Mythe")
-- and the legacy baked lines (ItemNameDescription db2: lowercase
-- gender-inclusive "vétéran ou vétérane", adjective "mythique"). Nothing
-- speculative: extra entries here are live false-match surface for the
-- fallback parser ("Rang : champion 2/3" must not parse as a track).
L.TRACK_NAMES = {
	-- Runtime singular forms (SharedString)
	["Aventurier"] = "Adventurer",
	["Vétéran"] = "Veteran",
	["Champion"] = "Champion",
	["Héros"] = "Hero",
	["Mythe"] = "Myth",
	-- Legacy baked gender-inclusive forms (ItemNameDescription)
	["aventurier ou aventurière"] = "Adventurer",
	["vétéran ou vétérane"] = "Veteran",
	["champion ou championne"] = "Champion",
	["héros ou héroïne"] = "Hero",
	["mythique"] = "Myth",
}

-- achievementID -> frFR name, exact strings from the 12.0.5.67823
-- Achievement db2. Blizzard did NOT derive these from the track names
-- ("Héraut de l’Aube" is Champion, "Héroïsme de l’aube" is Hero), and the
-- "l’Aube"/"l’aube" capitalization is theirs — do not "fix" either.
L.ACHIEVEMENT_NAMES = {
	[61809] = "Aventure de l’aube",
	[42767] = "Vétéran de l’aube",
	[42768] = "Héraut de l’Aube",
	[42769] = "Héroïsme de l’aube",
	[42770] = "Mythe de l’aube",
}
