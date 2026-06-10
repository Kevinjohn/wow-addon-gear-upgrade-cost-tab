# Gear Upgrade Cost Tab

A World of Warcraft (retail, Midnight 12.0.x) addon that adds a fourth **"Gear Upgrades"** tab to the character frame, after Character Info / Reputation / Currency. Like the Currency tab, it is click-to-open (no keybind) and shows a scrollable list with collapsible sections:

- **Equipped** (open by default) — every equipped slot in paper-doll order, with:
  - item level
  - upgrade track and rank (e.g. `Champion 5/6`)
  - Dawncrest cost to the next rank
  - Dawncrest cost to fully upgrade to 6/6
- **In Bag (next upgrade free)** (open by default) — bag items whose next
  upgrade costs no crests because they sit below the slot's best-known item
  level (the watermark — at minimum, what you have equipped in that slot).
  Great for the rings and trinkets you keep for their stats or effects and
  forget to upgrade. Shows item level, slot, name, a green **Free** marker,
  and the crest cost for any ranks beyond the free ones (`Free` again if the
  whole path is gold-only).
- **In Bag (crest required)** (collapsed by default) — bag items whose next
  upgrade costs crests. The two bag lists are exclusive: an item appears in
  whichever matches its *next* rank.

"Warbound until equipped" items are excluded from the bag lists (matched
against the `ITEM_ACCOUNTBOUND_UNTIL_EQUIP` / `ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP`
tooltip lines, so it is locale-safe); a toggle for this is planned.

