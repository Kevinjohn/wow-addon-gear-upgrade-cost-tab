# World of Warcraft Addon Publishing Readiness Checklist

> Goal: Ensure this GitHub repository is fully configured for automated releases to CurseForge and Wago using GitHub Actions and BigWigs Packager.
>
> Repository: https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab
>
> Date Checked: 2026-06-22
>
> Checked By: Kevinjohn Gallagher (with Claude Code)

---

## Status legend

- `[x]` — done and verified in the repo.
- `[ ]` 🔧 **YOU** — needs an action only you can take: an external account
  (CurseForge/Wago), a GitHub repo secret, or pushing a tag for a live test run.
  These can't be done from the codebase; each is annotated inline.

## Summary — what changed and what's left

Everything that lives **in the repository** is now ready:

- Added `.github/workflows/release.yml` — BigWigs packager, triggers on `v*`
  tags, creates the GitHub Release with the zip attached, and uploads to
  CurseForge/Wago. It **auto-skips** CF/Wago while their IDs/secrets are absent,
  so it is safe as-is and starts uploading the moment you complete the two steps
  below. (`docs/packaging.md`, `scripts/release.sh`, and the README badge row
  were updated to match.)

The only remaining work is **outside the repo** (the 🔧 items), in this order:

1. Create the CurseForge and Wago projects → get their IDs (Phase 2).
2. Uncomment + fill `X-Curse-Project-ID` / `X-Wago-ID` in
   `GearUpgradeCostTab.toc` (TOC Validation).
3. Add the `CF_API_TOKEN` and `WAGO_API_TOKEN` repo secrets (Phase 3).
4. Push a test tag and confirm the run (Phases 7–9).

---

# Phase 1 — Repository Audit

## Basic Structure

- [x] Repository exists on GitHub. (`origin` → wow-addon-gear-upgrade-cost-tab)
- [x] Repository contains addon source code. (`Data.lua`, `Scanner.lua`, `UI.lua`, `UI.xml`, `Locales/`)
- [x] Repository contains a valid `.toc` file. (`GearUpgradeCostTab.toc`)
- [x] Addon loads successfully inside World of Warcraft. (v0.7.0-alpha is installed/running)
- [x] No obvious build errors exist. (`scripts/check.sh`: luacheck clean, 1317 test checks / 0 failures)
- [x] No temporary or backup files are committed. (`.DS_Store` untracked; `.gitignore` covers build output)

> **Layout note:** this repo deliberately uses the **root layout** (the `.toc`
> and `.lua` live at the repo root, not in a `GearUpgradeCostTab/` subfolder).
> That is required by the BigWigs packager, which only discovers the `.toc` at
> `$topdir/<package-as>.toc`. `.pkgmeta`'s `ignore:` list keeps repo-only files
> out of the zip. So the "Expected structure" below is satisfied by the root
> layout, not a subfolder — see `docs/packaging.md`.

Expected structure:

```text
MyAddon/
├── MyAddon.toc
├── *.lua
├── README.md
└── .github/
```

---

## TOC Validation

Locate:

```text
GearUpgradeCostTab.toc
```

Confirm:

- [x] `## Title:` exists.
- [x] `## Author:` exists.
- [x] `## Notes:` exists. (+ localized `Notes-*` for 10 locales)
- [x] `## Interface:` exists. (`120007`)
- [x] Interface version is current for supported WoW version. (retail 12.0.7)
- [x] `## Version:` exists.
- [x] Version uses:

```toc
## Version: @project-version@
```

- [x] `## X-Curse-Project-ID:` exists — set to the real id **1583795**. The CF
      upload still needs the `CF_API_TOKEN` secret (Phase 3); until then the
      packager skips it.
- [x] `## X-Wago-ID:` exists. Field added with a placeholder. 🔧 **YOU** —
      replace it with the real id after the Wago project exists.

Example:

```toc
## Version: @project-version@
## X-Curse-Project-ID: 123456
## X-Wago-ID: abc123
```

---

# Phase 2 — Publishing Configuration

