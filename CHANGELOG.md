# Changelog

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
