#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"
locale="${1:-en}"
case "$locale" in en|ko|ja|es|fr|pt) ;; *) echo "Unsupported review language: $locale" >&2; exit 1 ;; esac
screen="${2:-collection}"
case "$screen" in collection|motion|motion-flight|motion-biped|lifecycle|hatch-adopt|onboarding|graduation|compact-hatch-error|compact-placement-error) ;; *) echo "Unsupported review screen: $screen" >&2; exit 1 ;; esac
review_seconds="${EVOBAR_REVIEW_SECONDS:-900}"
if [[ ! "$review_seconds" =~ ^[0-9]+$ ]] || (( review_seconds < 10 || review_seconds > 3600 )); then
    echo "EVOBAR_REVIEW_SECONDS must be between 10 and 3600." >&2
    exit 1
fi
review_root="$(mktemp -d "${TMPDIR:-/tmp}/EvoBarInteractive.XXXXXX")"
review_app="$review_root/EvoBar UI Review.app"
app_pid=""
cleanup() {
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    # Only this script's mktemp directory, never a caller-supplied app or store.
    rm -rf "$review_root"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cd "$project_dir"
swift build --scratch-path "$scratch_dir" --product EvoBar
debug_dir="$(swift build --scratch-path "$scratch_dir" --show-bin-path)"
mkdir -p "$review_app/Contents/MacOS" "$review_app/Contents/Resources"
cp "$debug_dir/EvoBar" "$review_app/Contents/MacOS/EvoBar"
cp "$project_dir/Packaging/Info.plist" "$review_app/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.evobar.interactive-review "$review_app/Contents/Info.plist"
plutil -replace CFBundleName -string 'EvoBar UI Review' "$review_app/Contents/Info.plist"
find "$debug_dir" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$review_app/Contents/Resources/" \;
for language in en ko ja es fr pt; do
    cp -R "$debug_dir/EvoBar_EvoBarApp.bundle/$language.lproj" "$review_app/Contents/Resources/"
done
codesign --force --deep --sign - "$review_app"
report="$review_root/report.json"
EVOBAR_SMOKE_TEST_OUTPUT="$report" EVOBAR_INTERACTIVE_REVIEW=1 EVOBAR_INTERACTIVE_REVIEW_SCREEN="$screen" \
    "$review_app/Contents/MacOS/EvoBar" -AppleLanguages "($locale)" -AppleLocale "$locale" \
    >"$review_root/app.log" 2>&1 &
app_pid="$!"
for _ in {1..150}; do
    if [[ -f "$report" ]] || ! kill -0 "$app_pid" 2>/dev/null; then break; fi
    sleep 0.1
done
if [[ ! -f "$report" ]] || [[ "$(plutil -extract status raw -o - "$report")" != ready ]]; then
    echo "Interactive fixture startup failed." >&2
    sed -n '1,80p' "$review_root/app.log" >&2
    exit 1
fi
echo "Fixture-only UI review is ready: $review_app"
echo "Close its window or quit to finish. Automatic cleanup after $review_seconds seconds."
deadline=$((SECONDS + review_seconds))
while kill -0 "$app_pid" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
        echo "Interactive review timed out; closing only the fixture app."
        exit 0
    fi
    sleep 1
done
wait "$app_pid"
app_pid=""
echo "Interactive fixture app closed; temporary app and data cleaned up."
