# Security Policy

This is a World of Warcraft addon: it runs as Lua inside the game's addon
sandbox. It has no access to your filesystem, makes no network connections, and
cannot run arbitrary code outside the client. The only data it stores is its own
saved-variables table (`GearUpgradeCostTabDB`), kept locally by the WoW client
with your other addon settings.

In other words, the realistic attack surface is small. The most likely
"security" issues are things like the addon mishandling input from a tooltip or
API in a way that causes a Lua error. Those are welcome as ordinary
[bug reports](https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab/issues).

## Reporting something sensitive

If you believe you've found something that shouldn't be discussed in a public
issue, email **email@kevinjohngallagher.com** instead of opening an issue, and
I'll respond as soon as I reasonably can.

## Supported versions

Only the latest released version receives fixes.
