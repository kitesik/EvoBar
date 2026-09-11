#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"
output_dir="$project_dir/build/ui-review"
review_root="$(mktemp -d "${TMPDIR:-/tmp}/EvoBarUIReview.XXXXXX")"
review_app="$review_root/EvoBarReview.app"
app_pid=""

cleanup() {
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    # This path was created by mktemp, never supplied by the caller.
    rm -rf "$review_root"
}
trap cleanup EXIT

cd "$project_dir"
swift build --scratch-path "$scratch_dir" --product EvoBar
debug_dir="$(swift build --scratch-path "$scratch_dir" --show-bin-path)"
mkdir -p "$review_app/Contents/MacOS" "$review_app/Contents/Resources"
cp "$debug_dir/EvoBar" "$review_app/Contents/MacOS/EvoBar"
cp "$project_dir/Packaging/Info.plist" "$review_app/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.evobar.ui-review "$review_app/Contents/Info.plist"
find "$debug_dir" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$review_app/Contents/Resources/" \;
for locale in en ko ja es fr pt; do
    cp -R "$debug_dir/EvoBar_EvoBarApp.bundle/$locale.lproj" "$review_app/Contents/Resources/"
done
codesign --force --deep --sign - "$review_app"

if [[ "$#" -eq 0 ]]; then set -- en ko; fi
for locale in "$@"; do
    case "$locale" in en|ko|ja|es|fr|pt) ;; *) echo "Unsupported review language: $locale" >&2; exit 1 ;; esac
    mkdir -p "$output_dir/$locale" "$review_root/$locale"
    report="$review_root/$locale/report.json"
    EVOBAR_SMOKE_TEST_OUTPUT="$report" \
    EVOBAR_VISUAL_REVIEW_DIRECTORY="$output_dir/$locale" \
        "$review_app/Contents/MacOS/EvoBar" -AppleLanguages "($locale)" -AppleLocale "$locale" \
        >"$review_root/$locale/app.log" 2>&1 &
    app_pid="$!"
    for _ in {1..600}; do
        if ! kill -0 "$app_pid" 2>/dev/null; then break; fi
        sleep 0.1
    done
    if kill -0 "$app_pid" 2>/dev/null; then
        echo "UI rendering timed out ($locale)." >&2
        exit 1
    fi
    wait "$app_pid"
    app_pid=""
    if [[ ! -f "$report" ]] || [[ "$(plutil -extract status raw -o - "$report")" != ready ]]; then
        echo "UI rendering failed ($locale)." >&2
        sed -n '1,100p' "$review_root/$locale/app.log" >&2
        exit 1
    fi
    for theme in dark; do
        for screen in home usage collection shop settings settings-companion settings-tracking settings-data shop-items collection-detail onboarding-0 onboarding-1 onboarding-2 empty ready-long-name shop-feedback shop-items-feedback compact-home compact-usage compact-collection compact-shop compact-settings compact-detail compact-graduation compact-privacy startup-failure settings-feedback compact-settings-feedback field-guide shiny-home shiny-collection; do
            image_path="$output_dir/$locale/$screen-$theme.png"
            test -s "$image_path"
            # Decode the generated image instead of accepting an empty/corrupt file.
            sips -g pixelWidth -g pixelHeight "$image_path" >/dev/null
        done
    done
    echo "Rendered 31 isolated SwiftUI review screens ($locale)."
done
echo "$output_dir"
