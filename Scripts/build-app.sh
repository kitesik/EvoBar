#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_dir/build"
app_dir="$build_dir/EvoBar.app"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"
marketing_version="${EVOBAR_MARKETING_VERSION:-0.1.0}"
build_version="${EVOBAR_BUILD_VERSION:-1}"
signing_identity="${EVOBAR_SIGNING_IDENTITY:--}"

if [[ ! "$marketing_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "EVOBAR_MARKETING_VERSION must be a semantic version" >&2
    exit 1
fi
if [[ ! "$build_version" =~ ^[1-9][0-9]*$ ]]; then
    echo "EVOBAR_BUILD_VERSION must be a positive integer" >&2
    exit 1
fi

cd "$project_dir"
swift build --scratch-path "$scratch_dir" -c release --arch arm64 --product EvoBar
swift build --scratch-path "$scratch_dir" -c release --arch x86_64 --product EvoBar

arm64_release="$scratch_dir/arm64-apple-macosx/release"
x86_release="$scratch_dir/x86_64-apple-macosx/release"
arm64_binary="$arm64_release/EvoBar"
x86_binary="$x86_release/EvoBar"

test -x "$arm64_binary"
test -x "$x86_binary"

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
lipo -create "$arm64_binary" "$x86_binary" -output "$app_dir/Contents/MacOS/EvoBar"
cp "$project_dir/Packaging/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Packaging/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
plutil -replace CFBundleShortVersionString -string "$marketing_version" "$app_dir/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$build_version" "$app_dir/Contents/Info.plist"

find "$arm64_release" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$app_dir/Contents/Resources/" \;

# SwiftPM keeps executable resources in a generated bundle. SwiftUI's implicit
# LocalizedStringKey lookup uses the app bundle, so mirror localizations there.
resource_bundle="$(find "$app_dir/Contents/Resources" -maxdepth 1 -type d -name 'EvoBar_EvoBarApp.bundle' -print -quit)"
if [[ -z "$resource_bundle" ]]; then
    echo "EvoBarApp resource bundle was not produced" >&2
    exit 1
fi
for locale in en ko ja es fr pt; do
    test -f "$resource_bundle/$locale.lproj/Localizable.strings"
    cp -R "$resource_bundle/$locale.lproj" "$app_dir/Contents/Resources/"
done

if [[ "$signing_identity" == "-" ]]; then
    codesign --force --deep --sign - "$app_dir"
else
    codesign \
        --force \
        --deep \
        --options runtime \
        --timestamp \
        --sign "$signing_identity" \
        "$app_dir"
fi
codesign --verify --deep --strict "$app_dir"
lipo -info "$app_dir/Contents/MacOS/EvoBar"
echo "$app_dir"
