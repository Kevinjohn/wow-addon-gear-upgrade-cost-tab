# Gear Upgrade Cost Tab

[![Release](https://img.shields.io/github/v/release/Kevinjohn/wow-addon-gear-upgrade-cost-tab?include_prereleases&sort=semver)](https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab/releases)
[![License: MIT](https://img.shields.io/github/license/Kevinjohn/wow-addon-gear-upgrade-cost-tab)](LICENSE)
![Interface](https://img.shields.io/badge/Interface-120007-blue)
![Last commit](https://img.shields.io/github/last-commit/Kevinjohn/wow-addon-gear-upgrade-cost-tab)

<!-- Keep the Interface badge above in step with `## Interface` in the .toc. -->

A World of Warcraft (retail) addon that shows what your gear upgrades will
cost — and which ones are free — without travelling to the upgrade vendor.

It adds a **Gear Upgrades** tab to your character window, right after
Character Info, Reputation, and Currency.

## Getting started

Once the addon is installed in your AddOns folder, restart the game (or type
`/reload`) and press **C** to open your character window. Click the **Gear
Upgrades** tab.

## What it shows

Three lists, each with a header you can click to collapse or expand:

- **Equipped** — everything you are wearing, with its item level, its
  upgrade track and rank (for example "Champion 5/6"), the crest cost of
  its next upgrade, and the total cost to upgrade it fully. Fully
  upgraded items are greyed out.
- **In Bag (next upgrade free)** — items in your bags whose next upgrade
  costs only gold, no crests. Great for spotting the spare rings and
  trinkets you forgot could be upgraded for free.
- **In Bag (crest required)** — items in your bags whose next upgrade
  costs crests.

Hover over any bag item to see its tooltip. The lists update on their own
when your bags change.

A bar below the lists can show how many of each crest you own, from the
most common on the left (Adventurer) to the rarest on the right (Myth). It
updates as you earn or spend crests, and hovering a crest shows its
tooltip. It is off by default — turn it on with **Show my crests** in the
dropdown.

Items that are "Warbound until equipped" are hidden from the bag lists
unless you opt in (see **Include Warbound items** below), because
upgrading one binds it to a single character.

## Screenshots

<!-- Drop your in-game captures into docs/img/ and they'll appear here. -->

![The Gear Upgrades tab in the character window](docs/img/tab.png)

## Options

The dropdown at the top of the tab has three parts.

**How costs are shown:**

- **Base costs** (the default) — the standard crest cost of each upgrade.
- **Discount aware** — applies your discounts: costs are halved on
  upgrade tracks where your warband has earned the matching "… of the
  Dawn" achievement, and an upgrade is marked **Free** when you have
  already earned a higher item level in that slot.

**Which bag items are shown:**

- **Include Uncommon items** (off by default) — also list green-quality
  gear in the bag sections.
- **Include Rare items** (off by default) — also list blue-quality gear
  in the bag sections.
- **Include Warbound items** (off by default) — also list "Warbound until
  equipped" gear. These are hidden by default because upgrading one binds
  it to that character, so it can no longer be passed around your
  warband.
- **Prioritise tier** (on by default) — when you are wearing a tier-set
  piece in a slot, bag items for that slot are hidden, so the lists never
  tempt you to break your set bonus.

**Display:**

- **Show my crests** (off by default) — adds a bar at the bottom of the
  tab showing how many of each crest you own; the lists shrink a little
  to make room.

Your choices are remembered between play sessions. If a bag section looks
empty only because the filters are hiding things, it will say so.

## Languages

The addon works in every language the game supports: English, German,
French, Spanish (EU and Latin America), Italian, Portuguese, Russian,
Korean, and Chinese (Simplified and Traditional).

## Something look wrong?

The cost numbers are verified in game where
possible, but if a cost, a discount, or a missing item looks off, please
[report it](https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab/issues)
— a screenshot of the row and the item's tooltip helps a lot.

---

**Installing a release:** download the latest `GearUpgradeCostTab` zip from the
[Releases page](https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab/releases),
unzip it into your `World of Warcraft/_retail_/Interface/AddOns/` folder, and
`/reload` (or restart the game).

**Contributing:** bug reports, translations, and pull requests are all welcome —
see [CONTRIBUTING.md](CONTRIBUTING.md). Released under the [MIT License](LICENSE).

Developers: see [README-dev.md](README-dev.md) for how the addon works,
data verification status, localization details, and tests.
