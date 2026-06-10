# Changelog

## [0.3.0-alpha] — 2026-06-10

### Added
- **Localization** for every European language WoW supports: German (deDE),
  French (frFR), Spanish (esES/esMX), Italian (itIT), Portuguese
  (ptBR/ptPT), and Russian (ruRU), with English (enUS/enGB) as the fallback
  for any untranslated string. Strings live in `Locales/`, one file per
  language; the "Equipped" header and the iLvl column reuse Blizzard's own
  localized `EQUIPPED` / `ITEM_LEVEL_ABBR` globals.
- Per-locale track-name maps (`L.TRACK_NAMES`): tooltips report upgrade
  tracks in the client language, and cost lookups now translate those back
  to the canonical track keys (previously every non-English client showed
  `?` for all costs). Each map carries BOTH verified shapes from the
  12.0.5.67823 client data: the runtime names (SharedString db2 — the
  strings the live format-string line renders) and the legacy baked
  tooltip lines (ItemNameDescription db2). The two differ in several
  locales: esES runtime names are capitalized while its baked lines are
  lowercase, and ruRU uses entirely different words at runtime ("Защитник",
  "Легенда") than in baked lines ("чемпион", "легендарный герой").
- Per-locale achievement-name maps (`L.ACHIEVEMENT_NAMES`), keyed by
  achievement ID so the lookup can't be orphaned by display-name edits.
  esMX gets its own override where it diverges from esES (Hero is "Adalid
  del alba"). If an achievement is earned but its name doesn't match our
  data, a one-time chat message says so instead of silently charging full
  price in discount-aware mode.
- The four missing discount achievement IDs, verified against the
  12.0.5.67823 Achievement db2: Veteran 42767, Champion 42768, Hero 42769,
  Myth 42770 (Adventurer was already 61809).
- Localized addon descriptions (`## Notes-xxYY`) in the TOC.
- The equipped rows' track column is now two regions, so a long localized
  track name ("Искатель приключений") truncates with an ellipsis while the
  rank ("4/6") stays visible; the cost-mode dropdown width is a locale
  value (`L.COST_MODE_WIDTH`) because ruRU's labels need more than 130px.
- `tests/run.lua`: a locale regression harness that loads the addon's Lua
  with a mocked WoW environment. Track-name aliases are derived from the
  loaded locale files (they cannot drift from a hand-kept copy), every
  alias is checked through both parse paths (including no-break-space
  prefixes), the format-string-derived parser is proven in isolation with
  an unknown track name, and a broken fixtures file fails the run loudly.
  Run with any Lua ≥ 5.1: `lua tests/run.lua`.

### Fixed
- The tooltip-parsing fallback (used when a line doesn't match
  `ITEM_UPGRADE_TOOLTIP_FORMAT_STRING`, e.g. deDE's legacy
  "Aufwertungsgrad:" lines) matched ASCII letters only, so it could never
  match track names like "Campeón" or "Ветеран"; it now accepts any text
  and keeps the known-track guard against false matches. It is also
  anchored and prefiltered (the old unanchored lazy pattern made every
  non-matching tooltip line an O(n²) scan — measured 58x slower), requires
  whitespace before the rank (so "Veteran2/6"-shaped text can't
  false-match), and folds no-break spaces before matching.
- The primary parser now routes captures by the format string's positional
  indices, so a hypothetical locale printing the max rank before the
  current one ("%3$d/%2$d") can no longer swap rank/maxRank and render a
  partially-upgraded item as maxed.
- The discount-achievement name guard compared `GetAchievementInfo`'s
  localized name against the enUS name, so discount-aware mode could never
  activate on non-English clients; it now compares against the locale's
  translated achievement name where one is shipped.

## [0.2.0-alpha] — 2026-06-10

### Added
- **In Bag (next upgrade free)** section (open by default): bag items whose
  next upgrade rank is gold-only because they sit below the slot's
  high-watermark (at minimum, the item level you have equipped in that slot).
  Catches the rings and trinkets kept for their stats or effects that quietly
  become free upgrades.
- **In Bag (crest required)** section (collapsed by default): bag items whose
  next upgrade costs crests. The two bag lists are exclusive, routed by what
  the item's *next* rank costs.
- Bag rows show item level, slot, and the quality-coloured item name, with
  hover tooltips; lists refresh on `BAG_UPDATE_DELAYED`.
- "Warbound until equipped" items are excluded from the bag lists, matched
  against the `ITEM_ACCOUNTBOUND_UNTIL_EQUIP` /
  `ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP` globals so the check is locale-safe.
  A toggle for this is planned.
- This changelog.

### Changed
- Columns are now `iLvl | Slot | Upgrade | Next | To 6/6` in every section,
  with a single font size throughout and rebalanced column spacing for
  readability.
- The equipped off-hand row is labelled "Off Hand" (matching the bag rows)
  instead of "Secondary Hand".

### Fixed
- `C_ItemUpgrade.GetHighWatermarkForItem` is now called with an item link, as
  the API expects, instead of an `ItemLocation`. The old call failed silently
  through its `pcall` guard, so discount-aware "Free" markers on equipped gear
  could never appear.

## [0.1.0-alpha] — 2026-06-10

### Added
- "Gear Upgrades" tab on the character frame (4th tab, after Currency),
  click-to-open, styled like the Currency tab.
- Equipped section: paper-doll-ordered list with item level, upgrade track and
  rank, crest cost to the next rank and to fully upgraded; fully upgraded rows
  render muted.
- "Base costs" / "Discount aware" dropdown, persisted across sessions
  (`GearUpgradeCostTabDB`).
- Costs computed from a static table (verified in game) with track/rank parsed
  from tooltip data; track-specific Dawncrest currency icons.
