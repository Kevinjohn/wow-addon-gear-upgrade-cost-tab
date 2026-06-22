# Changelog

## [Unreleased]

## [0.8.0] — 2026-06-22

### Added
- Automated releases: pushing a `v*` tag now runs a GitHub Actions workflow
  (`.github/workflows/release.yml`) that builds the package with the BigWigs
  packager, publishes a GitHub Release with the zip attached, and — once the
  CurseForge/Wago project IDs and API-token secrets are set — uploads there too
  (it safely skips those uploads until then). The workflow is publish-only;
  tests stay local (`scripts/release.sh` remains for dry-run builds).

### Changed
- Bumped `## Interface:` to `120007` for retail patch 12.0.7 so the addon loads
  without the "out of date" prompt.
- Moved the addon's loaded files (`GearUpgradeCostTab.toc`, `Data.lua`,
  `Scanner.lua`, `UI.lua`, `UI.xml`, `Locales/*.lua`) from the
  `GearUpgradeCostTab/` subfolder to the repository root so the BigWigs packager
  can discover the `.toc`. The shipped zip is unchanged — `.pkgmeta`'s
  `package-as`/`ignore` still produce a single `GearUpgradeCostTab/` folder. No
  in-game behaviour change. See `docs/packaging.md`.
- Removed the non-working `move-folders` block from `.pkgmeta` (it does not point
  the packager at a nested `.toc`; root layout is the actual fix).

## [0.7.0-alpha] — 2026-06-11

### Added
- Crest footer pinned below the scrolling list (the list and its scroll
  bar are 26px shorter while it is shown): one cell per crest in
  ladder order, least rare on the left (Adventurer) to rarest on the right
  (Myth), each showing the warband's owned total next to the crest's icon.
  Totals come from `C_CurrencyInfo.GetCurrencyInfo` and refresh live on
  `CURRENCY_DISPLAY_UPDATE`; rendering reuses the cost columns' formatter
  (`GetCurrencyString`), so a still-unverified crest currency ID degrades
  to a muted dash rather than a phantom zero. Hovering a cell shows the
  currency tooltip (`GameTooltip:SetCurrencyByID`, the auto-generated
  counterpart of `C_TooltipInfo.GetCurrencyByID` — usage confirmed against
  Blizzard's own PVPHonorSystem/PVPMatchResults code, live branch
  2026-06-11). The icon and number need no translation, and the dash
  reuses `L.DASH`.
- **Show my crests** checkbox (off by default) in the dropdown, below a
  second divider separating display options from the bag filters. Ticking
  it shows the crest footer and re-anchors the list's bottom edge (the
  scroll bar follows) to make room, refreshing the totals on every show,
  which covers currency changes that arrived while hidden (the
  `CURRENCY_DISPLAY_UPDATE` handler skips a hidden footer). Toggling
  re-anchors rather than rebuilding — the option changes panel chrome, not
  list contents. Label translated for all ten locales using each client's
  established crest term (`SHOW_CRESTS`); persists as `showCrests` in
  `GearUpgradeCostTabDB`.

## [0.6.0-alpha] — 2026-06-11

### Added
- **Include Warbound items** checkbox (off by default), joining the other
  bag-list filters in the dropdown. "Warbound until equipped" gear was
  previously always excluded from the In Bag sections; it can now be
  listed on demand. It stays hidden by default because upgrading a
  Warbound item causes it to become soulbound — the same warning the
  upgrade vendor shows (`CONFIRM_UPGRADE_ITEM_BIND`). Each locale's label
  and tooltip use the client's own Warbound/Soulbound vocabulary
  (`ITEM_ACCOUNTBOUND` / `ITEM_SOULBOUND`, verified against live
  GlobalStrings for all ten languages). The label deliberately does NOT
  reuse the quality checkboxes' "Include %s items" frame: several locales
  render that frame as "items of quality %s", which is wrong for a bind
  type.

