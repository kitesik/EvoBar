#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$project_dir/Sources/EvoBarApp/Resources/app-config.json"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/EvoBarStorefrontTests.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

valid_key="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
configured="$test_root/configured.json"
cp "$fixture" "$configured"
EVOBAR_CHECKOUT_URL="https://store.example.test/checkout" \
EVOBAR_LICENSE_PUBLIC_KEY_BASE64="$valid_key" \
EVOBAR_REQUIRE_PRODUCTION_STOREFRONT=1 \
    "$project_dir/Scripts/configure-storefront.sh" "$configured"

test "$(plutil -extract storefront raw -o - "$configured")" = "signed-license"
test "$(plutil -extract signedLicense.checkoutURL raw -o - "$configured")" = "https://store.example.test/checkout"
test "$(plutil -extract signedLicense.publicKeyBase64 raw -o - "$configured")" = "$valid_key"
for flag in unlockEverything unlockAllAnimals freeItems; do
    test "$(plutil -extract "$flag" raw -o - "$configured")" = "false"
done

if EVOBAR_REQUIRE_PRODUCTION_STOREFRONT=1 \
    "$project_dir/Scripts/configure-storefront.sh" "$fixture" >/dev/null 2>&1; then
    echo "Required production storefront unexpectedly accepted missing settings." >&2
    exit 1
fi
if EVOBAR_CHECKOUT_URL="http://store.example.test/checkout" \
    EVOBAR_LICENSE_PUBLIC_KEY_BASE64="$valid_key" \
    "$project_dir/Scripts/configure-storefront.sh" "$fixture" >/dev/null 2>&1; then
    echo "Storefront configuration unexpectedly accepted an HTTP checkout." >&2
    exit 1
fi
if EVOBAR_CHECKOUT_URL="https://store.example.test/checkout" \
    EVOBAR_LICENSE_PUBLIC_KEY_BASE64="c2hvcnQ=" \
    "$project_dir/Scripts/configure-storefront.sh" "$fixture" >/dev/null 2>&1; then
    echo "Storefront configuration unexpectedly accepted a short public key." >&2
    exit 1
fi

echo "Storefront configuration tests passed"
