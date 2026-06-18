#!/usr/bin/env sh
# Build a release zip with the BigWigs packager.
#
# This repo keeps the addon in the GearUpgradeCostTab/ subfolder; the packager
# is taught to find it by the `move-folders` directive in .pkgmeta, so it works
# without flattening the repo.
#
# By default this runs "dist only" (-d): it builds the zip into .release/ and
# uploads nothing — the right mode until CurseForge / Wago projects exist.
#
# To publish later:
#   1. Create the CurseForge / Wago projects and fill X-Curse-Project-ID /
#      X-Wago-ID in GearUpgradeCostTab/GearUpgradeCostTab.toc.
#   2. Export the tokens:
#         export CF_API_KEY=...        # CurseForge
#         export WAGO_API_TOKEN=...    # Wago
#         export GITHUB_OAUTH=...      # GitHub personal access token (for the Release)
#   3. Run with your own flags to upload, e.g.  sh scripts/release.sh -p 0000 -a abcd
#
# The packager reads the version from the latest git tag, so tag first:
#   git tag v0.8.0 && git push --tags
set -e

cd "$(dirname "$0")/.."

# Default to a no-upload build unless the caller passes their own flags.
if [ "$#" -eq 0 ]; then
	set -- -d
fi

curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- "$@"
