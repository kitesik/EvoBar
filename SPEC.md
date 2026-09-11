# EvoBar Product Specification

This specification records the implementation scope as of 2026-09-08. The UI refinement and its reference analysis are recorded in [[UX_REVIEW]].

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
- Usage bands: three user-adjustable daily raw-token thresholds (default 1M, 5M, 20M) drive a heat treatment on the Today tile and a four-band gauge under today's count, ticked at the thresholds, so the number has a scale. No band name is displayed.
- Day rank: today's raw tokens ranked against the last 30 recorded days.
- Story: each window leads with the numbers people feel, read off its events: time working together (a session's events within ten minutes are one stretch, a lone event is a minute, parallel sessions count once), the busiest hour, the longest session, the tokens as novels (120,000 each), the main model, and for today the streak of days with usage, the ratio to yesterday and the busiest day on record. Input, output, cache and the model list sit in a collapsed token detail for those who want them.
- First scan backfills the current growth day; earlier history is baselined and not counted.
- Discovery: provider defaults plus user-added wildcard log paths; permission and empty states remain provider-specific.

Raw events retain only stable event ID, provider, session ID, timestamp, model ID, token counts, and a one-way source fingerprint. Prompt, response, code, raw JSON lines, project names, and file paths are neither stored nor logged.

## Growth

Daily raw tokens are transformed with diminishing returns: 100% through 1M, 50% from 1M–5M, 20% from 5M–20M, and 5% above 20M. XP is `floor(effectiveTokens / 10,000)`. Daily target XP is recomputed and only the positive difference from already-awarded XP is credited. Credited XP waits, shown only as a translucent run ahead of the fill on the growth bar with the amount beside the count, until the Home tab is on screen; then it arrives on its own: the bar sweeps, the count rolls, and a roll may add to it (15% lucky, half again; 3% golden, doubled plus three Token Coins). A roll never subtracts, and the bonus is a share of what arrived, so opening the panel more often changes nothing. Rare Candy takes the same path and is worth two thirds to four thirds of its listed XP.

## Collection loop

The first companion is a directly selected Cat or Dog. At final evolution, the user may graduate the individual into Collection and either select another owned line or hatch randomly from owned lines. Graduation never erases the individual’s name, dates, usage, XP, provider ratios, nature, rarity, or shiny state.

Field guide: every stage, and the real prehistoric relatives met on the way up, is a page in the companion's detail sheet. Sixty-seven pages across the ten lines carry an era, a range, one size figure drawn to scale beside a 1.7 m person, two facts and a field note, the detail an enthusiast would tell a friend. Pages are written in Korean and English and the other four languages read English, so the guide can grow without waiting on six translations of a fact. A page is discovered when any companion of the line, graduated ones included, has reached its stage; a relative opens with the stage it sits after; a locked page shows only its era as a hint. Discovery is derived from the collection and never stored separately. Relatives are guide pages, not playable stages: a stage needs a sprite sheet, a page does not, and lines whose art has not shipped still carry a full guide. The Collection header counts discovered pages beside owned lines.

Random hatching draws only from animal lines already owned through the cash storefront. A hatch produces an individual with rarity, one original EvoBar nature, and a normal or shiny variant. Shiny probability is configurable in the economy manifest. Direct selection remains available so randomness never blocks use of a purchased line. Rarity, nature and the shiny mark are shown wherever the individual is (the Home card, the collection tile, the individual's record), with a one-line flavour for the nature, so what a hatch produced can be seen. Every new companion, chosen or hatched, arrives through a hatch ceremony over the Home tab: the egg stirs, cracks and shakes, glows in the line's rarity colour (gold for a shiny), blows out to white, and the companion lands with its name, species and rarity.

Token Coins are earned from daily effective tokens using the same diminishing-return input as XP. Coins cannot be purchased or transferred. The gameplay shop contains Rare Candy for bounded growth, Mint for nature rerolls, Shiny Charm for a configurable shiny-rate modifier, and random eggs. Item effects, prices, and safeguards live in the game-economy manifest.

## Care and bond

- Arrival: nothing to press. XP that gathered while the panel was closed sweeps into the bar when Home is on screen (instant with Reduce Motion), and the first arrival of a growth day counts as care without spending a petting slot. Pet and Treat are the two care controls.
- Affection: 0 to 100, stored in hundredths, starting at 50. Petting gives +2 up to five times a growth day; a Treat (15 Token Coins) gives +12 up to twice a day. After one day of grace, each neglected day costs 0.20. Affection never changes XP, evolution, coins, or anything the user is working toward, and the companion never leaves.
- Presentation: no affection number is shown. Five hearts and a named relationship stage carry the bond: Hurt, Guarded, Warming up, Fond, Devoted. Petting briefly shows a heart and a gentle response; Reduce Motion removes scaling.
- Evolution ceremony: acknowledging a stage plays four beats over the Home tab. A flinch and a raised mark, the two forms alternating inside a white silhouette at an accelerating rate while the body stretches, a white-out, then the new form landing with a sparkle burst and its name. Reduce Motion collapses the alternation to one cross-fade.
- Notifications (opt-in, one per transition): evolution ready, evolved, final form reached, new companion, shiny hatch, coin milestones (10, 50, 100, 250, 500, 1,000, 2,500, 5,000), and entry into the Guarded, Hurt, or Devoted stage.

## Companion surfaces

- The status-item companion exposes idle, working, evolution-ready, and sleeping states.
- The menu bar shows the sprite beside today's compact token count (for example 21.1M), plus estimated cost and quota percentage when available. The text can be hidden in Settings so the item fits a crowded notch display.
- The Home tab uses a compact companion card with name, state, bond, exact XP remaining, and an explicit care/evolution action, followed by today and seven-day usage cards. The older scrolling landscape view is no longer used on Home. The menu-bar sprite animation and four-beat evolution ceremony remain available.
- Walkers loop a synthesised gait built from the state's own sprite, posed as a three-bone skeleton per leg (thigh, shin, paw) driven by a foot target.
  - Analysis runs on the largest connected shape only, so a stray fragment left by sheet extraction cannot pass for the ground. Legs end within the pose's reach of the ground (a standing pose within 4% of body height, a running pose within 12%), the belly between them hangs well clear of it, and the hip line is the median underside of the belly between the outermost low columns; a tail or a chest tuft outside that span is body however low it hangs. The hip line is where the leg leaves the body and is never pushed up into the body to lengthen a leg: turning belly into leg makes a swing carry a slab of belly and leave a rectangular hole behind, so a stubby animal takes stubby steps instead. The legs are the masses reaching well below the hip line, counted on whichever shin row shows the most, with slivers discarded and near-touching runs treated as one leg. A pair drawn as a single wide mass is halved, and a pair drawn as one narrow leg gets a darkened stand-in behind the body.
  - Every column under the belly belongs to exactly one leg: ownership grows from each leg's narrowest point to the midpoint between its neighbours. A column owned by no leg would be dropped by the body and drawn by no leg, which cuts a notch out of the thigh; a column owned twice is posed twice and leaves a shard.
  - The foot leads and the leg follows. Each foot runs a stride path (planted: sliding backward at constant speed for the stance fraction of the cycle, walk 0.62, trot 0.5; lifted: swinging forward in an arc), and two-bone inverse kinematics solves the thigh and shin to reach it, hind legs folding forward at the stifle and front legs back at the elbow. Half the stride is 0.40 leg lengths at a walk and 0.46 at a trot, measured from the hip line to the ground, centred half-way from the hip to the drawn foot so a standing pose keeps its stance and a running pose keeps half its splay. The paw lies flat while planted and trails during the swing.
  - The body's height each frame is set by the planted legs: a foot far from its hip needs the hip lower to stay on the ground, so the body is lowest while the planted legs are splayed and highest as one passes vertical, the rise and fall of a real walk. This is what keeps a planted foot on the ground instead of floating at the ends of its stride; the drop is capped at 14% of leg height.
  - Posing is inverse mapped. Each destination pixel asks which source pixel it came from through the rigid bone transforms, so a limb gets exactly one lookup per pixel and can never tear, double-write, or leave holes. Neighbouring bones share a short band at each joint, tested parent first, so no wedge opens at the knee or ankle.
  - The top of each leg is a static hip cap drawn with the body, and the posed thigh also borrows body above the hip line, the way a cutout rig hides a limb's rounded end behind the torso, so a swing fills what it would otherwise open under the belly with the fur just above. The body is drawn first and is never overwritten, so a swinging leg cannot cut into the torso.
  - Idle and evolution-ready use a four-beat lateral walk (1.1 s), working uses a two-beat diagonal trot (0.6 s). The scene renders 16 frames per cycle and scrolls the ground at exactly the planted foot's speed, so the feet never skate; the same frames drive the menu bar item (Smooth 8 frames, Balanced 4, Power Saver still).
- A line whose sprite sheet has not shipped is listed in the shop as coming soon rather than sold, and is excluded from the hatch pool. A companion must never appear as a bare emoji. Artwork availability is read from the bundle at runtime, so a line becomes purchasable the moment its sheet lands.
- The Home tab carries a seven-day usage card after the companion and today's summary: one bar per calendar day ending today (quiet days as zero), today solid and earlier days faded, the week's total in the header, and each bar's count on hover. The week bars and growth bar use EvoBar's semantic green accent, independent of the animal artwork. Every element on the tab shares one 16 pt horizontal inset.
- Activating the app without clicking the status item (Cmd+Tab, relaunch) opens the dashboard in a floating window.
- A separate opt-in floating desktop pet supports 48–192 px sizing, free placement, hover usage, right-click actions, and quota-warning speech bubbles.
- Owned animals may be pinned to the menu bar independently of the one active growing individual.
- Animation modes are Power Saver, Balanced, and Smooth; reduced-motion and animation-off settings override them.
- Companion evolution, graduation, quota warning, and quota critical events can produce local notifications.

## Community comparison (opt-in)

Off by default. When enabled, the app sends one row per UTC day to a Supabase RPC: a random install identifier, today's raw tokens, the rolling five-hour tokens, and the app version. The function upserts the row and returns today's rank and sample size; the anon key can execute only that function and has no table access. Below 20 reporters the UI shows a collecting state instead of a rank. Rows are deleted after seven days. Schema: `Supabase/schema.sql`.

## Operations and distribution

- Localizations target Korean, English, Japanese, Spanish, French, and Portuguese. English is the development fallback; manifests use localization keys rather than duplicated display strings, and every manifest key (animal, stage, product) is carried by all six catalogs. Every string the UI shows, interpolated ones included, has a catalog entry; a `Text` fed a `String` parameter is never localized on its own and must go through `L10n`. UI copy uses commas and spaces as separators, never a middle dot.
- Direct distribution is primary: Developer ID signing, hardened runtime, notarization, stapling, and GitHub Releases update metadata.
- A Homebrew cask is published after a stable notarized artifact exists.
- Builds target Apple Silicon first during development and a universal arm64/x86_64 release once Intel CI or hardware verification is available.
- External character APIs and downloaded sprites are deliberately excluded. EvoBar ships and caches only original, versioned assets distributed by the project.

## Original IP boundary

All animal names, designs, stages, rarity, nature labels, sprites, and catalog data are original EvoBar material. Third-party game APIs and character assets are not used.

## Delivery sequence

### v0.1 foundation

Claude Code and Codex local parsing, safe incremental collection, daily growth, seven- or eight-stage evolution per line, Cat/Dog starter onboarding, manifest-backed ten-line catalog, menu-bar companion and popover, Collection shell, mock cash storefront, local persistence, settings/privacy, launch at login, tests, and signed/notarized direct-distribution packaging.

### v0.2 monitor depth

Five-hour/week/month aggregates, provider/model tabs, API-equivalent cost engine, official quota adapters, reset and exhaustion forecasts, outage/staleness UI, wildcard paths, refresh controls, Keychain access, and quota notifications.

### v0.3 collection loop

Graduation, multiple persistent animal individuals, rarity/nature/shiny hatching, Token Coin wallet and item effects, pinned companions, and richer original sprite assets.

### v0.4 desktop companion and reach

Floating desktop pet, placement and sizing, speech bubbles, power profiles, six localizations, GitHub in-app update checks, universal Intel support verification, and Homebrew cask.
