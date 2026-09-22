# EvoBar release runbook

This runbook covers direct distribution outside the Mac App Store. Release archives must be Developer ID signed, notarized, stapled, and published without credentials in the repository.

## The version

`VERSION` at the repository root is the only place the marketing version is
written. `build-app.sh`, `package-release.sh` and `verify-local.sh` all read it,
and the build refuses to finish if the bundle ends up stamped with anything
else. Bump that file in the same commit as the change you are releasing, and tag
`v<the same number>`: a tag whose number is ahead of the bundle tells everyone
who installs it that an update is available, forever.

## Turning release automation on

`.github/workflows/release.yml` runs only when the repository variable
`EVOBAR_RELEASE_ENABLED` is `1`. Set it in the same sitting as the signing
secrets and repository variables listed below, never before: with the variable
set and a secret missing, the workflow fails on purpose and says which one.
Without the variable a tag skips the job, which is what an unsigned preview
release should do.

## One-time account setup

1. Enroll the publisher in the Apple Developer Program.
2. Install a `Developer ID Application` certificate and private key in the login keychain.
3. Store notarization credentials locally. Example:

   ```bash
   xcrun notarytool store-credentials EvoBarNotary \
     --apple-id "APPLE_ID" \
     --team-id "TEAM_ID" \
     --password "APP_SPECIFIC_PASSWORD"
   ```

4. Create the external payment-provider account and production product identifiers. Do not enable purchases until the production adapter passes the same contract tests as `MockPurchaseService`.
5. Make the GitHub repository public before relying on public Releases, in-app update checks, or Homebrew installation.

The certificate, private key, Apple ID, app-specific password, notary profile contents, payment keys, and provider credentials must never be committed.

### GitHub release environment

Create a protected GitHub Actions environment named `release` and require a reviewer. Add these environment secrets:

- `APPLE_DEVELOPER_ID_P12_BASE64`: Base64 of the exported Developer ID Application certificate and private key (`.p12`).
- `APPLE_DEVELOPER_ID_P12_PASSWORD`: Export password for that `.p12` file.
- `APPLE_DEVELOPER_IDENTITY`: Exact identity printed by `security find-identity -v -p codesigning`.
- `APPLE_NOTARY_KEY_ID`: App Store Connect API key ID.
- `APPLE_NOTARY_ISSUER_ID`: App Store Connect API issuer ID.
- `APPLE_NOTARY_PRIVATE_KEY_BASE64`: Base64 of the matching `AuthKey_*.p8` file.

Add these non-secret environment variables:

- `EVOBAR_CHECKOUT_URL`: Absolute HTTPS URL for the production checkout endpoint.
- `EVOBAR_LICENSE_PUBLIC_KEY_BASE64`: Base64 of the 32-byte Ed25519 public verification key. The matching private key stays only in the license issuer.

Generate single-line secret values locally with `base64 -i FILE | pbcopy`. Never paste the signing certificate, private key, passwords, or API key into an issue, workflow file, build log, or repository variable. The workflow imports them into an ephemeral keychain and deletes it at the end.

## Build a release candidate

List the installed signing identity:

```bash
security find-identity -v -p codesigning
```

Create, sign, notarize, staple, verify, checksum, and generate the Homebrew Cask:

```bash
EVOBAR_SIGNING_IDENTITY="Developer ID Application: Publisher (TEAMID)" \
EVOBAR_NOTARY_PROFILE="EvoBarNotary" \
EVOBAR_CHECKOUT_URL="https://store.example.com/checkout" \
EVOBAR_LICENSE_PUBLIC_KEY_BASE64="BASE64_32_BYTE_PUBLIC_KEY" \
EVOBAR_REQUIRE_PRODUCTION_STOREFRONT="1" \
EVOBAR_BUILD_VERSION="1" \
./Scripts/package-release.sh 0.1.0
```

Outputs:

- `build/release/EvoBar-0.1.0-macos-universal.zip`
- `build/release/EvoBar-0.1.0-macos-universal.zip.sha256`
- `build/release/EvoBar.rb`

`package-release.sh` refuses unsigned output unless `EVOBAR_ALLOW_UNSIGNED=1` is explicitly set for CI validation. It also refuses to skip notarization unless `EVOBAR_SKIP_NOTARIZATION=1` is explicit.

## Release verification

Before publishing:

```bash
EVOBAR_EXPECTED_VERSION="0.1.0" \
EVOBAR_REQUIRE_NOTARIZATION="1" \
EVOBAR_REQUIRE_PRODUCTION_STOREFRONT="1" \
./Scripts/verify-release.sh build/EvoBar.app

./Scripts/smoke-test-app.sh build/EvoBar.app

(cd build/release && shasum -a 256 -c EvoBar-0.1.0-macos-universal.zip.sha256)
```

Then test the archive on a clean macOS 14+ account with no development tools installed:

- Download and unzip the GitHub Release asset.
- Move EvoBar to `/Applications` and launch it from Finder.
- Confirm Gatekeeper shows the identified developer without an override flow.
- Complete onboarding with neither provider installed, Claude only, Codex only, and both providers.
- Confirm login launch after a reboot.
- Confirm English, Korean, Japanese, Spanish, French, and Portuguese layouts.
- Confirm reset and aggregate export do not expose prompts, responses, code, paths, session IDs, or raw events.
- Confirm RELEASE purchases remain unavailable until a production adapter is configured.

## Publish

1. Tag the exact tested commit as `v0.1.0` and push that tag.
2. `.github/workflows/release.yml` reruns tests, imports credentials into an ephemeral keychain, signs, notarizes, staples, verifies, and creates a **draft** GitHub Release with the ZIP, checksum, Cask, and privacy policy. Missing secrets, malformed tags, notarization failure, or an existing Release fail closed.
3. Download the draft asset on a clean Mac, perform the manual verification above, and confirm its SHA-256.
4. Publish the existing draft without replacing its assets. Never rerun or overwrite a version that has been published.
5. Submit the generated `EvoBar.rb` to the Homebrew tap only after the public asset URL is stable.
6. Confirm EvoBar’s in-app update checker detects the public non-draft release.

Rollback by marking the release as a draft or deleting the release asset, then publishing a fixed build with a higher version and build number. Never replace a published binary under the same version.
