# EvoBar

[![CI](https://github.com/kitesik/EvoBar/actions/workflows/ci.yml/badge.svg)](https://github.com/kitesik/EvoBar/actions/workflows/ci.yml)

EvoBar is a local-first macOS companion that grows as you work with AI coding tools. It combines a serious usage monitor with original animal companions, persistent individual histories, collection progression, and separate cash and token-coin storefronts.

Status: executable foundation. The repository builds a working menu-bar app with first-run onboarding, provider detection, Cat/Dog starter selection, persistent animal instances, manual evolution and graduation, owned-line selection or random hatching, incremental Claude Code/Codex usage tracking, today/rolling-five-hour/week/month dashboards, provider/model breakdowns, API-equivalent cost estimates with coverage, quota UI and forecasts, deduplicated aggregates, diminishing-return XP and token coins, Collection, and a functional debug-only Mock Storefront.

## Requirements

- macOS 14+
- Swift 6 toolchain
- Full Xcode is required for signing, archiving, and notarization

The current command-line toolchain does not include SwiftData's compiler plugin. Persistence therefore uses a schema-v10, atomic JSON store behind `EvoBarStore`; the app-facing repository boundary is intentionally kept replaceable by a SwiftData adapter once the project is opened with full Xcode.

## Build and test

```bash
./Scripts/check.sh
./Scripts/build-app.sh
```

Both scripts keep the large, reproducible SwiftPM scratch directory in `~/Library/Caches/EvoBar/SwiftPM` instead of syncing it through Google Drive. Set `EVOBAR_SWIFTPM_SCRATCH` to override that location. The bundle script creates `build/EvoBar.app`; Developer ID signing and notarization are intentionally separate release steps.

To smoke-test the locally bundled app:

```bash
open build/EvoBar.app
```

The local bundle is ad-hoc signed and the build script produces a Universal 2 executable for Apple Silicon and Intel Macs. A public release still requires a Developer ID Application certificate, hardened runtime signing, notarization, and stapling.

The production release pipeline is documented in [RELEASE.md](RELEASE.md). With a local Developer ID identity and `notarytool` keychain profile, one command creates the signed/notarized/stapled ZIP, SHA-256 file, and rendered Homebrew Cask:

```bash
EVOBAR_SIGNING_IDENTITY="Developer ID Application: Publisher (TEAMID)" \
EVOBAR_NOTARY_PROFILE="EvoBarNotary" \
EVOBAR_BUILD_VERSION="1" \
./Scripts/package-release.sh 0.1.0
```

CI runs the same packaging and verification path with an explicitly unsigned candidate; unsigned output cannot be mistaken for a public release because `package-release.sh` refuses it by default.

Pushing a semantic version tag such as `v0.1.0` runs the protected release workflow. Once its Apple signing/notarization environment secrets are configured, the workflow tests the tagged source, produces a Developer ID signed and notarized Universal 2 archive, and creates a draft GitHub Release for clean-Mac acceptance testing. See [RELEASE.md](RELEASE.md); release credentials never belong in the repository.

The original EvoBar application icon, its reproducible `.icns` generator, and provenance are documented in [ARTWORK.md](ARTWORK.md). No third-party character or game artwork is used.

Direct-distribution purchases have a vendor-neutral [signed license format](LICENSE_FORMAT.md). The app verifies Ed25519 signatures, bundle ID, issue/expiry dates, and manifest product IDs before persisting an entitlement. RELEASE remains disabled until a payment provider and production public key are configured; no private signing key belongs in the app or repository.

## Privacy boundary

EvoBar extracts only usage metadata needed for aggregation: provider, session identifier, timestamp, model identifier, and token counts. It does not retain or log raw JSONL lines, prompts, responses, code, project paths, or unknown JSON fields.

Exported data is narrower still: animal histories, daily aggregate totals, coin balance, and non-secret app preferences. It excludes individual usage events, session identifiers, source fingerprints, file paths, and scan checkpoints. Credentials explicitly supplied to a future supported quota adapter are isolated behind `CredentialStore` and the macOS Keychain implementation; EvoBar does not import Claude Code or Codex login sessions.

The local Application Support directory is owner-only (`0700`), and the state and signed-license files are owner-readable/writable only (`0600`). Existing state-file permissions are repaired when the store opens.

See [SPEC.md](SPEC.md) and [PRIVACY.md](PRIVACY.md).

## Implemented and next

Implemented now: original 10-line animal manifest, Welcome/provider discovery/starter onboarding, versioned AnimalInstance persistence through schema v10, stepwise evolution, atomic graduation/next-companion transition, per-animal daily XP and usage attribution, owned-line random hatching, functional Token Coin Rare Candy/Mint/Shiny Charm/Random Egg transactions, confirmed local-data reset, privacy-filtered aggregate export, an in-app privacy disclosure, purchase abstraction and debug Mock Storefront outcomes, cached offline entitlements, Claude/Codex tolerant parsers, append checkpoints, rotation handling, stable-event deduplication, rolling/calendar usage windows, provider and model aggregation, provider-specific `*`/`**` additional log paths with unsafe-root protection, local recovery, menu-bar token/cost/quota status, quota cards/reset countdown/burn-rate forecast, opt-out official Claude/OpenAI service-status banners with five-minute throttling and stale-cache handling, opt-in evolution-ready and quota notifications, GitHub Release update checks with strict semantic-version comparison, persisted provider and refresh controls, launch at login, a movable 48–192 px desktop pet with hover usage/right-click actions/pinning/quota bubbles, `AnimalAssetProviding` sprite boundary, system-language UI resources for English, Korean, Japanese, Spanish, French, and Portuguese with English fallback, menu-bar popover, Universal 2 packaging, and app bundling. Release builds deliberately use `DisabledPurchaseService` until a real payment adapter is configured.

OpenAI documents five-hour shared local/cloud usage and possible weekly limits for Codex, but does not document a personal-account quota retrieval API. Its separately documented organization Usage API requires an Admin Key and measures API organization activity rather than a personal ChatGPT Codex allowance. For that reason DEBUG builds use clearly labelled deterministic quota demo data, while RELEASE builds show an unavailable state through `UnavailableQuotaService`. The adapter boundary and Keychain vault are ready, but the app will not reuse `~/.codex/auth.json`, another app's keychain entry, or an undocumented endpoint. See the [official Codex pricing documentation](https://developers.openai.com/codex/pricing), [Codex authentication documentation](https://developers.openai.com/codex/auth), and [OpenAI Usage API reference](https://platform.openai.com/docs/api-reference/usage).

The bundled price manifest is dated 2026-09-03 and links every rate set to its source. OpenAI prices come from the [official ChatGPT Rate Card](https://help.openai.com/en/articles/20001415-chatgpt-rate-card-enterprise-token-based-pricing); Claude prices come from the [official Claude pricing documentation](https://platform.claude.com/docs/en/about-claude/pricing). Unknown models and token categories remain unpriced and lower the displayed coverage instead of receiving a guessed rate. Estimates are not an invoice and exclude plan allowances, taxes, discounts, long-context premiums, fast mode, regional processing, and other feature charges.

The update checker intentionally uses no embedded GitHub credential. While this repository remains private, checks return a safe “no public release” state; they become live automatically after the repository and a non-draft Release are public.

Localization catalogs are parity-tested for matching keys and format placeholders, and the packaging script verifies that all six `.lproj` resources are present in the installable app bundle.

Next product milestones: supported quota adapters if providers publish suitable APIs, additional providers, production art, a real purchase adapter, and running the prepared notarized/Homebrew release path with publisher credentials.
