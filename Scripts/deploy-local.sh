#!/usr/bin/env bash
# Install the current source into /Applications as the app you actually use.
#
# This is not a release. It is ad-hoc signed and carries the development
# unlock, so it is for the machine that built it and nowhere else. The signed,
# notarized path for other people is RELEASE.md.
#
# It backs the live store up first, moves any previous install aside instead of
# deleting it, and never touches build/EvoBar.app, which stays a build artifact
# for the test scripts to overwrite freely.
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

store_dir="$HOME/Library/Application Support/com.evobar.app"
installed="/Applications/EvoBar.app"
stamp="$(date +%Y%m%d-%H%M%S)"
keep_dir="${TMPDIR:-/tmp}/EvoBar-replaced"

echo "==> Build and smoke test"
./Scripts/build-app.sh >/dev/null
./Scripts/smoke-test-app.sh build/EvoBar.app

if [[ -f "$store_dir/EvoBar-v1.json" ]]; then
    cp "$store_dir/EvoBar-v1.json" "$store_dir/EvoBar-v1.json.before-install-$stamp"
    echo "==> Store backed up: EvoBar-v1.json.before-install-$stamp"
fi

echo "==> Install"
pkill -x EvoBar 2>/dev/null || true
sleep 2
if [[ -d "$installed" ]]; then
    mkdir -p "$keep_dir"
    mv "$installed" "$keep_dir/EvoBar-$stamp.app"
    echo "    previous install kept at $keep_dir/EvoBar-$stamp.app"
fi
ditto build/EvoBar.app "$installed"

open "$installed"
sleep 5
if pgrep -x EvoBar >/dev/null; then
    echo "==> Running from $installed"
else
    echo "==> EvoBar is not running; open it from /Applications"
    exit 1
fi

cat <<'NOTE'

If Launch at Login was on before this, turn it off and on once in
Settings, Companion. macOS remembers the bundle that registered it, which
was the old copy, and only the app itself can re-register the new one.
NOTE
