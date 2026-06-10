# Dev notes: detecting equipped tier (class set) pieces

The "Prioritise tier" filter needs to answer one question per equipped slot:
*is this item a set ("tier") piece worth protecting from upgrade
suggestions?* There is no `C_Item.IsTierPiece()`. Getting a working answer
took three iterations on 2026-06-10, two of which were killed by in-game
testing on the same day they were written. This file records what was
tried, exactly why each attempt failed, and the evidence, so nobody
re-walks this path — including us.

All build-data references are to retail 12.0.5.67823 (Midnight) unless
noted. The test character's helm throughout is item **250024 "Branches of
the Luminous Bloom"** (Druid tier head, ItemSet 1980 "Sprouts of the
Luminous Bloom").

## What the platform actually offers

Researched up front (warcraft.wiki.gg, Gethe/wow-ui-source `live`,
wago.tools db2, 2026-06-10):

- `C_Item.GetItemInfo` returns 18 values; **#15 `expansionID`**, **#16
  `setID`** (nilable — `nil` for non-set items, and the whole return list
  is empty for uncached items).
- **No "is tier" flag exists anywhere.** The ItemSet db2 (990 rows) only
  distinguishes legacy sets (`SetFlags=1`, 703 rows, bonuses inactive) and
  the Warmonger PvP appearance sets (`SetFlags=4`, 5 rows). Class tier
  sets (IDs 1978–1990, one per class) share `SetFlags=0` with crafted and
  world-drop sets. An `ItemSetSpec` table does not exist in this build.
- **No tooltip line type identifies the set-name line** — the
  `Enum.TooltipDataLineType` values (0–43) have entries for
  `ItemUpgradeLevel`, `ItemBinding`, etc., but the "Sprouts of the
  Luminous Bloom (2/5)" header arrives as a generic text line
  (`ITEM_SET_NAME = "%s (%d/%d)"`).
- Blizzard's only first-party heuristic is in `Blizzard_WeeklyRewards.lua`
  (`FindFirstNonRaidActivityWithClassSetReward`), with their own comment
  admitting it is an assumption:

  ```lua
  -- We are working under the assumption that a set item which is class specific is a "Class Set"
  local setID = select(16, C_Item.GetItemInfo(reward.id));
  if setID and C_Item.IsItemSpecificToPlayerClass(reward.id) then
  ```

  Note for later: Blizzard passes **numeric item IDs** here, not links.
- WeakAuras doesn't even try: its "Item Set Equipped" trigger makes the
  user type a numeric set ID from Wowhead, then counts equipped slots
  whose `setID` matches.

## Attempt 1: Blizzard's heuristic + an expansion guard — wrong in principle

```lua
setID and C_Item.IsItemSpecificToPlayerClass(link)
      and expansionID == (LE_EXPANSION_LEVEL_CURRENT or GetExpansionLevel())
```

The expansion leg was our addition (Blizzard has no such leg) to stop
*legacy* class tiers — which pass both of Blizzard's checks — from
suppressing current upgrades. It is wrong in principle, not just in
practice:

- `LE_EXPANSION_LEVEL_CURRENT` tracks the **client**, not the gear.
  Ketho/BlizzardInterfaceResources history shows it flipped 10 → 11 on the
  12.0.0 **prepatch** build (committed 2026-01-23) — roughly six weeks
  before any Midnight tier existed on a player (Season 1 opened
  2026-03-17). During every prepatch window the comparison rejects all
  genuinely-current tier.
- It permanently rejects **previous-season tier** (TWW pieces report
  `expansionID` 10), which players demonstrably still wear and upgrade
  early in an expansion — exactly the gear the filter exists to protect.
- `GetExpansionLevel()` as a fallback is account-level
  (`min(GetAccountExpansionLevel(), GetServerExpansionLevel())`), another
  client property.
- The whole `LE_EXPANSION_*` constant family is deprecated as of Midnight
  per warcraft.wiki.gg — a future-removal time bomb.

Replaced before in-game testing with: **the equipped piece must itself be
on an upgrade track** (parsed from its tooltip, which this addon already
does for every equipped row). Legacy tier has no current crest track, so
it is excluded *behaviorally* instead of by expansion math. Ironically,
the test helm's `expansionID` later dumped as 11 — this leg would have
passed for it — but the guard was independently broken for the prepatch
and previous-season cases.

## Attempt 2: Blizzard's own class-lock API is broken for item links

```lua
setID and C_Item.IsItemSpecificToPlayerClass(link)  -- plus the upgrade-line leg
```

First in-game test: tier helm equipped, filter on, Head bag rows still
listed. Diagnostic dump on the live client:

```
/dump GetInventoryItemLink("player",1),
      select(15, C_Item.GetItemInfo(link)),        -- → 11 (expansionID)
      C_Item.IsItemSpecificToPlayerClass(link)     -- → false
```

`C_Item.IsItemSpecificToPlayerClass(itemLink)` returned **false** for an
equipped Druid tier helm, on a Druid. The item data is not at fault:
ItemSparse for 250024 has `AllowableClass = 1024` (Druid-only bitmask) and
`ItemSet = 1980`; the tooltip shows the class restriction. The API simply
gives the wrong answer for this input. Blizzard's own caller passes
numeric `reward.id`s, so the link-handling path is plausibly just broken
(untested whether a bare itemID works — by then we no longer wanted the
dependency; an addon mostly holds links).

