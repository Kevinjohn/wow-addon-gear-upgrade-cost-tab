# WoW Addon — Release-Readiness Checklist

A reusable checklist for getting a WoW addon's GitHub repo ready for a public
release. This repo was set up with it; copy it into your other addon repos and
work top to bottom. It assumes a lean, GitHub-only setup (no CI workflows;
release zips built locally with the BigWigs packager).

> **Layout (do this first — it bites late otherwise).** Put the addon's loaded
> files (`.toc`, `.lua`, any `Locales/`, `LICENSE`) at the **repository root**,
> *not* in an `ADDON/` subfolder. The BigWigs packager only discovers a `.toc`
> at the repo root (`$topdir/<package-as>.toc`); `package-as` renames the folder
> *inside the zip*, it can't point the packager at a subfolder. A nested
> `ADDON/ADDON.toc` fails with "Could not find an addon TOC file." `.pkgmeta`'s
> `ignore:` list (step 4) keeps the repo-only files out of the zip, so the root
> stays clean. Converting an existing subfolder repo: see the migration steps at
> the end of this file.

Placeholders used below — set these first:
- `OWNER`  = GitHub user/org      (e.g. `Kevinjohn`)
- `REPO`   = GitHub repo slug     (e.g. `wow-addon-foo`)
- `ADDON`  = in-game / zip folder name (e.g. `FooAddon`)  ← must match `package-as`
            and the `.toc` base name (`ADDON.toc` at the repo root)

## 0. Sanity
- [ ] Confirm the real remote: `git remote -v`  (badges/links die on a wrong slug)
- [ ] Confirm `ADDON.toc` is at the **repo root** (not `ADDON/ADDON.toc`) and its
      base name == `ADDON` == `.pkgmeta`'s `package-as` (see the Layout note above)

## 1. LICENSE
- [ ] Add a LICENSE (MIT is the usual pick). GitHub → Add file → "Choose a license
      template" → MIT, set year + name. Confirm the sidebar shows the license.

## 2. README badges + screenshots + footer
- [ ] Badge row directly under the H1 (omit CurseForge/CI badges until those exist):
```
[![Release](https://img.shields.io/github/v/release/OWNER/REPO?include_prereleases&sort=semver)](https://github.com/OWNER/REPO/releases)
[![License: MIT](https://img.shields.io/github/license/OWNER/REPO)](LICENSE)
![Interface](https://img.shields.io/badge/Interface-XXXXXX-blue)
![Last commit](https://img.shields.io/github/last-commit/OWNER/REPO)
```
- [ ] `## Screenshots` section → `![...](docs/img/foo.png)` (keep the Interface badge
      in step with `## Interface` in the .toc)
- [ ] Footer: install-from-Releases line + links to CONTRIBUTING.md and LICENSE

## 3. .toc metadata
- [ ] `## Version: @project-version@`  (packager stamps the git tag at build time;
      a raw checkout shows the literal token — accepted trade-off)
- [ ] `## X-License: MIT`
- [ ] `## X-Website: https://github.com/OWNER/REPO`
- [ ] Stub for later (commented so the client/packager ignore them):
```
# To publish to CurseForge / Wago later, create the projects then uncomment:
# ## X-Curse-Project-ID: 000000
# ## X-Wago-ID: 000000
```

## 4. .pkgmeta  (repo root)
```yaml
package-as: ADDON
enable-nolib-creation: no
# Ship the curated CHANGELOG.md instead of the packager's git-log dump (see note).
manual-changelog:
  filename: CHANGELOG.md
  markup-type: markdown
ignore:
  - .release
  - .github
  - .gitignore
  - .gitattributes
  - .luacheckrc
  - .pkgmeta
  - scripts
  - tests
  - docs
  - README.md
  - README-dev.md
  - CONTRIBUTING.md
  - SECURITY.md
  - CODE_OF_CONDUCT.md
```
- [ ] **Changelog gotcha:** the packager *always* puts a changelog in the zip —
      with no config it generates one from the git log (commit trailers and all)
      and adds it **regardless of `ignore:`**. The `manual-changelog` block ships
      your curated `CHANGELOG.md`; when you use it, keep `CHANGELOG.md` **out** of
      `ignore:` (the packager has to read it).
- [ ] **Do NOT reach for `move-folders` to keep a subfolder addon.** Tested
      (2026-06-18): it does *not* point the packager at a nested `.toc` — TOC
      discovery runs first, so a nested `ADDON/ADDON.toc` still dies with "Could
      not find an addon TOC file," and a one-level `ADDON: ADDON` mapping produces
      an empty build. Put the `.toc` at the repo root instead (Layout note up top;
      migration steps at the bottom). `move-folders` is for splitting one repo into
      multiple *output* addon folders, not for source discovery.

## 5. Local scripts  (no CI)
- [ ] `scripts/check.sh` (chmod +x) — luacheck + tests, auto-detecting the interpreter:
```sh
#!/usr/bin/env sh
set -e
cd "$(dirname "$0")/.."
echo "==> luacheck"; luacheck *.lua   # + Locales/*.lua etc. if your Lua is nested
LUA=""
for c in lua lua5.4 lua5.3 lua5.2 lua5.1 luajit; do
  command -v "$c" >/dev/null 2>&1 && { LUA="$c"; break; }
done
[ -n "$LUA" ] || { echo "no Lua interpreter found" >&2; exit 1; }
echo "==> tests ($LUA)"; "$LUA" tests/run.lua   # adjust if your test entrypoint differs
```
- [ ] `scripts/release.sh` (chmod +x) — BigWigs packager, no-upload by default:
```sh
#!/usr/bin/env sh
set -e
cd "$(dirname "$0")/.."
[ "$#" -eq 0 ] && set -- -d   # -d = build zip into .release/, upload nothing
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- "$@"
```
  Needs `bash` >= 4.3 (the packager is bash; macOS ships 3.2 — `brew install bash`)
  and the flat layout (Layout note up top). To publish later: fill the X-* .toc IDs,
  export `CF_API_KEY` / `WAGO_API_TOKEN` / `GITHUB_OAUTH`, and run without `-d`.

