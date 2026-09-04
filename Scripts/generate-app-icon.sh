#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_png="$project_dir/Packaging/AppIconSource.png"
output_icns="$project_dir/Packaging/AppIcon.icns"
temp_dir="$(mktemp -d)"
iconset_dir="$temp_dir/AppIcon.iconset"
mkdir -p "$iconset_dir"

cleanup() {
    find "$temp_dir" -depth -delete
}
trap cleanup EXIT

test -f "$source_png"

render() {
    local pixels="$1"
    local filename="$2"
    sips -z "$pixels" "$pixels" "$source_png" --out "$iconset_dir/$filename" >/dev/null
}

render 16 icon_16x16.png
render 32 icon_16x16@2x.png
render 32 icon_32x32.png
render 64 icon_32x32@2x.png
render 128 icon_128x128.png
render 256 icon_128x128@2x.png
render 256 icon_256x256.png
render 512 icon_256x256@2x.png
render 512 icon_512x512.png
render 1024 icon_512x512@2x.png

iconutil -c icns "$iconset_dir" -o "$output_icns"
test -s "$output_icns"
echo "$output_icns"