Two diagnostic lessons from this round:

- **`/dump` truncates a multi-return call in the middle of an expression
  list to a single value** (standard Lua expression adjustment). Our first
  dump put `select(15, …)` in the middle, so `setID` was silently
  swallowed and `[2]=11` was *expansionID*, not the set. Put multi-return
  calls **last**.
- A db2-verified fact ("this item is class-locked") and a runtime-verified
  fact ("this API says so") are different claims. Verify the API leg, not
  the data leg.

## Attempt 3 (withdrawn): tooltip "Classes: …" line

Replacement idea for the class leg: match the tooltip's own restriction
line via a pattern derived from `ITEM_CLASSES_ALLOWED` (`"Classes: %s"`),
locale-safe by construction — the same technique the upgrade-line parser
uses. Written, shipped to the test character, **helms still showed**.
Root cause never determined (a stale `/reload` or the line genuinely
missing from `C_TooltipInfo.GetInventoryItem` data — equipped tooltips
were never dumped to check), because at that point the calculus changed:
this leg existed only to add precision (excluding PvP appearance sets),
and it was the **second unverified dependency in a row**. Swapping one
unverifiable leg for another was the wrong bet. Withdrawn.

## What shipped

```lua
-- Data.lua
function ns.IsSetItem(itemLink)
    return (select(16, C_Item.GetItemInfo(itemLink))) ~= nil
end

-- Scanner.lua (GetEquippedTierSlots)
itemLink and ns.IsSetItem(itemLink)
         and ParseUpgradeFromTooltip(C_TooltipInfo.GetInventoryItem("player", slot))
```

Two legs, **both runtime-verified on a live character before shipping**:

1. **Set membership** — `setID` (return 16) works with item links: the
   test helm's link dumps `1980`. Confirmed in game 2026-06-10.
2. **On an upgrade track** — the same tooltip parse the entire addon is
   built on, in production since v0.1.0.

This is also, full circle, what the addon author suggested as the
fallback in the very first feature request: detect tier by set
membership, with everything cleverer layered on top having failed.

Scope the two legs produce:

| Equipped item | Suppresses its slot? | Why |
| --- | --- | --- |
| Current/previous-season class tier | yes | setID + crest track |
| Truly-legacy tier (any class) | no | no current upgrade track |
| Crafted gear, incl. crafted "sets" | no | recrafting, never a crest track |
| The 4 "set look" off-slots (cloak/wrist/waist/feet) | no | `ItemSet = 0` in db2 — no setID |
| PvP appearance sets (Warmonger) on a PvP upgrade track | **yes** | known trade-off — no class leg |

The last row is the precision we paid for reliability. It arguably still
matches the filter's intent ("don't tempt me to replace an equipped set"),
and the checkbox turns the whole filter off.

## Lessons

1. **db2/docs-verified ≠ runtime-verified.** Every leg of a heuristic
   needs its own in-game check; one `/dump` per leg, multi-return calls
   last.
2. **Blizzard's internal usage doesn't transfer.** An API that works for
   their caller (numeric itemIDs, vault context) can fail for addon
   inputs (item links, equipped slots).
3. **Client-version constants are not gear properties.** Anything keyed
   to `LE_EXPANSION_LEVEL_CURRENT`-style globals breaks at prepatch and
   misclassifies previous-season items — and that family is deprecated.
4. **Prefer legs the addon already exercises.** The tooltip upgrade-line
   parser had thousands of in-game executions behind it; both surviving
   legs were chosen because their failure modes were already known.
5. **When a precision leg costs a second unverified dependency, drop the
   leg.** Fail-open beats inert: a false positive shows a few extra
   hidden rows; a false negative silently disables the feature the user
   ticked.

## References

- Blizzard heuristic: [`Blizzard_WeeklyRewards.lua` (live)](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua)
- [`C_Item.GetItemInfo`](https://warcraft.wiki.gg/wiki/API_C_Item.GetItemInfo) (return 15/16 semantics, cache caveat)
- [`C_Item.IsItemSpecificToPlayerClass`](https://warcraft.wiki.gg/wiki/API_C_Item.IsItemSpecificToPlayerClass) (signature only; no semantics documented)
- [`LE_EXPANSION`](https://warcraft.wiki.gg/wiki/LE_EXPANSION) / [`ExpansionLevel`](https://warcraft.wiki.gg/wiki/ExpansionLevel) (deprecation note), [`GetExpansionLevel`](https://warcraft.wiki.gg/wiki/API_GetExpansionLevel)
- Constant flip history: [Ketho/BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources) `Resources/LuaEnum.lua`, commits for builds 11.2.7.64978 (`= 10`) → 12.0.0.65512 (`= 11`)
- db2: [ItemSet](https://wago.tools/db2/ItemSet?build=12.0.5.67823) (sets 1978–1990), ItemSparse rows via `https://wago.tools/db2/ItemSparse?build=12.0.5.67823&filter[ID]=exact:250024` (`AllowableClass=1024`, `ItemSet=1980`)
- WeakAuras' approach: [`Prototypes.lua`](https://github.com/WeakAuras/WeakAuras2/blob/main/WeakAuras/Prototypes.lua) "Item Set Equipped" (user-supplied set ID)
