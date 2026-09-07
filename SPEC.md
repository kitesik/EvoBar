# EvoBar Product Specification

This specification records the implementation scope as of 2026-09-02.

## Product promise

“The time I spend working with AI remains as the growth of my animal companion.”

## Product layers

1. Usage Monitor: local usage, model breakdown, cost estimates, official quota and forecasts.
2. Companion and Collection: named original animals, five evolution stages, graduation, random hatching, rarity, nature, and shiny variants.
3. Storefronts: cash entitlements for animal lines and non-purchasable Token Coins for gameplay items.

## Providers

The architecture targets Claude Code, Codex, Gemini CLI, Antigravity, OpenCode, Hermes Agent, Cursor, Grok CLI, Copilot CLI, Kiro CLI, Pi Agent, and omp. The first implementation slice ships Claude Code and Codex parsers.

Each provider adapter owns discovery, tolerant parsing, stable event identity, incremental checkpoints, quota retrieval, health, price metadata, and optional user-defined wildcard paths. Provider credentials or session keys are read from Keychain only when an official quota adapter requires them; they are never placed in the usage database or logs.

## Usage monitor target

- Time windows: today, rolling five-hour block, week, and month.
- Official quota: five-hour and weekly windows for Claude, Codex, and Antigravity where supported.
- Forecasts: reset countdown, current burn rate, and projected quota exhaustion time with explicit freshness.
- Cost: model-aware API-equivalent estimate clearly labelled as an estimate, never presented as the user's actual bill.
- Surfaces: optional token, estimated cost, or quota percentage in the menu bar; provider tabs and model breakdown in the popover.
- Reliability: provider outage/stale-data banners, manual refresh, and a configurable 1–15 minute refresh interval.
- Live refresh: provider log roots are watched with FSEvents so appended usage appears within seconds; the interval remains as a fallback.
- Usage bands: three user-adjustable daily raw-token thresholds (default 1M, 5M, 20M) drive a heat treatment on the Today tile. No band name is displayed.
- Day rank: today's raw tokens ranked against the last 30 recorded days.
- First scan backfills the current growth day; earlier history is baselined and not counted.
- Discovery: provider defaults plus user-added wildcard log paths; permission and empty states remain provider-specific.

Raw events retain only stable event ID, provider, session ID, timestamp, model ID, token counts, and a one-way source fingerprint. Prompt, response, code, raw JSON lines, project names, and file paths are neither stored nor logged.

## Growth

Daily raw tokens are transformed with diminishing returns: 100% through 1M, 50% from 1M–5M, 20% from 5M–20M, and 5% above 20M. XP is `floor(effectiveTokens / 10,000)`. Daily target XP is recomputed and only the positive difference from already-awarded XP is credited. Credited XP lands in the companion's bowl as food; the XP bar moves only when the user feeds, and Rare Candy takes the same path.

## Collection loop

The first companion is a directly selected Cat or Dog. At final evolution, the user may graduate the individual into Collection and either select another owned line or hatch randomly from owned lines. Graduation never erases the individual’s name, dates, usage, XP, provider ratios, nature, rarity, or shiny state.

Random hatching draws only from animal lines already owned through the cash storefront. A hatch produces an individual with rarity, one original EvoBar nature, and a normal or shiny variant. Shiny probability is configurable in the economy manifest. Direct selection remains available so randomness never blocks use of a purchased line.

Token Coins are earned from daily effective tokens using the same diminishing-return input as XP. Coins cannot be purchased or transferred. The gameplay shop contains Rare Candy for bounded growth, Mint for nature rerolls, Shiny Charm for a configurable shiny-rate modifier, and random eggs. Item effects, prices, and safeguards live in the game-economy manifest.

## Care and bond

- Feeding: a Feed button serves the whole bowl at once. The XP gauge fills in a single spring-loaded sweep and the meal counts as care without spending a petting slot. An empty bowl disables the button.
- Affection: 0 to 100, stored in hundredths, starting at 50. Petting gives +2 up to five times a growth day; a Treat (15 Token Coins) gives +12 up to twice a day. After one day of grace, each neglected day costs 0.20. Affection never changes XP, evolution, coins, or anything the user is working toward, and the companion never leaves.
- Presentation: no number is shown. Five hearts and a named relationship stage carry the bond, each stage with its own line: Hurt, Guarded, Warming up, Fond, Devoted. Petting throws drifting hearts.
- Evolution ceremony: acknowledging a stage plays four beats over the Home tab. A flinch and a raised mark, the two forms alternating inside a white silhouette at an accelerating rate while the body stretches, a white-out, then the new form landing with a sparkle burst and its name. Reduce Motion collapses the alternation to one cross-fade.
- Notifications (opt-in, one per transition): evolution ready, evolved, final form reached, new companion, shiny hatch, coin milestones (10, 50, 100, 250, 500, 1,000, 2,500, 5,000), and entry into the Guarded, Hurt, or Devoted stage.

## Companion surfaces

