#!/usr/bin/env bash
# Everything the CI workflow runs, on this machine, in the same order.
#
# CI no longer runs on every push (a private repository bills macOS runner
# minutes at ten times the clock), so this is the check that a change has to
# pass. It is the same four scripts CI calls, with the same environment, and it
# leaves the same two artifacts behind: the rendered review screens under
# build/ui-review and the unsigned release candidate under build/release.
#
# What it cannot tell you is whether the change also builds on a machine that is
# not this one. Run the CI workflow by hand for that, before a release:
#   gh workflow run ci.yml --ref main
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

languages=("${@:-en ko}")
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
export EVOBAR_SWIFTPM_SCRATCH="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"

echo "==> Build and run unit tests"
./Scripts/check.sh

echo "==> Render isolated UI review screens (${languages[*]})"
# shellcheck disable=SC2086
./Scripts/review-ui.sh ${languages[*]}

echo "==> Build unsigned release candidate"
EVOBAR_ALLOW_UNSIGNED="1" ./Scripts/package-release.sh 0.1.0

echo "==> Launch packaged app smoke test"
./Scripts/smoke-test-app.sh build/EvoBar.app

echo
echo "All CI steps passed locally."
echo "  review screens: build/ui-review"
echo "  release candidate: build/release"
echo "A clean-machine run still needs: gh workflow run ci.yml --ref main"