A dropdown at the top (like the Reputation tab's filter) switches between:

- **Base costs** (default) — the standard per-rank crest cost.
- **Discount aware** — halves costs for tracks where your warband has earned the "… of the Dawn" achievement, and marks upgrades below your slot high-watermark as **Free** (gold only).

The choice is saved between sessions (`GearUpgradeCostTabDB`).

## Installation

Copy (or symlink) the `GearUpgradeCostTab` folder into your AddOns directory — on this Mac that is `/Applications/Games/World of Warcraft/_retail_/Interface/AddOns`:

```
# macOS (run from this repo)
ln -s "$(pwd)/GearUpgradeCostTab" "/Applications/Games/World of Warcraft/_retail_/Interface/AddOns/GearUpgradeCostTab"

# Windows (run from this repo, adjust drive/path)
mklink /D "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\GearUpgradeCostTab" "%cd%\GearUpgradeCostTab"
```

Then `/reload` (or restart the client) and press **C**.

## ⚠️ Data verification status

The Midnight upgrade-cost numbers in `GearUpgradeCostTab/Data.lua` come from third-party guides (there is no API that exposes upgrade costs while the upgrade vendor is closed, so the addon computes them from a static table). Verified in game 2026-06:

- ✅ **Costs and tooltip parsing** — per-rank crest costs and track/rank parsing confirmed correct against live gear.
- ✅ **Dawncrest currency IDs** — Adventurer **3383**, Veteran 3341, Champion 3343, Hero 3345 confirmed in game (icons render). Myth (3347) confirmed as "Myth Dawncrest" in the 12.0.5.67823 client data (wago.tools CurrencyTypes db2), in-game icon render still untested until Myth-track gear is available.
- ✅ **Discount achievement IDs** — all five verified against the 12.0.5.67823 Achievement db2 (2026-06-10): Adventurer 61809, Veteran 42767, Champion 42768, Hero 42769, Myth 42770, each still guarded by a (localized) name check. The *halved-cost mechanic itself* remains guide-sourced and should be sanity-checked at the vendor once an achievement is earned.
- ✅ **Localized track/achievement names** — verified against the 12.0.5.67823 db2 dumps per locale (see `Locales/*.lua` comments); not yet sighted on live non-English clients in game.
- ⚠️ **High-watermark API** — `C_ItemUpgrade.GetHighWatermarkForItem` takes an item link and returns character/account watermarks (signature wiki-verified for 12.0.1), but the values' in-game semantics are unverified, so it is probed defensively. The Free Upgrades section also falls back to comparing against the item level you have equipped in the slot, which can only under-report, never falsely mark an upgrade free.
- **`## Interface:` number** — bump `GearUpgradeCostTab.toc` when patches flag the addon as out of date.

## Files

| File | Purpose |
| --- | --- |
| `GearUpgradeCostTab.toc` | Addon manifest |
| `Locales/*.lua` | Translations, one file per language (`enUS.lua` is the fallback and loads first) |
| `Data.lua` | Slot order, upgrade-track/cost/currency/achievement data, cost math |
| `Scanner.lua` | Reads equipped and bag items and parses upgrade track/rank from tooltip data |
| `UI.xml` | Row/header templates and the panel (mirrors Blizzard's `Blizzard_TokenUI`) |
| `UI.lua` | Mixins, character-frame tab integration, dropdown, scroll list |

## Localization

Every language the WoW client ships is supported: English (enUS/enGB),
German (deDE), French (frFR), Spanish (esES/esMX), Italian (itIT),
Portuguese (ptBR/ptPT), Russian (ruRU), Korean (koKR), Simplified Chinese
(zhCN), and Traditional Chinese (zhTW). Each `Locales/<locale>.lua`
overrides the enUS table, so a missing translation falls back to English
instead of breaking.

Three things make a locale work beyond plain UI strings:

- **`L.TRACK_NAMES`** — maps the localized upgrade-track names that tooltips
  report back to the canonical keys in `ns.TRACKS`. Each locale carries BOTH
  verified shapes from the client data: the runtime names (SharedString db2
  rows 970–978 — what the live `ITEM_UPGRADE_TOOLTIP_FORMAT_STRING` line
  renders, e.g. ruRU "Защитник"/"Легенда") and the legacy baked tooltip
  lines (ItemNameDescription db2, e.g. ruRU "чемпион"/"легендарный герой"),
  which differ in case and sometimes in wording. If a track name is missing
  here, the row still renders but its costs show `?`.
- **`L.ACHIEVEMENT_NAMES`** — maps each discount achievement's ID to the
  name `GetAchievementInfo` returns on that client. Discount-aware mode only
  trusts an ID when the in-game name matches, so a locale without these
  degrades to "no discount", never to wrong costs — and if an achievement is
  *earned* but the name doesn't match, a one-time chat message asks the user
  to report it. esMX overrides the one name where it diverges from esES.
- Everything else (slot names, the "Equipped" header, the iLvl column
  label, currency strings, "warbound" detection, the upgrade-line pattern
  derived from `ITEM_UPGRADE_TOOLTIP_FORMAT_STRING`) comes from Blizzard's
  own localized globals (`EQUIPPED`, `ITEM_LEVEL_ABBR`, …) and needs no
  translation. `L.COST_MODE_WIDTH` lets a locale widen the cost-mode
  dropdown when its labels outgrow the default 130px (ruRU does).

`tests/run.lua` is a locale regression harness: it loads the addon's Lua
files with a mocked WoW environment and verifies tooltip parsing (both the
format-string path — proven in isolation with an unknown track name — and
the fallback path, including no-break-space prefixes, fullwidth colons,
and the fused name+rank shape zhTW's legacy lines use), track-name
resolution for every alias a locale ships (derived from the loaded locale
files, so the tests can't drift from the data), and cost math. Run it from
the repo root with any Lua ≥ 5.1: `lua tests/run.lua`.

## Implementation notes

- The tab is injected by creating `GearUpgradeCostTabButton` from `CharacterFrameTabTemplate` (which self-registers into `CharacterFrame.Tabs`), appending the panel to `CHARACTERFRAME_SUBFRAMES`, and setting `CharacterFrame.numTabs = 4`. Title, frame width (400, matching the Currency tab), and tab-overflow shrinking are corrected via `hooksecurefunc` because Blizzard keeps that lookup table file-local.
- Known trade-off: writing `CHARACTERFRAME_SUBFRAMES`/`numTabs` from addon code taints values that Blizzard's `ToggleCharacter` reads when the C/U keybinds fire. This is the established pattern for character-frame tabs and `CharacterFrame` is not protected, but in combat edge cases it could produce "Interface action failed because of an AddOn" — worth testing C/U in combat once.
- The list uses the modern `ScrollBox` API (`CreateScrollBoxListLinearView` + `ScrollUtil.InitScrollBoxListWithScrollBar`) with `ListHeaderThreeSliceTemplate` accordion headers — the same pattern as the Currency tab.
- Midnight's addon restrictions ("Secret Values") only affect real-time combat data; this out-of-combat UI addon is unaffected.

Lint with [luacheck](https://github.com/lunarmodules/luacheck): `luacheck GearUpgradeCostTab/` (config in `.luacheckrc`). Test with `lua tests/run.lua`.

Release notes live in [CHANGELOG.md](CHANGELOG.md).
