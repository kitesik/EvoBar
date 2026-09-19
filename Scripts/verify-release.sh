#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_path="${1:-$project_dir/build/EvoBar.app}"
expected_version="${EVOBAR_EXPECTED_VERSION:-}"
require_notarization="${EVOBAR_REQUIRE_NOTARIZATION:-0}"
require_production_storefront="${EVOBAR_REQUIRE_PRODUCTION_STOREFRONT:-0}"

if [[ "$require_production_storefront" != "0" && "$require_production_storefront" != "1" ]]; then
    echo "EVOBAR_REQUIRE_PRODUCTION_STOREFRONT must be 0 or 1." >&2
    exit 1
fi

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
app_resource_bundle="$(find "$app_path/Contents/Resources" -maxdepth 1 -type d -name 'EvoBar_EvoBarApp.bundle' -print -quit)"
test -n "$app_resource_bundle"
app_config="$app_resource_bundle/app-config.json"
test -f "$app_config"
test "$(plutil -extract schemaVersion raw -o - "$app_config")" = "1"
test "$(plutil -extract distribution raw -o - "$app_config")" = "direct"
storefront="$(plutil -extract storefront raw -o - "$app_config")"
if [[ "$require_production_storefront" == "1" ]]; then
    test "$storefront" = "signed-license"
fi
if [[ "$storefront" == "signed-license" ]]; then
    checkout_url="$(plutil -extract signedLicense.checkoutURL raw -o - "$app_config")"
    public_key_base64="$(plutil -extract signedLicense.publicKeyBase64 raw -o - "$app_config")"
    [[ "$checkout_url" =~ ^https://[^[:space:]]+$ ]]
    decoded_key="$(mktemp "${TMPDIR:-/tmp}/EvoBarVerifyPublicKey.XXXXXX")"
    trap 'rm -f "$decoded_key"' EXIT
    printf '%s' "$public_key_base64" | base64 --decode >"$decoded_key"
    test "$(wc -c <"$decoded_key" | tr -d '[:space:]')" = "32"
elif [[ "$storefront" != "mock-debug" ]]; then
    echo "Unsupported storefront configuration: $storefront" >&2
    exit 1
fi
# Every normal form in the current catalog must ship in all four states.
# Atlas V2 has no emoji-only lines or recoloured placeholder stages.
catalog="$(find "$core_resource_bundle" -type f -name animals.v1.json -print -quit)"
test -s "$catalog"
sprite_ids="$(python3 - "$catalog" <<'PY'
import json, sys
catalog = json.load(open(sys.argv[1]))
seen = []
for animal in catalog["animals"]:
    for stage in animal["stages"]:
        assert not stage.get("artworkPending", False), "Pending artwork in packaged catalog"
        if stage["normalAssetID"] not in seen:
            seen.append(stage["normalAssetID"])
print("\n".join(seen))
PY
)"
test "$(printf '%s\n' "$sprite_ids" | wc -l | tr -d '[:space:]')" = "72"
shiny_ids="$(python3 - "$catalog" <<'PY'
import json, sys
catalog = json.load(open(sys.argv[1]))
print("\n".join(stage["shinyAssetID"] for animal in catalog["animals"]
                if animal.get("hasShinyArtwork", False) for stage in animal["stages"]))
PY
)"
for sprite_id in $sprite_ids $shiny_ids; do
    for state in idle working evolutionReady sleeping; do
        sprite="$(find "$core_resource_bundle" -type f -name "$sprite_id.$state.png" -print -quit)"
        test -n "$sprite"
        test -s "$sprite"
    done
done

# Non-quadruped lines must contain their own four-frame cycle for BOTH colours.
# Walking lines intentionally use the existing procedural leg rig; 144 authored
# strips are not a shipping claim. Decode/alpha checks live in the unit suite.
python3 - "$catalog" "$core_resource_bundle" <<'PY'
import json, pathlib, struct, sys
catalog = json.load(open(sys.argv[1]))
root = pathlib.Path(sys.argv[2])
assert all(a.get("hasShinyArtwork", False) for a in catalog["animals"]), "Missing alternate line"
motion_ids = [s[key] for a in catalog["animals"] if a.get("locomotion", "walk") != "walk"
              for s in a["stages"] for key in ("normalAssetID", "shinyAssetID")]
assert len(motion_ids) == 60, "Unexpected motion inventory"
for asset_id in motion_ids:
    files = list(root.rglob(asset_id + ".motion.png"))
    assert len(files) == 1, "Missing/ambiguous motion strip: " + asset_id
    with files[0].open("rb") as source:
        header = source.read(24)
    assert header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR", "Invalid PNG: " + asset_id
    width, height = struct.unpack(">II", header[16:24])
    assert 64 <= height <= 256 and width == 4 * height, "Invalid frame geometry: " + asset_id
print("Verified 72 normal + 72 alternate forms and 60 authored motion strips")
PY

codesign --verify --deep --strict --verbose=2 "$app_path"
if [[ "$require_notarization" == "1" ]]; then
    xcrun stapler validate "$app_path"
    spctl --assess --type execute --verbose=2 "$app_path"
fi

echo "Verified EvoBar $version ($build): Universal 2, six locales, companion sprite states, valid signature"