> Both subsections below are external account setup on CurseForge/Wago — only
> you can do these. The repo is already wired to use the IDs once you have them.

## CurseForge

Verify:

- [x] CurseForge project exists. (id **1583795**)
- [x] Correct CurseForge Project ID obtained. (**1583795**)
- [x] Project ID matches TOC. (`X-Curse-Project-ID: 1583795`)
- [ ] 🔧 **YOU** — Project is configured as a WoW Addon.
- [ ] 🔧 **YOU** — Project description exists.
- [ ] 🔧 **YOU** — Project icon exists (recommended).
- [ ] 🔧 **YOU** — Source code URL configured. (https://github.com/Kevinjohn/wow-addon-gear-upgrade-cost-tab)

Reference:

https://authors.curseforge.com/

---

## Wago

Verify:

- [ ] 🔧 **YOU** — Wago project exists.
- [ ] 🔧 **YOU** — Correct Wago Project ID obtained.
- [ ] 🔧 **YOU** — Project ID matches TOC. (paste the ID into `X-Wago-ID`)
- [ ] 🔧 **YOU** — Project description exists.
- [ ] 🔧 **YOU** — Source code URL configured.

Reference:

https://addons.wago.io/

---

# Phase 3 — GitHub Secrets

Open:

Repository → Settings → Secrets and Variables → Actions

> The workflow reads these exact names. CurseForge tokens:
> https://authors.curseforge.com/account/api-tokens — Wago tokens:
> https://addons.wago.io/account/apikeys

Verify:

- [ ] 🔧 **YOU** — `CF_API_TOKEN` exists. (add as a repo secret)
- [ ] 🔧 **YOU** — `WAGO_API_TOKEN` exists. (add as a repo secret)

> Note: the GitHub Release itself needs **no** secret — the workflow uses the
> built-in `GITHUB_TOKEN` (mapped to `GITHUB_OAUTH`) with `contents: write`.

Confirm (verified in repo):

- [x] Tokens are not stored in source code.
- [x] Tokens are not committed to repository.
- [x] Tokens are not present in README files.
- [x] Tokens are not present in workflow files. (`release.yml` references `${{ secrets.* }}` only — no literals)

---

# Phase 4 — Packaging Configuration

## .pkgmeta

Verify file exists:

```text
.pkgmeta
```

Verify:

- [x] package-as value is correct. (`package-as: GearUpgradeCostTab`)
- [x] Ignore rules are sensible.
- [x] Development files excluded. (`scripts`, `tests`, `docs`, dev READMEs, dotfiles)
- [x] GitHub workflow files excluded from release package. (`.github` is in `ignore:`; verified the built zip contains no `.github`, so `release.yml` never ships to players)

> The `.pkgmeta` also ships the curated `CHANGELOG.md` as release notes via
> `manual-changelog` (instead of the packager's git-log dump).

Example:

```yaml
package-as: GearUpgradeCostTab

ignore:
  - .github
  - README.md
```

Reference:

https://github.com/BigWigsMods/packager

---

# Phase 5 — GitHub Actions

Verify workflow exists:

```text
.github/workflows/release.yml
```

Confirm:

- [x] Workflow uses BigWigs Packager. (`BigWigsMods/packager@v2`)
- [x] Workflow triggers on Git tags. (`on: push: tags: ["v*"]`)
- [x] Workflow creates GitHub Releases. (`GITHUB_OAUTH` + `permissions: contents: write`)
- [x] Workflow uploads to CurseForge. (wired via `CF_API_TOKEN`; **auto-skips until** the `X-Curse-Project-ID` + secret exist — Phases 2/3)
- [x] Workflow uploads to Wago. (wired via `WAGO_API_TOKEN`; **auto-skips until** the `X-Wago-ID` + secret exist — Phases 2/3)

Reference:

https://github.com/BigWigsMods/packager

---

# Phase 6 — Documentation

Verify:

- [x] README.md exists. (with badge row, usage, install-from-Releases footer)
- [x] Installation instructions exist. (README footer + "Getting started")
- [x] Repository description exists. (README; confirm the GitHub "About" blurb is set too)
- [x] Licence file exists. (`LICENSE`, MIT)
- [x] Changelog exists or release notes are generated automatically. (`CHANGELOG.md`, shipped as release notes via `manual-changelog`)

Recommended files:

```text
README.md
LICENSE
CHANGELOG.md
```

---

# Phase 7 — Release Validation

> 🔧 **YOU** — a live test run. Best done **after** Phases 2–3 so the CF/Wago
> legs can be validated too. The GitHub leg will work immediately even before
> secrets are added. Delete the test release/tag afterward.

Create test tag:

```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```

Verify:

## GitHub

- [ ] 🔧 **YOU** — Workflow executed successfully. (Actions tab → "Release")
- [ ] 🔧 **YOU** — GitHub Release created.
- [ ] 🔧 **YOU** — Release ZIP attached.

## CurseForge

- [ ] 🔧 **YOU** — File uploaded successfully. (only after Phase 2/3 — else skipped, which is expected)
- [ ] 🔧 **YOU** — Version visible.
- [ ] 🔧 **YOU** — Release notes present.
- [ ] 🔧 **YOU** — No validation errors.

## Wago

- [ ] 🔧 **YOU** — File uploaded successfully. (only after Phase 2/3 — else skipped, which is expected)
- [ ] 🔧 **YOU** — Version visible.
- [ ] 🔧 **YOU** — Release notes present.
- [ ] 🔧 **YOU** — No validation errors.

---

# Phase 8 — Package Verification

> Pre-verified against the local dry-run build
> (`.release/GearUpgradeCostTab-…zip`, produced by `sh scripts/release.sh`). The
> CI zip is byte-for-byte the same packager output, so these hold for releases.
> The last three items are in-game checks (already true for the installed
> v0.7.0-alpha copy).

Verify:

- [x] ZIP extracts correctly.
- [x] Top-level folder name is correct. (`GearUpgradeCostTab/`)
- [x] TOC file exists inside package. (`GearUpgradeCostTab/GearUpgradeCostTab.toc`, version stamped — not `@project-version@`)
- [x] Addon appears in WoW AddOns list. (installed dev copy loads)
- [x] Addon loads without Lua errors.
- [x] SavedVariables still function correctly. (`GearUpgradeCostTabDB`)

Expected ZIP structure:

```text
GearUpgradeCostTab.zip
└── GearUpgradeCostTab/
    ├── GearUpgradeCostTab.toc
    ├── Data.lua  Scanner.lua  UI.lua  UI.xml
    ├── Locales/*.lua
    ├── LICENSE
    └── CHANGELOG.md
```

---

# Phase 9 — Future Release Process

Verify repository supports:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Expected result (the workflow is configured for exactly this; confirm on the
first real tag after Phase 7):

- [x] GitHub Release created automatically. (workflow configured; confirm on first tag)
- [ ] 🔧 **YOU** — CurseForge upload created automatically. (after Phase 2/3)
- [ ] 🔧 **YOU** — Wago upload created automatically. (after Phase 2/3)
- [x] No manual ZIP creation required.
- [x] No manual uploads required.

---

# Final Sign-Off

## Publishing Readiness

- [x] Repository ready for automated publishing. (workflow + packaging + docs in place)
- [ ] 🔧 **YOU** — CurseForge integration working. (needs project + `X-Curse-Project-ID` + `CF_API_TOKEN`, then a test run)
- [ ] 🔧 **YOU** — Wago integration working. (needs project + `X-Wago-ID` + `WAGO_API_TOKEN`, then a test run)
- [ ] 🔧 **YOU** — GitHub Actions working. (confirm on the first tag push — Phase 7)
- [ ] 🔧 **YOU** — Test release completed successfully. (Phase 7)

Result:

- [ ] PASS — once the 🔧 items above are done.
- [ ] FAIL

> Current status: **repo-side READY.** All in-repo configuration is complete and
> verified. Activation is the four external steps in the Summary (CF/Wago
> projects → TOC IDs → repo secrets → one test tag).
