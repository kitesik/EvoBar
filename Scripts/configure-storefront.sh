#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 APP_CONFIG_JSON" >&2
    exit 2
fi

config_path="$1"
checkout_url="${EVOBAR_CHECKOUT_URL:-}"
public_key_base64="${EVOBAR_LICENSE_PUBLIC_KEY_BASE64:-}"
require_production="${EVOBAR_REQUIRE_PRODUCTION_STOREFRONT:-0}"

if [[ ! -f "$config_path" ]]; then
    echo "App storefront configuration not found: $config_path" >&2
    exit 1
fi
if [[ "$require_production" != "0" && "$require_production" != "1" ]]; then
    echo "EVOBAR_REQUIRE_PRODUCTION_STOREFRONT must be 0 or 1." >&2
    exit 1
fi
if [[ -z "$checkout_url" && -z "$public_key_base64" ]]; then
    if [[ "$require_production" == "1" ]]; then
        echo "Production storefront configuration is required for this build." >&2
        exit 1
    fi
    exit 0
fi
if [[ -z "$checkout_url" || -z "$public_key_base64" ]]; then
    echo "EVOBAR_CHECKOUT_URL and EVOBAR_LICENSE_PUBLIC_KEY_BASE64 must be set together." >&2
    exit 1
fi
if [[ ! "$checkout_url" =~ ^https://[^[:space:]]+$ ]]; then
    echo "EVOBAR_CHECKOUT_URL must be an absolute HTTPS URL without whitespace." >&2
    exit 1
fi

decoded_key="$(mktemp "${TMPDIR:-/tmp}/EvoBarPublicKey.XXXXXX")"
trap 'rm -f "$decoded_key"' EXIT
if ! printf '%s' "$public_key_base64" | base64 --decode >"$decoded_key" 2>/dev/null; then
    echo "EVOBAR_LICENSE_PUBLIC_KEY_BASE64 is not valid Base64." >&2
    exit 1
fi
key_size="$(wc -c <"$decoded_key" | tr -d '[:space:]')"
if [[ "$key_size" != "32" ]]; then
    echo "EVOBAR_LICENSE_PUBLIC_KEY_BASE64 must decode to a 32-byte Ed25519 public key." >&2
    exit 1
fi

plutil -replace storefront -string "signed-license" "$config_path"
plutil -replace signedLicense -dictionary "$config_path"
plutil -insert signedLicense.checkoutURL -string "$checkout_url" "$config_path"
plutil -insert signedLicense.publicKeyBase64 -string "$public_key_base64" "$config_path"
test "$(plutil -extract storefront raw -o - "$config_path")" = "signed-license"
test "$(plutil -extract signedLicense.checkoutURL raw -o - "$config_path")" = "$checkout_url"
test "$(plutil -extract signedLicense.publicKeyBase64 raw -o - "$config_path")" = "$public_key_base64"