- The status-item companion exposes idle, working, evolution-ready, and sleeping states.
- The menu bar shows the sprite beside today's compact token count (for example 21.1M), plus estimated cost and quota percentage when available. The text can be hidden in Settings so the item fits a crowded notch display.
- The Home tab shows the companion in a scrolling scene. Ground marks and hills move at a state-dependent speed, flyers (pterosaur, phoenix, dragon) hover, and the evolution bar shimmers once the next stage is ready.
- Walkers loop a synthesised gait built from the state's own sprite, posed as a two-bone skeleton per leg.
  - Analysis runs on the largest connected shape only, so a stray fragment left by sheet extraction cannot pass for the ground. The widest gap between feet is the belly, and its underside is the hip line; the legs are the masses reaching well below it, counted on whichever shin row shows the most, with slivers discarded and near-touching runs treated as one leg. A pair drawn as a single wide mass is halved, and a pair drawn as one narrow leg gets a darkened stand-in behind the body.
  - Every column under the belly belongs to exactly one leg: ownership grows from each leg's narrowest point to the midpoint between its neighbours, with a small lap. A column owned by no leg would be dropped by the body and drawn by no leg, which cuts a notch out of the thigh.
  - Posing is inverse mapped. Each destination pixel asks which source pixel it came from through the rigid thigh and shin transforms, so a limb gets exactly one lookup per pixel and can never tear, double-write, or leave holes.
  - The top rows of each leg form a static hip cap drawn with the body, which hides the pivot so the joint cannot open however far the leg swings. The body is drawn first and is never overwritten, so a swinging leg cannot cut into the torso.
  - The knee flexion alone lifts the foot, so no vertical offset is applied to a bone and the leg cannot come apart at a joint. The body bobs twice per stride.
- A line whose sprite sheet has not shipped is listed in the shop as coming soon rather than sold, and is excluded from the hatch pool. A companion must never appear as a bare emoji. Artwork availability is read from the bundle at runtime, so a line becomes purchasable the moment its sheet lands. A planted foot slides backward at constant speed for the stance fraction of the cycle (walk 0.62, trot 0.5) and then lifts and swings forward in an arc, so the animal reads as moving forward over the scrolling ground rather than moonwalking. Idle and evolution-ready use a four-beat lateral walk (1.1 s), working uses a two-beat diagonal trot (0.6 s); the scene scroll speed is matched to the stance speed. The same frames drive the menu bar item (Smooth 8 frames, Balanced 4, Power Saver still).
- Activating the app without clicking the status item (Cmd+Tab, relaunch) opens the dashboard in a floating window.
- A separate opt-in floating desktop pet supports 48–192 px sizing, free placement, hover usage, right-click actions, and quota-warning speech bubbles.
- Owned animals may be pinned to the menu bar independently of the one active growing individual.
- Animation modes are Power Saver, Balanced, and Smooth; reduced-motion and animation-off settings override them.
- Companion evolution, graduation, quota warning, and quota critical events can produce local notifications.

## Community comparison (opt-in)

Off by default. When enabled, the app sends one row per UTC day to a Supabase RPC: a random install identifier, today's raw tokens, the rolling five-hour tokens, and the app version. The function upserts the row and returns today's rank and sample size; the anon key can execute only that function and has no table access. Below 20 reporters the UI shows a collecting state instead of a rank. Rows are deleted after seven days. Schema: `Supabase/schema.sql`.

## Operations and distribution

- Localizations target Korean, English, Japanese, Spanish, French, and Portuguese. English is the development fallback; manifests use localization keys rather than duplicated display strings.
- Direct distribution is primary: Developer ID signing, hardened runtime, notarization, stapling, and GitHub Releases update metadata.
- A Homebrew cask is published after a stable notarized artifact exists.
- Builds target Apple Silicon first during development and a universal arm64/x86_64 release once Intel CI or hardware verification is available.
- External character APIs and downloaded sprites are deliberately excluded. EvoBar ships and caches only original, versioned assets distributed by the project.

## Original IP boundary

All animal names, designs, stages, rarity, nature labels, sprites, and catalog data are original EvoBar material. Third-party game APIs and character assets are not used.

## Delivery sequence

### v0.1 foundation

Claude Code and Codex local parsing, safe incremental collection, daily growth, five-stage evolution, Cat/Dog starter onboarding, manifest-backed ten-line catalog, menu-bar companion and popover, Collection shell, mock cash storefront, local persistence, settings/privacy, launch at login, tests, and signed/notarized direct-distribution packaging.

### v0.2 monitor depth

Five-hour/week/month aggregates, provider/model tabs, API-equivalent cost engine, official quota adapters, reset and exhaustion forecasts, outage/staleness UI, wildcard paths, refresh controls, Keychain access, and quota notifications.

### v0.3 collection loop

Graduation, multiple persistent animal individuals, rarity/nature/shiny hatching, Token Coin wallet and item effects, pinned companions, and richer original sprite assets.

### v0.4 desktop companion and reach

Floating desktop pet, placement and sizing, speech bubbles, power profiles, six localizations, GitHub in-app update checks, universal Intel support verification, and Homebrew cask.

