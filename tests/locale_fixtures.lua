-- Per-locale fixtures for tests/run.lua: ONLY data the addon cannot supply
-- itself — the GetLocale() token, the Locales/ file that serves it, and the
-- locale's real ITEM_UPGRADE_TOOLTIP_FORMAT_STRING (source:
-- Ketho/BlizzardInterfaceResources, branch "live",
-- Resources/GlobalStrings/<locale>.lua, fetched 2026-06-10). Track-name
-- aliases are NOT restated here: the harness derives them from the loaded
-- L.TRACK_NAMES, so fixtures and locale files cannot drift.
-- expectAchievements pins per-locale achievement-name divergences.

-- frFR's format string contains U+2019 (\226\128\153) and a no-break space
-- U+00A0 (\194\160) before the colon, hex-verified; escapes keep those
-- bytes survivable in editors. The Spanish and Portuguese strings are
-- shared by both their locales.
local FR_FORMAT = "Niveau d\226\128\153am\195\169lioration\194\160: %s %d/%d"
local ES_FORMAT = "Nivel de mejora: %s %d/%d"
local PT_FORMAT = "Nível de aprimoramento: %s %d/%d"

return {
	-- deDE legacy baked lines use the "Aufwertungsgrad:" prefix instead of
	-- this live global; the harness's prefix fallback cases cover them.
	{ locale = "deDE", file = "deDE", formatString = "Stufe aufwerten: %s %d/%d" },
	{ locale = "frFR", file = "frFR", formatString = FR_FORMAT },
	{ locale = "esES", file = "esES", formatString = ES_FORMAT,
	  expectAchievements = { [42769] = "Héroe del alba" } },
	-- esMX shares the esES file but retranslates Hero's achievement.
	{ locale = "esMX", file = "esES", formatString = ES_FORMAT,
	  expectAchievements = { [42769] = "Adalid del alba" } },
	{ locale = "itIT", file = "itIT", formatString = "Livello di potenziamento: %s %d/%d" },
	{ locale = "ptBR", file = "ptBR", formatString = PT_FORMAT },
	-- ptPT clients share the ptBR file and data.
	{ locale = "ptPT", file = "ptBR", formatString = PT_FORMAT },
	{ locale = "ruRU", file = "ruRU", formatString = "Уровень улучшения: %s %d/%d" },
}