### Changed
- Warbound rows hidden by the new filter now count toward the "hidden by
  your filters" empty note, like every other filter; previously the
  warbound exclusion was invisible, so an empty section could claim there
  was nothing to upgrade while warbound upgradeables sat in the bags.

## [0.5.0-alpha] — 2026-06-10

### Added
- Three bag-list filter checkboxes in the cost-mode dropdown, below a
  divider — the same radios-divider-checkboxes layout the Reputation tab's
  filter uses. All three persist in `GearUpgradeCostTabDB`:
  - **Include Uncommon items** and **Include Rare items** (both off by
    default): green and blue gear is now hidden from both In Bag sections
    unless opted in. The labels reuse Blizzard's localized
    `ITEM_QUALITY2/3_DESC` quality names, wrapped in their quality colors
    via `ColorManager`, so only the sentence frame needed translating.
  - **Prioritise tier** (on by default): hides bag items for any slot
    whose equipped item is a set ("tier") piece the player is actively
    upgrading, so the lists never suggest competing with a set bonus.
    There is no direct "is tier" API; detection is two in-game-verified
    legs: the equipped item belongs to an item set (`C_Item.GetItemInfo`
    return 16, `setID`) AND is itself on an upgrade track (the same
    tooltip parse the rest of the addon runs on). Truly-legacy tier has
    no current crest track and crafted "sets" recraft instead of using
    crests, so neither suppresses anything; the four "set look"
    off-slots carry no `setID`. Two stronger class-lock legs were
    rejected by in-game testing (2026-06-10):
    `C_Item.IsItemSpecificToPlayerClass` — Blizzard's own Great Vault
    class-set check — returned false for an equipped Druid tier helm
    passed as an item link (item 250024, db2-verified class-locked with
    `AllowableClass=1024`), and `expansionID ==
    LE_EXPANSION_LEVEL_CURRENT` compares gear against a constant that
    tracks the client, not the item (flips at prepatch, rejects
    previous-season tier, deprecated family). Without a class leg,
    non-class sets on a crest track (e.g. PvP appearance sets) also
    protect their slots — consistent with the filter's intent. The
    heuristic lives in `Data.lua` (`ns.IsSetItem`) alongside the other
    verify-in-game facts; confirmed working in game 2026-06-10. Full
    post-mortem of the rejected approaches: `docs/tier-detection.md`.
- Filter-aware empty notes: when a bag section is empty only because the
  filters hid every upgradeable row, it now says so ("Upgradeable items
  here are hidden by your filters") instead of falsely claiming there is
  nothing to upgrade. The scanner runs the user filters last and reports
  what they hid per section.

### Fixed
- Expanding a collapsed section now goes through the same item-data
  preload as every other rebuild path; previously the header click
  rebuilt immediately and could scan not-yet-cached items, making the new
  filters silently fail open until the next update.
- `ns.BuildBagRows` called without saved settings now applies the
  documented defaults (tier filter on); previously a nil options table
  produced a quality-filtered-but-tier-unfiltered mix matching neither
  the defaults nor unfiltered output.

## [0.4.0-alpha] — 2026-06-10

### Added
- Korean (koKR), Simplified Chinese (zhCN), and Traditional Chinese (zhTW)
  localization — the addon now covers every language the WoW client ships.
  Track and achievement names verified against the 12.0.5.67823 client db2.
  Blizzard's achievement naming is again non-parallel (koKR Champion is
  "여명의 용사" against the track's "챔피언"; zhTW Myth is "黎明傳奇"
  against the track's "神話"), and zhTW's legacy tooltip lines use "傳奇"
  for the Myth track where the live client says "神話" — all mapped.

### Fixed
- The fallback tooltip parser now folds the fullwidth colon U+FF1A used by
  the Chinese clients' line prefixes ("升级：") and accepts zhTW's legacy
  fused name+rank shape ("等級提升：精兵1/8"). The fused form is only
  trusted when the name ends in a CJK character, so Latin or Cyrillic text
  glued to digits ("Veteran2/6") still can't false-match.

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
