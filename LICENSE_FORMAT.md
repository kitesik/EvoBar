# EvoBar signed license format

This document defines the vendor-neutral entitlement boundary for direct distribution. A payment adapter may use any checkout provider, but EvoBar activates paid animal lines only from a valid Ed25519-signed license envelope.

The signing private key belongs in the payment backend or a protected offline issuance system. It must never be embedded in the app, committed to Git, placed in GitHub Actions for ordinary CI, or included in release artifacts. The app contains only the public verification key.

## Envelope

The license file is UTF-8 JSON. Foundation encodes `Data` fields as Base64 strings:

```json
{
  "payload": "BASE64_OF_EXACT_PAYLOAD_BYTES",
  "signature": "BASE64_OF_ED25519_SIGNATURE"
}
```

The signature is calculated over the exact decoded `payload` bytes. The verifier does not re-encode or canonicalize the payload before checking the signature, so a backend may choose its JSON key order as long as it signs the exact bytes embedded in the envelope.

## Payload schema v1

Dates use RFC 3339 / ISO-8601 encoding.

```json
{
  "schemaVersion": 1,
  "licenseID": "opaque-nonempty-id",
  "appBundleID": "com.evobar.app",
  "productIDs": ["evobar.animal.fox"],
  "issuedAt": "2026-09-04T00:00:00Z",
  "expiresAt": null
}
```

- `licenseID`: opaque identifier; do not include an email address or other personal data.
- `appBundleID`: must be exactly `com.evobar.app`.
- `productIDs`: only IDs present in `storefront.v1.json` are accepted.
- `issuedAt`: may be at most five minutes in the future to tolerate clock skew.
- `expiresAt`: optional. Omit or use `null` for perpetual purchases; an expired license is rejected.

The verifier rejects malformed envelopes, invalid public keys or signatures, unknown schema versions, wrong applications, blank IDs, future issue dates, expired licenses, unknown products, envelopes over 1 MiB, and payloads over 64 KiB.

## Checkout adapter contract

`SignedLicensePurchaseService` implements `PurchaseService` without depending on a specific vendor:

1. It maps manifest products into storefront display products.
2. Purchase opens the configured HTTPS checkout with `product_id` and `source=evobar` query items.
3. The checkout returns pending until a signed license is imported or refreshed.
4. `importLicense` verifies before writing and emits `entitlementsChanged` only after a valid license is persisted.
5. Existing valid license data remains usable offline.

On every RELEASE launch, EvoBar reconstructs paid entitlements from the verified license. Cached `activeProductIDs` are cleared when signed licensing is not configured or when the local license is invalid, expired, or missing; the persistence JSON is never treated as purchase proof.

Before enabling it in RELEASE, add a provider adapter that obtains the signed envelope after checkout and restore, pin the production public key in app configuration, provide a user-visible import/restore path, and run the `PurchaseService` contract tests against the provider’s sandbox. Until then RELEASE continues to use `DisabledPurchaseService` and cannot grant paid entitlements.