## 6. Community-health docs
- [ ] `CONTRIBUTING.md` — bug reports (addon ver, `GetBuildInfo()`, error text via
      `/console scriptErrors 1`, screenshot of row+tooltip); translations as PRs to
      `Locales/<locale>.lua`; "run scripts/check.sh before a PR"; MIT note
- [ ] `SECURITY.md` — short + honest: addon runs in WoW's Lua sandbox (no FS/network),
      only local saved-vars; private contact email; "latest version supported"
- [ ] `CODE_OF_CONDUCT.md` — **link to** Contributor Covenant 2.1, don't inline the full
      text (the enumerated list trips content filters; a short by-reference file is cleaner):
```
This project adopts the Contributor Covenant v2.1
(https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
Be respectful, welcoming, constructive. Report concerns privately to <email>.
```

## 7. .github templates  (templates only — NO workflows/)
- [ ] `.github/ISSUE_TEMPLATE/bug_report.yml` (form: addon version, WoW build,
      what happened, repro, error text, screenshot)
- [ ] `.github/ISSUE_TEMPLATE/feature_request.yml`
- [ ] `.github/ISSUE_TEMPLATE/config.yml` → `blank_issues_enabled: false`
- [ ] `.github/pull_request_template.md` (summary + "ran scripts/check.sh" + "CHANGELOG updated")

## 8. .gitignore
- [ ] Add the packager output dir:
```
# BigWigs packager output
.release/
```

## 9. Gotchas (learned the hard way)
- [ ] **Exec-bit noise:** AddOns-folder symlinks on macOS flip Lua/XML/.toc to `+x`.
      Source files must NOT be executable. With the flat layout the files are at the
      repo root, so fix before committing:
      `chmod 644 *.lua *.xml *.toc Locales/*.lua`
      then verify `git diff --summary | grep "mode change"` is empty. Keep `scripts/` at 755.
      (Recurs? treat it as an env quirk; don't use `core.fileMode false` or your
      `scripts/` lose their `+x` in the index.)
- [ ] **Nested layout breaks the packager.** It only finds the `.toc` at the repo
      root (`-t <dir>` needs `.git` there too, so it won't help), and `move-folders`
      does NOT fix discovery (tested — see §4). The fix is the flat layout: Layout
      note up top, migration steps at the bottom.
- [ ] **Packager needs `bash` >= 4.3** (macOS ships 3.2 — `brew install bash`),
      plus `git`, `curl`, `zip`.
- [ ] **CHANGELOG** — keep one in "Keep a Changelog" format if you don't already.

## 10. Verify
- [ ] `sh scripts/check.sh` → luacheck clean + tests pass
- [ ] README renders; badges resolve (only the screenshot placeholder is missing)
- [ ] Names/emails/years correct in LICENSE / SECURITY / CODE_OF_CONDUCT
- [ ] Dry-run zip: `sh scripts/release.sh` → unzip `.release/` contains only the `ADDON`
      folder, and its .toc shows a real version (not `@project-version@`)

## 11. Ship
- [ ] Commit (focused commit, separate from feature work)
- [ ] `git push`
- [ ] Tag: `git tag vX.Y.Z && git push --tags`  (resolves the version badge + `@project-version@`)
- [ ] Build the zip and attach to a GitHub Release (`gh release create vX.Y.Z .release/*.zip`)
- [ ] Drop screenshot(s) into `docs/img/`

---

## Per-repo adaptation notes
- **Interface badge** (`XXXXXX`) and the test entrypoint (`tests/run.lua`) vary — adjust both.
- If a repo already publishes to CurseForge/Wago, *do* add the download badges
  (`https://img.shields.io/...` or `cf.way2muchnoise.eu/<id>.svg`) and a CI badge if it
  has workflows — this checklist assumes the lean GitHub-only setup.

## Migrating a subfolder repo to flat

If an addon currently lives in `repo/ADDON/…` and you want the packager-native
flat layout (`.toc` at the repo root), from the repo root:

1. Move the addon's files up one level and drop the now-empty folder:
```sh
git mv ADDON/* .
rmdir ADDON 2>/dev/null || true
```
   (If `Locales/` or any dotfiles don't move with the glob, repeat
   `git mv ADDON/<thing> .` for each.)
2. `.pkgmeta`: keep `package-as: ADDON`, **delete the `move-folders:` block** (no
   longer needed). The `ignore:` list now keeps the repo-only root files out of the zip.
3. Fix paths that assumed the subfolder: `scripts/check.sh` (`luacheck ADDON` →
   `luacheck .`), the test harness's addon dir, `.luacheckrc`, and any README-dev
   symlink instructions.
4. The dev symlink now points the **repo root** into AddOns as `ADDON`
   (`ln -s /path/to/repo ".../AddOns/ADDON"`). Repo-meta files (`.git`, README,
   scripts) then sit beside the addon in-game, but WoW ignores everything that
   isn't `.lua`/`.xml`/`.toc`.
5. Verify: `sh scripts/release.sh` → the zip is a single `ADDON/` folder, version stamped.
