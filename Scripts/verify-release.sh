#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_path="${1:-$project_dir/build/EvoBar.app}"
expected_version="${EVOBAR_EXPECTED_VERSION:-}"
require_notarization="${EVOBAR_REQUIRE_NOTARIZATION:-0}"

if [[ ! -d "$app_path" ]]; then
    echo "App bundle not found: $app_path" >&2
    exit 1
fi

plist="$app_path/Contents/Info.plist"
binary="$app_path/Contents/MacOS/EvoBar"
test -f "$plist"
test -x "$binary"
test -f "$app_path/Contents/Resources/AppIcon.icns"

bundle_id="$(plutil -extract CFBundleIdentifier raw -o - "$plist")"
icon_file="$(plutil -extract CFBundleIconFile raw -o - "$plist")"
minimum_macos="$(plutil -extract LSMinimumSystemVersion raw -o - "$plist")"
is_agent="$(plutil -extract LSUIElement raw -o - "$plist")"
version="$(plutil -extract CFBundleShortVersionString raw -o - "$plist")"
build="$(plutil -extract CFBundleVersion raw -o - "$plist")"

test "$bundle_id" = "com.evobar.app"
test "$icon_file" = "AppIcon"
test "$minimum_macos" = "14.0"
test "$is_agent" = "true"
[[ "$build" =~ ^[1-9][0-9]*$ ]]
if [[ -n "$expected_version" ]]; then
    test "$version" = "$expected_version"
fi

architectures="$(lipo -archs "$binary")"
[[ " $architectures " == *" arm64 "* ]]
[[ " $architectures " == *" x86_64 "* ]]

for locale in en ko ja es fr pt; do
    strings_file="$app_path/Contents/Resources/$locale.lproj/Localizable.strings"
    test -f "$strings_file"
    plutil -lint "$strings_file" >/dev/null
done

core_resource_bundle="$(find "$app_path/Contents/Resources" -maxdepth 1 -type d -name 'EvoBar_EvoBarCore.bundle' -print -quit)"
test -n "$core_resource_bundle"
for animal in cat dog fox capybara; do
    for stage in 1 2 3 4 5; do
        for state in idle working evolutionReady sleeping; do
            sprite="$(find "$core_resource_bundle" -type f -name "$animal.$stage.$state.png" -print -quit)"
            test -n "$sprite"
            test -s "$sprite"
        done
    done
done

codesign --verify --deep --strict --verbose=2 "$app_path"
if [[ "$require_notarization" == "1" ]]; then
    xcrun stapler validate "$app_path"
    spctl --assess --type execute --verbose=2 "$app_path"
fi

echo "Verified EvoBar $version ($build): Universal 2, six locales, companion sprite states, valid signature"
