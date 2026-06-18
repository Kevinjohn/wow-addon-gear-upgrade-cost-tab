#!/usr/bin/env sh
# Build an installable addon zip into .release/.
#
# Why not the BigWigs packager? It expects the .toc at the repository root (a
# "flat" addon repo). This repo keeps the addon in the GearUpgradeCostTab/
# subfolder (so the repo can carry README/tests/docs/scripts alongside it), so
# we build the zip directly instead: archive the tracked addon files, substitute
# the @project-version@ keyword the way the packager would, and zip it.
#
# Usage:
#   sh scripts/release.sh            # version from `git describe` (latest tag, +commits if ahead)
#   sh scripts/release.sh 0.8.0      # explicit version
#
# For a clean release number, tag first:  git tag v0.8.0 && sh scripts/release.sh
#
# Publishing to CurseForge / Wago later: either upload the built zip through
# their web UI, or adopt the BigWigs packager (which needs a flat repo layout —
# see docs/release-checklist.md).
set -e
cd "$(dirname "$0")/.."

ADDON=GearUpgradeCostTab
VER=${1:-$(git describe --tags --always 2>/dev/null | sed 's/^v//')}
[ -n "$VER" ] || { echo "error: could not determine a version (no tags, no commits?)" >&2; exit 1; }

OUT=.release
rm -rf "$OUT"
mkdir -p "$OUT"

# Tracked files only (no .DS_Store, no stray exec bits), taken from the last commit.
git archive --format=tar --prefix="$ADDON/" "HEAD:$ADDON" | ( cd "$OUT" && tar -xf - )

# Substitute the version keyword in the packaged TOC (portable in-place edit).
toc="$OUT/$ADDON/$ADDON.toc"
tmp=$(mktemp)
sed "s/@project-version@/$VER/g" "$toc" > "$tmp" && mv "$tmp" "$toc"

( cd "$OUT" && zip -r -X -q "$ADDON-$VER.zip" "$ADDON" )
echo "built $OUT/$ADDON-$VER.zip"
