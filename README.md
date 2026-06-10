# Gear Upgrade Cost Tab

A World of Warcraft (retail, Midnight 12.0.x) addon that adds a fourth **"Gear Upgrades"** tab to the character frame, after Character Info / Reputation / Currency. Like the Currency tab, it is click-to-open (no keybind) and shows a scrollable list with collapsible sections:

- **Equipped** (open by default) — every equipped slot in paper-doll order, with:
  - item level
  - upgrade track and rank (e.g. `Champion 5/6`)
  - Dawncrest cost to the next rank
  - Dawncrest cost to fully upgrade to 6/6
- **In Bag** — placeholder for a future update.

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
- ✅ **Dawncrest currency IDs** — Adventurer **3383**, Veteran 3341, Champion 3343, Hero 3345 confirmed (icons render). **Myth (3347) untested** until Myth-track gear is available; if its icon is missing, find the right ID via `/dump C_CurrencyInfo.GetCurrencyInfo(3347)`.
- ⚠️ **Discount achievement IDs** — only Adventurer has a candidate ID (61809), guarded by a name check; fill in the others in `ns.TRACKS` once confirmed (search "of the Dawn" in the achievement pane and shift-link to get IDs).
- ⚠️ **High-watermark API** — discount mode probes `C_ItemUpgrade.GetHighWatermarkForItem` defensively; if it is missing or behaves differently in 12.0, "Free" markers simply won't appear.
- **`## Interface:` number** — bump `GearUpgradeCostTab.toc` when patches flag the addon as out of date.

## Files

| File | Purpose |
| --- | --- |
| `GearUpgradeCostTab.toc` | Addon manifest |
| `Data.lua` | Slot order, upgrade-track/cost/currency/achievement data, cost math |
| `Scanner.lua` | Reads equipped items and parses upgrade track/rank from tooltip data |
| `UI.xml` | Row/header templates and the panel (mirrors Blizzard's `Blizzard_TokenUI`) |
| `UI.lua` | Mixins, character-frame tab integration, dropdown, scroll list |

## Implementation notes

- The tab is injected by creating `GearUpgradeCostTabButton` from `CharacterFrameTabTemplate` (which self-registers into `CharacterFrame.Tabs`), appending the panel to `CHARACTERFRAME_SUBFRAMES`, and setting `CharacterFrame.numTabs = 4`. Title, frame width (400, matching the Currency tab), and tab-overflow shrinking are corrected via `hooksecurefunc` because Blizzard keeps that lookup table file-local.
- Known trade-off: writing `CHARACTERFRAME_SUBFRAMES`/`numTabs` from addon code taints values that Blizzard's `ToggleCharacter` reads when the C/U keybinds fire. This is the established pattern for character-frame tabs and `CharacterFrame` is not protected, but in combat edge cases it could produce "Interface action failed because of an AddOn" — worth testing C/U in combat once.
- The list uses the modern `ScrollBox` API (`CreateScrollBoxListLinearView` + `ScrollUtil.InitScrollBoxListWithScrollBar`) with `ListHeaderThreeSliceTemplate` accordion headers — the same pattern as the Currency tab.
- Midnight's addon restrictions ("Secret Values") only affect real-time combat data; this out-of-combat UI addon is unaffected.

Lint with [luacheck](https://github.com/lunarmodules/luacheck): `luacheck GearUpgradeCostTab/` (config in `.luacheckrc`).
