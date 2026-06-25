# Contributing

Thanks for taking a look. This is a small, single-purpose addon, but bug
reports, translations, and pull requests are all welcome.

## Reporting a bug

Open an [issue](https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab/issues)
using the **Bug report** form. The most useful reports include:

- the **addon version** (shown on the AddOns list, or on the Releases page),
- the **WoW build** (`/run print(GetBuildInfo())` in-game),
- any **error text** — enable Lua errors with `/console scriptErrors 1` (or use
  BugSack), and
- for a wrong cost, track, or missing item: a **screenshot of the row plus the
  item's tooltip**. The costs are read from the tooltip, so seeing both is what
  makes a cost bug fixable.

## Translations

Locales live in `Locales/`, one file per language. To add or fix a translation,
edit the relevant `Locales/<locale>.lua` and open a PR.

`Locales/enUS.lua` is the source of truth for which keys exist — a locale file
may only **override** keys that enUS already defines. The test suite enforces
this (and that every translated upgrade-track name still parses), so run the
checks below before opening the PR.

## Local development

See [README-dev.md](README-dev.md) for how the addon is structured and how to
symlink it into your AddOns folder for live testing (`/reload` to pick up
changes).

## Before opening a pull request

Run the checks locally — they need `lua` (5.1+) and `luacheck` on your `PATH`:

```sh
sh scripts/check.sh
```

That runs `luacheck` (config in `.luacheckrc`) and the locale regression suite
(`lua tests/run.lua`). Please also:

- keep each PR to one self-contained change,
- add a short, plain-language note to [`CHANGELOG.md`](CHANGELOG.md) and the
  technical detail to [`CHANGELOG-dev.md`](CHANGELOG-dev.md), and
- match the existing style — Lua 5.1, tabs for indentation, conventions encoded
  in `.luacheckrc`.

## Building a release

Releases run in CI: pushing a `v*` tag triggers
[`.github/workflows/release.yml`](.github/workflows/release.yml), which runs the
BigWigs packager to build the zip, publish a GitHub Release, and (once
configured) upload to CurseForge/Wago. CI does **not** run tests — run
`sh scripts/check.sh` locally before tagging.

```sh
sh scripts/check.sh                     # luacheck + tests (the local gate)
git tag vX.Y.Z && git push --tags       # CI packages + publishes
```

For a no-upload dry-run build into `.release/` (to inspect the zip first), run
`sh scripts/release.sh` locally — the addon is at the repo root so the packager
can find the `.toc` (see [docs/packaging.md](docs/packaging.md)); needs
`bash` >= 4.3.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
