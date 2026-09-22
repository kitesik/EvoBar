#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
release_dir="$project_dir/build/release"
version="${1:-${EVOBAR_MARKETING_VERSION:-$(cat "$project_dir/VERSION")}}"
build_version="${EVOBAR_BUILD_VERSION:-1}"
signing_identity="${EVOBAR_SIGNING_IDENTITY:-}"
notary_profile="${EVOBAR_NOTARY_PROFILE:-}"
notary_keychain="${EVOBAR_NOTARY_KEYCHAIN:-}"
allow_unsigned="${EVOBAR_ALLOW_UNSIGNED:-0}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Version must be semantic, for example 0.1.0" >&2
    exit 1
fi

if [[ -z "$signing_identity" && "$allow_unsigned" != "1" ]]; then
    echo "Set EVOBAR_SIGNING_IDENTITY to a Developer ID Application identity." >&2
    echo "For CI-only packaging, explicitly set EVOBAR_ALLOW_UNSIGNED=1." >&2
    exit 1
fi
if [[ -n "$signing_identity" && -z "$notary_profile" && "${EVOBAR_SKIP_NOTARIZATION:-0}" != "1" ]]; then
    echo "Set EVOBAR_NOTARY_PROFILE or explicitly set EVOBAR_SKIP_NOTARIZATION=1." >&2
    exit 1
fi

mkdir -p "$release_dir"
archive="$release_dir/EvoBar-$version-macos-universal.zip"
checksum="$archive.sha256"
notary_archive="$release_dir/.EvoBar-$version-notary.zip"
rm -f "$archive" "$checksum" "$notary_archive"

EVOBAR_MARKETING_VERSION="$version" \
EVOBAR_BUILD_VERSION="$build_version" \
EVOBAR_SIGNING_IDENTITY="${signing_identity:--}" \
    "$project_dir/Scripts/build-app.sh"

app_path="$project_dir/build/EvoBar.app"
EVOBAR_EXPECTED_VERSION="$version" "$project_dir/Scripts/verify-release.sh" "$app_path"

if [[ -n "$notary_profile" ]]; then
    ditto -c -k --sequesterRsrc --keepParent "$app_path" "$notary_archive"
    notary_arguments=(--keychain-profile "$notary_profile")
    if [[ -n "$notary_keychain" ]]; then
        notary_arguments+=(--keychain "$notary_keychain")
    fi
    xcrun notarytool submit "$notary_archive" "${notary_arguments[@]}" --wait
    xcrun stapler staple "$app_path"
    EVOBAR_EXPECTED_VERSION="$version" EVOBAR_REQUIRE_NOTARIZATION=1 \
        "$project_dir/Scripts/verify-release.sh" "$app_path"
    rm -f "$notary_archive"
fi

ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive"
unzip -tq "$archive"
(
    cd "$release_dir"
    shasum -a 256 "$(basename "$archive")" > "$(basename "$checksum")"
    shasum -a 256 -c "$(basename "$checksum")"
)

EVOBAR_RELEASE_VERSION="$version" "$project_dir/Scripts/render-homebrew-cask.sh" "$archive"

echo "$archive"
echo "$checksum"
echo "$release_dir/EvoBar.rb"
