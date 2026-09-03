#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_dir/build"
app_dir="$build_dir/EvoBar.app"
cache_base="${XDG_CACHE_HOME:-${HOME}/Library/Caches}"
scratch_dir="${EVOBAR_SWIFTPM_SCRATCH:-$cache_base/EvoBar/SwiftPM}"

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

find "$arm64_release" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$app_dir/Contents/Resources/" \;

codesign --force --deep --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"
lipo -info "$app_dir/Contents/MacOS/EvoBar"
echo "$app_dir"
