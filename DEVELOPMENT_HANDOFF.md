# EvoBar development handoff

This note preserves the current implementation boundary and restart position as of 2026-09-19, with older checkpoints retained as history. Read the newest checkpoint first. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

## Full alternate inventory and hybrid motion — 2026-09-19

- Current owner request: finish all variants and animations while keeping the quiet Home. All10 lines now have72 normal and72 dedicated Shiny forms with four states each (576 PNGs). This adds176 alternate-state PNGs for Fox, Kirin, Raptor, Pterosaur, Dragon and Phoenix; prior normal and four shipped Shiny sources are unchanged. Stable IDs, XP, hatching odds, entitlements and save schema are unchanged.
- Motion coverage is deliberately hybrid:84 quadruped form/colour combinations use the tested walk/trot rig;60 Raptor/Pterosaur/Dragon/Phoenix combinations add four distinct authored phases each (240 new frames). Menu bar, Home and desktop now share playback; colour never falls back to a different-colour motion strip. Ready-state stars remain visible; sleeping/Power Saver/Reduce Motion are static. No new game/UI system was added.
- A bounded12-strip cache avoids decoding every tick. All four phases use one padded alpha>2 presentation crop, preserving visible RGBA pixels and relative positions while excluding negligible export haze from layout. Normal Pterosaur1 menu height improved from4.31–6.75px to8.24–12.90px at24px. Native menu-only0.5pt contrast shadow preserves sprite colours.
- Untouched source PNGs, exact built-in prompts, selected/rejected generation identifiers and alpha-conserving import records are under Artwork/Sources/ShinyV1 and MotionV1. See [[ARTWORK]] for scope and limitations. The Fox alternate preserves the existing normal silhouette; a proof of nine separately visible tails in every pose and144 hand-drawn strips are NOT claims of this delivery. The strict future all-authored gate remains opt-in and unmet.
- All168 unit/fixture tests passed in338.825s after updating the old Shiny count assertions to42 walking forms/84 poses per colour. No anatomy/alpha/gait tolerance was weakened.5 focused decoding/presentation tests also passed. Native review adds six animated Shiny Homes and a Phoenix ready state. The artwork fixture now has zero pending XP, so it cannot attempt an unrelated save in the isolated store. The first packaging attempt was invalidated by this DEBUG fixture edit during compilation and is not counted as a passing build.
- Final DEBUG-source EN/KO native review passed after fixing the fixture's pending-XP setup inside AppModel (its setter intentionally remains private). New EN Pterosaur/Raptor/Fox/ready Phoenix and KO Pterosaur/Dragon/Kirin/ready Phoenix screens were inspected; the final clean fixtures have no spurious save warning. Final Universal2 packaging, all576 poses/60 strips, six locales, ad-hoc signature, ZIP/checksum and isolated launch passed. The earlier compile attempts invalidated by source edits/private-setter access are not accepted results. Logs are in build/art-review/final-verification-20260919.log (168 core tests) and final-delivery-20260919.log (final UI/package/launch).
- Installed and running from Applications. Live store backup: EvoBar-v1.json.before-install-20260919-221258; prior app retained in the temporary EvoBar-replaced/EvoBar-20260919-221258.app. No live game action or reroll was used as a test. Existing Launch at Login may need one off/on toggle to re-register the replaced bundle. This is an ad-hoc local development build, not a notarized public release. Paid GitHub CI remains disabled, and the dirty Drive mirror was not overwritten.

## Quieter default Home — 2026-09-19 owner clarification

- The owner explicitly clarified that the screen is too complicated; retain functionality and simplify its initial presentation. This supersedes always-visible secondary statistics and care controls in earlier checkpoints.
- Home now defaults to the companion image, name and evolution progress. One initially closed Details & care disclosure retains traits, current stage, affection, activity status, pet/treat buttons, the daily summary and unfinished/held eggs. Direct petting of the companion remains available. Evolution/graduation buttons, ready eggs, discovery acknowledgement and actionable failures remain visible outside the disclosure. No growth, purchase, save or animal record is changed.
- Removed the duplicate pending-XP label and routine growth hint from the default surface. Added a localized disclosure title in all six catalogs and an expanded-details native fixture so hidden capabilities are not silently lost. All 155 tests passed in 296.087 seconds. EN/KO/FR native rendering, Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch passed; the final Korean collapsed Home and English expanded details were visually inspected. No new direct-click or VoiceOver acceptance is claimed, and no paid GitHub CI run was requested.
- Installed and running from Applications. Store backup: `EvoBar-v1.json.before-install-20260919-205850`; previous app retained in the temporary `EvoBar-replaced/EvoBar-20260919-205850.app`. No live game action was used as a test. This remains an ad-hoc development build, not a public notarized release.
- Keep the clarification in [[GAMEPLAY_PLAN]] as the default for further work. Do not remove features or add new ones merely to make this screen quieter.

## Compact layout polish — 2026-09-19 follow-up

- Continuation from `ccc15a2`. No new feature, copy, balance, artwork or persistence change. Home now keeps short identity/stage/status rows inline and moves supporting information beneath them only when their natural widths do not fit. A long companion name can use two lines instead of competing with the activity badge; stage names are no longer squeezed by affection hearts.
- The egg prompt likewise preserves its single-line action and moves it below the description when necessary. French preview confirmed the full species name and egg-placement label remain readable; Korean short-label Home retains its compact layout. The same action and busy-state guards are reused in both arrangements.
- First-session names also allow two lines. Added 328-point-wide long-name first-session and evolution-ready renders to every locale and required-image validation. All 155 domain/fixture tests passed in 285.416 seconds; final UI source was then rebuilt and all six native render passes completed. Final EN/KO long-name and FR egg-prompt screens were visually inspected. The preliminary FR/KO preview is not the final acceptance run. Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch passed through the local pipeline. No new GitHub CI run was requested under the existing cost policy.
- Installed and running from Applications. Store backup: `EvoBar-v1.json.before-install-20260919-204547`; prior app retained in the temporary `EvoBar-replaced/EvoBar-20260919-204547.app`. No live game records were used as test fixtures. This remains an ad-hoc development build, not a public notarized release.
- Keep the product small. Existing native rendering is not a substitute for physical keyboard or VoiceOver acceptance; the earlier unresponsive UI-control tool has not been counted as a passing check.

## Durable companion transitions — 2026-09-19 follow-up

- Continuation from `cc5269d`, with no new game systems or balance changes. Onboarding, evolution, switching, graduating into a new individual and adopting a waiting individual now restore their prior in-memory state if saving fails. An unsuccessful graduation cannot silently consume its required egg or retire the current companion.
- A five-case synthetic regression forces a write failure, checks the original animals/current selection/starter grant/tracking date/inventory/pending XP/coins, restores the save destination, retries, and reopens the store. Every successful path has exactly one growing companion. The first run exposed unstable ordering for equal birth timestamps; snapshots and exports now reuse the existing birth-date/UUID ordering. No test assertion was weakened to hide that failure.
- Evolution starts its ceremony only after the store save succeeds. A failure keeps the original stage, removes the busy state and gives a localized retry explanation. Existing six-language UI and prior companion data are preserved; no live game action is used as a test.
- Final source passed all 155 tests in 302.453 seconds, EN/KO native rendering, Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch through `Scripts/verify-local.sh en ko`. The earlier failed/interrupted runs are not counted. No new interactive/VoiceOver acceptance is claimed, and push-triggered CI remains disabled under the existing cost policy.
- Installed and running in Applications with the store backed up as `EvoBar-v1.json.before-install-20260919-201353`; the previous app remains in the temporary `EvoBar-replaced/EvoBar-20260919-201353.app`. No user game actions were performed as tests. This is still an ad-hoc development build, not a notarized public release.
- The simplicity guardrails and active continuation schedule below remain current. Next possible polish is compact long-label layout; do not add another feature to fill the roadmap.

## Small, reliable play loop — 2026-09-19

This is the current direction and supersedes the older feature-expansion, art-first and quota-pause instructions below. The owner wants continued improvements without a maximal product. Follow [[GAMEPLAY_PLAN]] and [[GAMEPLAY_PACING]]: improve the existing work/growth/discovery loop, not new systems or token consumption for its own sake.

- Home puts the current companion first, offers one compact next-egg action, and links a short daily growth/token summary to Usage. Detailed provider/cost information and the seven-day chart stay in Usage. Collection now counts actual encountered lines and revealed forms, not unlocked licenses; its Met filter and next-form hint use the same projection and preserve discoveries across duplicates, switching and retirement.
- Incubation counts distinct positive-usage days after placement, including out-of-order provider arrivals. An additive optional day ledger restores older saves from already-local usage without taking away earned progress. Ready eggs remain deliberate openings; placement is single-flight.
- Growth, petting and all existing coin-item transactions restore their previous in-memory state on failed saves. Visual care rewards happen only after saving. Failed growth absorption keeps pending XP and does not retry forever. A synthetic failure/retry test covers eight reward paths. It also exposed and fixed an omitted `sceneThemeID` decode; all four backdrop selections now round-trip.
- Reduced-motion hatch/evolution ceremonies immediately show a static final reveal without white flashes, sparks or bounce. The hidden Home scene stops its timeline, and menu-bar elapsed-time transitions can stop an obsolete working animation. No CPU-saving percentage has been measured.
- No new game mechanic, rebalance, animal art, live payment, credential change or real-user test data. Development all-unlocked/free-item behavior stays intact. Public release still needs the existing signing/notarization and payment gates.
- Final-source unit/fixture suite: all 154 tests passed in 295.489 seconds. `Scripts/verify-local.sh en ko ja es fr pt` passed all six native render passes, Universal 2 packaging, signature/resources, ZIP/checksum and isolated packaged launch. English, Korean, Japanese and French changed screens were visually inspected. The separate Korean interactive fixture launched correctly, but the UI-control tool stalled until its five-minute lifetime had expired; no new click/keyboard/VoiceOver acceptance is claimed. Its temporary app/data cleaned up automatically.
- Installed and running from `/Applications/EvoBar.app`. Store backup: `EvoBar-v1.json.before-install-20260919-195540`; previous app retained as `EvoBar-replaced/EvoBar-20260919-195540.app` in the temporary directory. No live egg or care action was used for verification. This remains an ad-hoc development build, not a public release. Push-triggered CI is disabled by the existing cost policy; this checkpoint relies on the completed local pipeline, not an unrun GitHub workflow.
- Next bounded work: exercise failed saves for existing switching/evolution/graduation actions and preserve their records if needed, then review the return to the growing companion. Do not add a new game subsystem. The French compact Home wraps the egg-placement label and abbreviates a long species name; a small layout follow-up can improve that without changing navigation. Keep interactive checks marked unverified until a responsive UI tool is available.
- The existing `evobar` heartbeat was found PAUSED with an obsolete art-first prompt. It is now ACTIVE at its existing 30-minute cadence, attached to this task and aligned with the simplicity guardrails. It checks real allowance, never redeems credits or enables paid overage, and preserves unfinished work for natural recovery when a safe verification unit cannot finish. It avoids duplicate active work and pauses when there is no safe meaningful improvement or new authority is needed. Old dated 10%/reset entries below are historical, not a current pause.

## Gameplay discovery checkpoint — 2026-09-19

- Latest owner direction: prioritize game enjoyment and the anticipation, surprise and collecting loop of PokeTokenBar. [[GAMEPLAY_PLAN]] records the source comparison, implemented slice, next priorities and remaining limitations. No third-party character assets, APIs, paid randomness, growth rebalance or user-store migration was introduced.
- Incubator eggs now require an explicit Open egg action. Home and Collection expose progress and the action; merely opening Home no longer consumes ready eggs. The ceremony saves the individual first, then leaves an acknowledgement card showing species, nature, rarity and alternate-colour status. First discoveries and repeat species have different headings. The current growing companion is not replaced.
- The acknowledgement is session-local, while the individual survives restart in Collection. A quit after the durable hatch cannot reroll the egg. Other graduation ceremonies retain their prior behavior. Inventory and incubator state roll back if placement/hatch saving fails; a second hatch of a consumed egg is rejected.
- Updated all six languages to describe the actual incubation flow, including the outdated Shop guidance. Added native Home-incubator and hatch-discovery fixtures plus an app-model acknowledgement/navigation check. The isolated fixture uses authored alternate-colour Capybara art, not a new art asset.
- All 144 tests passed in 296.292 seconds. English/Korean native rendering and app-model review assertions passed; both new English screens and the Korean discovery screen were visually inspected. All six localization files passed syntax validation. Public release still requires signing/notarization and purchase configuration; the development all-unlocked/free-item configuration remains unchanged.
- Universal 2 packaging, six locales/resources, ad-hoc signature, ZIP/checksum and isolated packaged launch all passed. Installed and launched in Applications; the existing store was backed up as `EvoBar-v1.json.before-install-20260919-180001`, and the previous app was retained in the temporary EvoBar-replaced directory. No live egg was consumed during verification.

## Tracking and first-session checkpoint — 2026-09-19

- The owner asked for autonomous product improvements and installation of the finished result. This slice strengthens the first-session and trustworthy-tracking loop. It does not restore the removed recap, bond ladder or mastery system.
- `UsageTrackingCoordinator` now lives in EvoBarPersistence so fixture tests exercise the actual app pipeline. Its result contains a snapshot plus provider-level transient health reports. Discovery errors and unreadable files no longer masquerade as successful tracking; healthy files/providers continue. No error descriptions, file paths, raw lines or sessions enter the diagnostics.
- `RefreshWorker` (EvoBarInfrastructure) serializes timer/manual/FSEvents triggers and coalesces requests made while busy. Cancellation drains old work before another scan starts; settings generation guards reject obsolete results. Reset drains scanning before deleting data. External quota/service checks run separately from the local scan.
- Ingestion restores the prior in-memory state when persistence fails, and unchanged checkpoint scans avoid rewriting the store. Synthetic regressions cover retries, recovery, malformed records, missing/removed files, denied folders, cancellation and competing refresh requests.
- Home has a compact first-companion introduction and an actionable first-session card instead of empty usage charts. Settings show connection diagnostics, last-check age and native folder selection; the footer opens Tracking. Six localized review scenarios cover connected, denied, partial, paused, manual and compact recovery states. Existing animal artwork and progression rules are unchanged.
- The first version passed 140 tests, English/Korean native rendering and Universal 2 packaging/launch, then was installed with the live store and prior app backed up. Live UI inspection exposed previously silent Codex failures caused by records above the scanner's 8 MiB limit. The scanner now discards oversized complete records with bounded memory, reports a skipped line and continues through later usage; an unfinished record keeps its start checkpoint until a newline arrives. Twenty-one focused scanner/coordinator/refresh tests passed, including chunk boundaries, exact limits, consecutive oversized records and append recovery. Final-source verification is recorded below after completion.
- Remaining release gates include publisher signing/notarization and real payment configuration. The local signing check on 2026-09-19 found no valid code-signing identities; installed tools are Command Line Tools. Development installs remain ad-hoc signed, not notarized public releases.
- Final source passed all 143 tests in 310.116 seconds, all expected English/Korean native renders, Universal 2 packaging, ZIP/checksum and signature/resource verification, and isolated app-launch smoke testing through `Scripts/verify-local.sh en ko`. The updated `/Applications/EvoBar.app` was installed with the prior app and local store backed up. Native interaction confirmed footer-to-Tracking navigation, recovery of previously blocked usage, and both provider connections returning healthy after a manual incremental refresh; the existing companion remained intact. No live usage totals, screenshots or raw logs are committed.

## Mammoth Shiny checkpoint — 2026-09-11 evening

- Mammoth now has seven original authored Shiny forms and 28 state PNGs, bringing dedicated Shiny coverage to Cat, Dog, Capybara and Mammoth: 28 forms / 112 resources. `Artwork/Sources/ShinyV1/MAMMOTH.md` holds the accepted built-in prompt and provenance; `Mammoth.png` is the untouched transparent source and `Mammoth.json` records exact alpha-conserving extraction.
- The Shiny manifest flag is enabled only after all 28 files were exported. Existing normal art, gameplay, odds, entitlements, prices, schema and user data remain unchanged. Coverage/gait tests now exercise all 28 authored Shiny quadrupeds with unchanged thresholds.
- DEBUG-only native review adds Mammoth stage-four Home, final Home and discovered detail journey, bringing the harness to 37 screens per locale. After rebasing onto the automatic-growth UI, all 74 EN/KO renders were regenerated and the Mammoth screens were visually inspected. The combined 113-test suite passed in 329.365 seconds. A pre-existing ambiguous `cos`/`sin` overload in the incoming star path was fixed by using `CGFloat`, restoring the macOS build without changing its geometry.
- Actual weekly allowance was 64% remaining at start and 60% after full local verification. The secondary window remained unavailable rather than zero; no reset credit was consumed.
- Next safe art slice: another unambiguous unfinished line. Fox remains quarantined until its legendary forms show nine separately countable tails. Remaining six Shiny lines and authored biped/wing frame cycles are unfinished. Keep the existing 30-minute quota guard active and continue outside the dirty Drive mirror.

## Capybara Shiny checkpoint — 2026-09-11 afternoon

Resumed from clean `1a8d5c0`; its CI `34568877799` passed. Actual weekly allowance was 73% remaining at start and 71% at the asset/test boundary. No secondary window was reported; no reset credits were used. This checkpoint supersedes older pause and remaining-art notes.

- Added seven original Capybara Shiny forms, 28 state PNGs. Total dedicated Shiny coverage is Cat/Dog/Capybara, 21 forms and 84 PNGs. Source/prompt/extraction records are in `Artwork/Sources/ShinyV1/Capybara.{png,json}` and `CAPYBARA.md`. The 28 files reproduce with identical SHA-256 values and exact source-alpha conservation.
- Normal art and the 56 completed starter Shiny images are unchanged. Only Capybara gets `hasShinyArtwork`; no hatch odds, ownership, prices, XP, schema version or user records are changed. Core coverage/gait tests now exercise all 21 authored Shiny quadrupeds with unchanged thresholds. DEBUG-only native fixtures add stage-four/final Home and discovered detail views; the harness now expects 34 screens per locale.
- The first Capybara atlas failed the pup's standing leg ratio (0.04698 versus the unchanged >0.06 requirement). It was replaced by a fresh transparent generation with clearer exposed legs, not by relaxing the test or altering the gait engine. The revised pup ratio is 0.08118 and all seven standing diagnostics pass. Only final-source full validation counts; earlier failed logs are quarantined in Drive.
- Native review exposed an existing variant mismatch: a Shiny collection tile opened a detail header/journey using normal art. `CompanionDisplaySelection.representativeInstance` now centralizes the existing highest-stage/newest/UUID ordering for pin, tile and detail. The detail header and journey carry that representative's Shiny flag; the educational field guide intentionally keeps normal species illustrations. Two regressions ensure lower-stage Shiny animals cannot reveal later Shiny forms reached only by normal individuals and preserve tie-breaking. No records are mutated.
- Fox Shiny was attempted but NOT shipped. Its first transparent 28-pose atlas failed the nine-visible-tail anatomical check; a targeted tail edit also lost alpha; a fresh larger two-column legendary sheet still failed the tail-count criterion. Drafts and exact prompts are quarantined in the separate Drive delivery, never runtime resources. Do not accept segmentation counts or a non-nil alpha channel as proof of artistic correctness.
- Revised-art validation passed all 108 tests (295.603 seconds), including 21 Shiny quadruped forms, before the collection-selector follow-up. After that follow-up, all seven selection tests (two new, 110 total in the full suite) and all 68 EN/KO native renders passed. The final detail header/journey was visually checked in both languages and shows the actual Shiny variant. Final-source Universal 2 packaging and full CI results belong in the separate Drive delivery's `VERIFICATION.md`; do not confuse the first failed atlas or pre-selector renders with the final version.
- Next safe art slice: Mammoth Shiny or another unambiguous unfinished line. Fox needs a separate anatomical redraw with nine clearly counted tails, not another identical whole-atlas edit. Remaining seven Shiny lines and authored biped/wing frame cycles are unfinished. Keep the existing 30-minute quota-guard heartbeat active; work outside the dirty Drive mirror and preserve its source/index.

## Starter Shiny checkpoint — 2026-09-11

See the newer Capybara checkpoint above when choosing remaining work.

Resumed from clean `2de55b7` after checking the actual reported weekly allowance (81% remaining at start, 78% at the implementation boundary; no secondary window or reset credits used). The normal-art slice passed GitHub CI `34564738266` and is not repeated.

- Added dedicated Cat/Dog Shiny artwork: 14 alternate forms, 56 state PNGs. Source `Artwork/Sources/ShinyV1` holds exact prompts, untouched PNGs and alpha-conserving extraction records. The two attempted Cat edits with baked-in checkerboards were rejected; accepted images are fresh original transparent generations, not pixel-identical recolours. Normal Atlas V2 art is unchanged.
- Optional `hasShinyArtwork` declares the two complete lines. All other lines/older catalogs retain normal-art fallback. No individual is rerolled, no hatch odds, XP, ownership, prices, persistence version or user data are changed.
- Importer accepts `--shiny`, refuses atlases without alpha, and writes dedicated `.shiny` resource IDs. Re-export SHA-256 values match for all 56 files. The package verifier also requires all declared Shiny stage/state files.
- Coverage and gait checks now exercise normal and authored Shiny art independently, with their original safety thresholds unchanged. All 108 tests passed on final source (280.880 seconds). DEBUG-only native fixtures add Shiny Home/Collection: all 62 EN/KO screens rendered, and both new screens were visually checked in both languages. Universal 2 packaging, resources/signature/ZIP checks and isolated app launch passed. This is an ad-hoc-signed development preview, not a public notarized release. Final CI and delivery checks are recorded in the separate Drive delivery's verification note.
- Next art work: the remaining eight Shiny lines, then authored biped/wing cycles. Do not regenerate normal art or these two completed Shiny sources; preserve the dirty Drive mirror and work from the clean checkout. This checkpoint is copied into a separate Drive delivery, never over the mirror's source files.

## Active checkpoint — original art, 2026-09-11

This section supersedes the historical no-art/paused/next-slice notes below. The owner explicitly asked to resume and finish the animal artwork. Work starts from `4c2e292` in the clean checkout outside Google Drive; do not reset or bulk-stage the Drive mirror.

- All 10 current lines now have 72 independently drawn normal forms and 288 transparent state poses. All six undrawn lines and eight recoloured placeholder stages are replaced. Exact generation prompts and untouched originals are in `Artwork/Sources/AtlasV2`; extraction is documented in [[ARTWORK]].
- `Scripts/prepare-art-atlas.swift` splits the actual connected silhouettes instead of assuming equal grid cells. Source alpha totals are conserved exactly; a second export produced identical SHA-256 values for all 288 runtime files. Legacy placeholder/five-column utilities refuse to overwrite existing assets.
- New coverage checks enforce 72 stages, 288 distinct pose resources, transparent borders and no pending-stage flags. Existing gait tests now cover all 42 quadruped forms. The rig measures the actual owned paw pixels and permits a bounded settle of one quarter of the visible leg, fixing floating feet on the new fox/capybara drawings without relaxing test thresholds.
- Raptor is explicitly biped and bypasses the four-leg rig. All normal images are complete; separate Shiny palettes and authored biped/wing frame cycles remain unfinished. Do not describe four state poses as frame-by-frame animation.
- Fixed a pre-existing Swift 6 build error in the care-anchor preference callback by handing the state update back to MainActor. No user data, entitlement IDs, prices, token thresholds, credentials or external services changed.
- Current account reports only a weekly allowance (duration 10,080 minutes), last checked 87% remaining. A missing secondary window is unavailable, not exhausted. No reset credits used. The owner's below-10% pause rule still applies to any actually reported limiting window.
- Original art, cropped sprites, tools and review sheets are also preserved in the Drive project's `Art Deliverables/AtlasV2-2026-09-11`, independently of the dirty mirror source. This confirms local presence only, not remote Drive sync.
- Verification: all 108 unit/fixture tests pass (including the expanded gait suite); EN/KO isolated native review produced 58 screens and passed its startup/window/keyboard checks. Home, compact Home, Collection and detail images were inspected. Universal 2 packaging, ZIP/checksum, ad-hoc signature/resource validation and isolated app launch all pass. These checks do not certify VoiceOver, physical Intel hardware or a multi-monitor session.
- Artwork commit `3526257` is pushed to the existing private repository. Release validation now requires every one of the 72 forms in all four states instead of checking just the old 28; the separate incomplete-bundle check removes only a test copy's raptor sprite and requires rejection. This app is a local development preview, not Developer ID signed/notarized or publicly released. Final CI run/status is linked in the Drive delivery's verification note.

## Current run

- State: paused at the quota safety boundary after completing two verified slices. Adaptive layout/recovery `f5c7595` passed GitHub CI `34317111912`; dismissible feedback `f7fe0ca` passed GitHub CI `34317554011`.
- Starting commit: `1b3de70`, with a clean worktree and passing CI.
- Focus: adaptive popover/dashboard sizing, screen-disconnection recovery for windows and the desktop pet, then keyboard/accessibility and recoverable states.
- Implemented: screen-aware layout and window recovery, compact detail/privacy/graduation sheets, persistent graduation actions, Command-F search, spoken stages/selection, direct Tracking navigation, and non-destructive startup Retry.
- 99 unit/fixture tests and 312 native renders across six languages passed, including startup retry and Tracking navigation checks. Release packaging and CI results are recorded at the checkpoint below.
- Local checkpoint: Universal 2 packaging, resource/signature/ZIP verification, and isolated app launch passed. GitHub CI must be checked against the commit containing this note before considering the slice fully handed off.
- No animal-image changes, live payments, public releases, user-data changes, or new service integrations.

## Field guide slice (Claude, 2026-09-09 evening)

- Landed after `8b39958` while the Codex run was paused: a 67-page field guide (`Sources/EvoBarCore/Resources/lore.v1.json`, `Lore.swift`, `FieldGuideView.swift`) shown in `CompanionDetailView` under the evolution journey, with a discovered-pages badge in the Collection header. Discovery is derived from `animalInstances`; nothing new is persisted and no schema changed.
- The isolated review now renders 58 screens per locale: `field-guide-{light,dark}` was added to `VisualReviewExporter` and `Scripts/review-ui.sh`. Korean renders were checked by eye; the `.git/index` file was found missing on 2026-09-09 18:47 KST and rebuilt with a plain `git reset` (no working-tree change).
- Tests: `LoreTests` (coverage, both languages, discovery from the highest stage reached). Full check passes. No animal-image changes, payments, releases, user-data changes or new services.
- Open: relatives could become playable stages once sprites exist; the manifest's five-stage rule and thresholds would then need the re-spaced ladders proposed in the field-guide artifact.

## Compact dark glass panel (Claude, 2026-09-09 night)

- Landed after `5db78c2`: the panel is 360 by 540 points and always dark glass (`popover.appearance = .darkAqua` with a clear SwiftUI root; the detached dashboard is an `NSPanel` with `.hudWindow`; `EvoStyle` surfaces are white tints). Header row removed, text tabs at the top, Settings in the footer, smaller section titles without subtitles, tighter cards. See the dated section in `UX_REVIEW.md`.
- `VisualReviewExporter` and `Scripts/review-ui.sh` render the dark appearance only: 29 screens per locale, same file names with the `-dark` suffix. `WindowPlacementTests` keep their explicit 420-by-700 inputs and still pass; `WindowLayoutReview` compares against `EvoStyle.height` and needs no change.
- No animal-image changes, payments, releases, user-data changes or new services. A "match system appearance" option was deliberately not added; add one only if users ask.
- Rebased onto `bc6d53a` (the keyboard slice and its checkpoint). Because that slice's CI failed on the localization scanner, the scanner fix described in `NATIVE_UI_CHECKPOINT.md` was applied here as well: an identifier boundary before the view name, the extraction shared as `staticUIStrings(in:)`, and a regression test (`staticStringScannerStopsAtIdentifierBoundaries`, suite now 103 tests). The Codex run resuming after 00:45 KST should not repeat it; the `KeyboardNavigationReview` passed against the new panel in the Korean/English isolated review.
- The `.git/index` on this Google Drive mirror has twice been seen out of step with HEAD (missing on 2026-09-09 18:47; staging a reversal of the field-guide files later that evening, per the checkpoint). Neither editor lost work. Treat a surprising index as a sync artifact: compare against HEAD before trusting `git status`.

## Claude work plan, 2026-09-09 night (product owner request)

Work proceeds in scoped slices, each committed and CI-checked, so a quota pause loses nothing. Resume from the first unchecked item.

- [x] A. Walking scene back on Home (the companion walks across the top of its card with the parallax backdrop; tap to pet); glass tokens with gradient fill and hairline, panel tint 66%.
- [x] B. Shop and collection show an egg for any line that has not hatched; `unlockEverything` in `app-config.json` makes every line owned and items free until the storefront goes live.
- [x] C. Longer evolution ladders: cat and dog 7 stages, the other lines 7 to 8 (see the dated section in UX_REVIEW.md). Sprites for the shifted forms were renamed (`cat.4` became `cat.5`, `cat.5` became `cat.7`, likewise dog; `fox.4` became `fox.6`, `fox.5` became `fox.7`; `capybara.5` became `capybara.7`); stages without their own sheet borrow a neighbour and carry `artworkPending: true`.
- [x] D. Artwork briefs: ARTWORK.md now carries one generation brief per line for the extended ladders (seven or eight columns by four states) and the hand-off steps (calibrate a grid entry in `Scripts/extract-sprite-sheet.swift`, extract, point every stage at its own asset id, drop `artworkPending`). The images themselves still have to be generated by a run with an image tool; this editor has none. Until then the eight pending stages of the illustrated lines show recoloured placeholders (`Scripts/derive-placeholder-sprites.swift`, provenance in ARTWORK.md). Motion is procedural and needs no extra art.
- [x] E. Quota rule from the product owner: stop below 10% remaining and resume after the reset; record any pause here. No pause was needed for slices A to D; the 23:13 KST resume check on 2026-09-09 found every item landed with CI green at `1a22ad2`. The rule stays in force for later slices.

## Next slice for the Codex run (image tool required)

Generate the ten sprite sheets described in the "Extended ladders, 2026-09-09" section of ARTWORK.md, one line at a time, in this order of value: cat and dog (the starters), fox and capybara (replace the recoloured placeholders), then raptor, mammoth, pterosaur, dragon, phoenix and kirin (the lines that still render as emoji). For each: calibrate a grid in `Scripts/extract-sprite-sheet.swift`, extract, point the stages at their own ids and drop `artworkPending`, run `Scripts/check.sh` and `Scripts/review-ui.sh en ko`, record provenance in ARTWORK.md, commit per line. The pending placeholders may simply be overwritten by the extraction.

## Drive mirror repair, 2026-09-10 morning (Claude)

- The mirror's `.git` had lost `refs/heads/main` (unborn HEAD, every file staged as new) and carried stale `index.lock` and `main.lock` files. The branch ref was recreated at `origin/main` (`46e8025`), the index rebuilt with a plain `git reset`, the locks moved out of the repository, and the files the interactive-review commit touched were restored from HEAD. Four identical Drive duplicates (`AppWindowLayout (1).swift` and friends) that broke the build were moved out as well. No history was rewritten; nothing was force-pushed.
- The pattern is Google Drive syncing `.git` internals. Working from a clean checkout outside Drive, as the Codex QA note already does, is the reliable fix; the mirror should become documentation only.

## Gait rig, care burst and glass, 2026-09-10 afternoon (Claude)

- `SpriteGaitRenderer` was rebuilt around a scanline model: legs swing by inverse kinematics from a joint above the hip line (`SpriteGaitAnalysis.thighHeight`, `strideLength`), the body between joint and hip line is a leaning band pinned at the belly's middle, shins shear and squeeze, paws translate, far legs get a shaded copy of the fuller partner leg. Ownership below the hip line is per pixel (`Rig.owner`), a hanging tail is rejected as a leg in standing poses, and a lone wide run splits at the paw gap, the contour, or the middle. The scenery scroll rate follows `strideLength`, so `SpriteGaitMetrics.legHeightFraction` grew with it. UX_REVIEW.md has the reasoning.
- Sprites scale with `.high` interpolation everywhere they are drawn smaller than their sheet (scene, tiles, menu bar). The sheets are pixel art at about 230 pixels; nearest-neighbour downsampling was the visible pixel breakage.
- `CompanionHomeView` gained `CareBurst` and `CareBurstLayer`: a Canvas over the companion card driven by a TimelineView that runs only while a burst is alive. Anchors for the scene and the two buttons come from a preference key in the card's named coordinate space. Reduce Motion skips it.
- `EvoStyle.glass` is 34% now. `StatusItemController.thinPopoverGlass()` walks up from the hosting view to the first `NSVisualEffectView` (on macOS 26.5 the frame class `NSPopoverFrame` is one) and sets the HUD material; if AppKit changes that hierarchy the call finds nothing and the popover keeps its default material. The detached HUD panel asks for `.fullSizeContentView` with a hidden title; on macOS 26.5 the HUD panel keeps a 24-point title bar anyway, drawn as the same glass, so `fitDetachedWindow` sets `CompanionPanelLayout.topInset` (applied by `RootPopoverView`) to 18 only when the title bar height is zero.
- Verified locally: `Scripts/check.sh`, `Scripts/review-ui.sh ko`, the app relaunched from `Scripts/build-app.sh` and its dashboard window captured. Not verified: VoiceOver speech; the popover material on macOS 14 and 15, where `NSPopoverFrame` may not be a visual effect view (the walk then finds none and nothing changes).
- Sheet generation for the ten lines remains the Codex run's slice; nothing here touches the manifests or the sprites.

## Hip-height thigh, 2026-09-10 evening (Claude)

- `SpriteGaitAnalysis.thighHeight` now reaches from the hip line up to 55% of the body height (the hip and shoulder joints); `strideLength` is a separate stored figure (visible leg plus about as much again, clamped) so the stride did not grow with the joint. The band shifts by the driver's knee displacement times depth, eased to zero between the knee column and the belly's middle (`Rig.weight`), and each row is inverted once with a monotonic walk (`Rig.sources`). `bodyRise` adds a twice-per-cycle bounce of 1.2% of body height. The driver of a pair is the leg with the larger owned area down the shin (`Rig.area`), outer leg on a tie; a leg with background between it and its partner gets no ghost.
- Superseded the same night: the joint is at 42% of the height, and the band's shift is full from the knee column outward and fades out over `Band.fade` columns (a little over twice the knee's swing) toward the belly, with `Band.factor` 0.85 for the haunch and 0.5 for the chest. The belly between the bands is rigid. A rigid cutout (haunch and chest as turned pieces with a torso cut) was tried and rejected: seams through the fur and holes behind turned pieces. If the sway still looks strong on a sheet, the levers are the 0.42 joint height, the two factors, and the 0.012 bounce; the stride is `strideLength`, not `thighHeight`.
- `SpriteGaitRenderer.groundShadow` marks wide translucent components in the bottom sixth of a sheet (painted paw shadows); they are excluded from the silhouette used for analysis and never drawn in gait frames.
- `Rig.owner` only covers pixels reachable from the bottom quarter of the sheet without crossing the hip line (`standing`), so belly fur is body. The near leg of a pair (`driver`) is chosen by shin brightness, then owned area, then position; only the other leg of the pair gets a shaded copy (`ghost`) of the near leg's shape.
- `ProviderStatusBanner` now renders inside `UsageDashboardView` under the window picker instead of above the tabs' content.

## Rubber-hose gait rig, 2026-09-11 (Claude)

- `SpriteGaitRenderer.Rig` was rewritten. No skeleton, no inverse kinematics, no bands, no ghost legs, no rotation: each leg's rows slide by `offset(of:)` times a quadratic ramp that is 0 at `legTop[index]` and 1 a quarter above the drawn foot. The torso is rigid and only dips (`bodyRise`). `dropLoosePieces` clears anything in the finished frame not reachable from the hip line, unless the artist drew it loose; `frames(...)` re-renders the whole cycle with `movingLegs: false` when that clearing costs more than 1/40 of the drawing.
- Levers, all in `SpriteGait.swift`: `bendShare` (how far down the bend finishes), the 0.014 dip in `bodyRise`, the settle cap in `offset(of:)`, and the 40 in the fallback test. `strideLength` still drives both the stride and the scenery scroll, so planted feet stay with the ground.
- `SpriteGaitTests.posingNeverBreaksTheDrawingUp` is the invariant that ends the whack-a-mole: a posed frame may be no more broken up than its source sheet. Add it to any future change here before touching the rig.
- Known: the kirin capybara (`capybara.7`) has no background between its legs, so its belly fur is taken as leg and slides. Real walk art for that line resolves it; no rule found so far tells that fur from a leg without also stopping the wolf and the lynx from walking.

## Growth arrives on its own, 2026-09-11 (Claude)

- `EvoBarStore.feedCurrentAnimal` is gone. `absorbPendingXP(now:bonusRoll:)` moves the waiting XP into the companion, rolls `GrowthBonusEngine` (EvoBarEvolution), drops golden coins into the wallet and counts the first arrival of a growth day as care (`AnimalInstance.absorbedOnCareDay`, reset with the care counters). `pendingFoodXP` is `pendingXP` in code and keeps its old JSON key.
- `AppModel.absorbGrowthIfNeeded()` runs only while `isPanelVisible` and Home is selected; `StatusItemController` sets visibility from the popover's show and close notifications and from the detached window. The Home view calls it on appear and whenever `pendingXP` rises, and shows `lastAbsorption` through `CareBurst` (kinds pet, treat, growth) plus a three-second gold note for a lucky or golden roll.
- Rare Candy: `purchaseGameItem(..., candyRoll:)` and `GrowthBonusEngine.candyGrant`; the manifest's `xpGrant` is now the mean, 60.
- `UsageBandGauge` (CompanionHomeView.swift) draws today's tokens against the usage band thresholds.
- Tests: `growthBonusTiersFollowTheRoll`, `candyGrantSpansItsListedValue`, `absorbingXPMovesItRollsABonusAndCountsCareOncePerDay`; the pipeline test absorbs instead of feeding. The six catalogs lost the feed keys and gained `care.treat.action`, `care.bonus.lucky`, `care.bonus.golden`, `ui.growthHint`.

## Usage story, 2026-09-11 (Claude)

- `UsageStoryEngine` (EvoBarUsage) reads a window's events into `UsageStory` (Core): active seconds with parallel sessions merged, peak hour in the growth time zone, longest session. `EvoBarStore.usageDashboard` fills it per window and adds `streakDays`, `bestDay` and `yesterdayTokens` to `UsageDashboardSnapshot` from the daily aggregates. Both snapshot inits default the new fields, so older call sites compile unchanged.
- `UsageDashboardView.storyCard` renders it; input, output, cache and the model list moved into a `DisclosureGroup` (`ui.tokenDetail`) that still honours `showTokenBreakdown`. Fifteen keys were added to the six catalogs (`story.*`, `ui.tokenDetail`).
- Tests: `UsageStoryEngineTests` (four) and `usageDashboardTellsTheStoryOfTheDay`.

## Rarity, nature, shiny and the hatch ceremony, 2026-09-11 (Claude)

- `L10n.nature`, `L10n.natureFlavor`, `L10n.rarity` read the catalog keys (`nature.<id>`, `nature.<id>.flavor`, `rarity.<raw>`); all six catalogs carry the twelve natures with flavours and the four rarities, and `natureAndRarityNamesAreLocalized` holds them to the bundled catalog. `EvoStyle.rarityColor` is the one palette for badges and the egg's glow.
- `AppModel.hatchCeremony` is set by `startNextCompanion` after the store write and cleared after `HatchCeremonyView.total`; the Home tab overlays it like the evolution ceremony, and `absorbGrowthIfNeeded` waits for it. The collection tile, header and detail edits are small and local so the Codex run's `representativeInstance` work is untouched.

## Companion voice, 2026-09-11 (Claude)

- `CompanionVoice.key(nature:mood:state:occasion:roll:)` (EvoBarEvolution) chooses a catalog key; `CompanionHomeView.say(_:)` localises and shows it in `SpeechBubbleView` over the scene. Keys: `voice.<nature>.0..2`, `voice.<nature>.pet`, `voice.state.sleeping.0..1`, `voice.state.working.0..1`, `voice.state.ready.0`, `voice.mood.sulking.0`, `voice.mood.sulking.pet`, `voice.mood.distant.0`, `voice.growth.0..2`. `everyVoiceLineExists` walks the chooser and holds every key to the English catalog; parity covers the rest. EvoBarCoreTests now depends on EvoBarEvolution for that test.
- To add a line: add the key to all six catalogs and raise the matching count constant in `CompanionVoice`; the test picks it up.

## Journal, 2026-09-11 (Claude)

- `AnimalInstance` gained `firstGrowthAt`, `evolutionDates` (stage index to date), `adoringAt`, `firstGoldenAt`, all optional or empty for older records; `PersistedDailyAggregate.tokensByAnimal` mirrors `awardedXPByAnimal` in raw tokens, and `PersistedAppSnapshot.busiestDays` reduces it per individual. The store writes the dates in `absorbPendingXP`, `acknowledgeEvolution`, `petCurrentAnimal` and the treat branch (`notingAdoration`).
- `CompanionJournal.entries(for:animal:busiestDay:)` derives the lines; `CompanionJournalView` draws them at the end of each individual's record in the collection detail, replacing the two loose "final evolution" and "graduated" lines. Ten `journal.*` keys in the six catalogs. Test: `journalDatesAreRecordedAsTheyHappen`.

## Claude checkpoint, 2026-09-11 evening

- Shipped today on top of the Codex art commits, one slice per commit: growth arrives on its own with a bonus roll and a today gauge (`294fb14`), the Usage story card (`5c6ef8b`), rarity, nature, shiny and the hatch ceremony (`b68a844`), the companion's voice (`937b5b0`), and the journal (this commit). Each slice passed the full suite, the Korean renders, packaging, an isolated launch and a live capture locally.
- GitHub CI has been refused since 08:07 UTC for every push, Codex's included: the job never starts and the annotation reads "recent account payments have failed or your spending limit needs to be increased". That is a Billing & plans setting on the GitHub account, not the code. Until it is fixed, the local verification above is the check; re-run the latest workflow once billing is back and confirm green before calling these slices handed off.
- The product owner's approved policy list is finished, one slice and one commit each: the daily gift, scene backdrops for coins, the weekly recap, bond levels, line mastery, the companion card, and the incubator. The two motion items remain: whole-body locomotion as the walk fallback, and a frame-strip playback path so authored frame cycles plug in. Nothing else from that list is outstanding.
- Proposed convention for authored frame cycles, to settle before either run draws one: `<assetID>.<state>.cycle.png`, one horizontal strip of equal frames, strip width an integer multiple of the state sheet's width, frames in gait order starting at touchdown. `AnimalSpriteImage.gaitCycle` will slice such a strip and play it in place of the procedural cycle when it exists; nothing else changes.

## CI on request, 2026-09-11 evening (Claude)

- `ci.yml` no longer runs on pushes to `main`; it runs on pull requests and `workflow_dispatch`. A private repository bills macOS runner minutes at ten times the clock, so the free 2,000 minutes are 200 macOS minutes, about 28 runs of this workflow. Sixty seven runs in eleven days spent it, and every push after that was refused before its first step with a billing annotation rather than a test failure. Neither run's code was at fault.
- `Scripts/verify-local.sh` runs the workflow's four steps in order with the same environment, and is now the check a change has to pass. Both runs should use it per slice. It leaves the same artifacts (`build/ui-review`, `build/release`).
- What it cannot cover is a clean machine. Before a release, or when a change touches packaging, the toolchain or resources, run `gh workflow run ci.yml --ref main` and confirm it green. `release.yml` is untouched and still runs on every `v*.*.*` tag.
- Reading a refused run: if the job has zero steps and no runner name, it never started, so the code is not the suspect. `gh api repos/kitesik/EvoBar/check-runs/<job id>/annotations` carries the reason.

## Daily gift, 2026-09-11 (Claude)

- `DailyGiftEngine.gift(coinRoll:itemRoll:candyXP:)` (EvoBarEvolution) returns `DailyGift`; `GrowthAbsorption.gift` carries it and `total` includes its XP. The store rolls it inside `absorbPendingXP` only when `absorbedOnCareDay` is still false, so it rides exactly the once-a-day branch that already counted care; coins and XP join the same sweep and an egg goes to `itemInventory["random-egg"]`. `AppModel` passes the manifest's Rare Candy XP so the gift follows the economy file.
- Levers: `leastCoins`, `mostCoins`, `candyChance`, `eggChance`. Tests: `theDailyGiftAlwaysGivesCoinsAndSometimesMore`, `theDailyGiftLandsOnceAGrowthDay`.

## Scene themes, 2026-09-11 (Claude)

- `GameItemKind.sceneTheme` plus four manifest items (`scene-dawn`, `scene-dusk`, `scene-night`, `scene-snow`, 60 coins). `SceneTheme` (Core) maps an item id to three colours; `AppSettings.sceneThemeID` holds the one worn, nil meaning the old artwork tint. The store's purchase branch refuses a second buy and wears the theme on purchase; `AppModel.setSceneTheme` toggles it off and on.
- `CompanionSceneView` gained a `sceneTheme` parameter and draws sky, hills and ground from a three-colour palette; with no theme the three are the artwork tint at the previous opacities, so the unthemed scene is unchanged. Test: `sceneThemesAreBoughtOnceAndWornByChoice`, which also holds the manifest and the enum to the same four ids.
- To add a backdrop: one manifest item, one `SceneTheme` case with its colours, and `item.scene-<id>` in the six catalogs. Nothing else.

## Companion card, 2026-09-11 (Claude)

- `CompanionCardView` is a fixed 420 by 560 surface, never scrolled and never tapped; `CompanionCardExporter.png(for:)` draws it through `NSHostingView` and `cacheDisplay`, the same way the review renderer does, and `AppModel.exportCompanionCard` runs an `NSSavePanel` and writes the file. `cardExportMessage` reports the result under the button in the collection detail.
- The harness renders `companion-card-*` each run (40 per locale now), so a broken card fails the local check rather than being found by a user. `CompanionCardNameTests` pins the file-name rules.

## Incubator, 2026-09-11 (Claude)

- `IncubatingEgg` (Core) carries `activeDays` and `lastCountedDayKey`; `EvoBarStore.ingest` counts each egg once per growth day that saw usage, so warmth follows work rather than the clock. `placeEggInIncubator` consumes a `random-egg` (capacity 3), `hatchEgg` records a draw made above it, and `graduateCurrentAndAdopt` raises one that was waiting. `AnimalInstance.isWaitingToBeRaised` is `!isCurrent && graduatedAt == nil`.
- `AppModel.hatchReadyEggIfNeeded` makes the draw with `HatchEngine` (it has the catalog and the charm), records it, and plays `HatchCeremony`; it runs only while Home is visible and after any arrival, so the two ceremonies never overlap. `IncubatorCard` sits at the top of Collection; the graduation sheet gained a Waiting mode that opens selected when one waits.
- Tests: `eggsWarmOnWorkingDaysAndHatchIntoACompanionThatWaits`, `adoptingAWaitingCompanionGraduatesTheOldOne`.

## Policy slices finished, 2026-09-11 night (Claude)

- Seven slices landed after the CI change, each verified by `Scripts/verify-local.sh` and committed on its own: `5d44d6f` daily gift, `38dd9a4` scene backdrops, `f2f089c` weekly recap, `b5a2645` bond levels, `21380d4` line mastery, `f28964c` companion card, `2010658` incubator. The suite is 133 tests and the harness renders 41 screens per locale.
- Two of them changed shapes other work has to know about. `AnimalInstance` gained `careCount` and four journal dates, all defaulting for older records, and an individual can now exist in a third state: hatched, never raised, waiting (`isWaitingToBeRaised`). `PersistedSettings` gained `incubator`. Anything that enumerates instances should decide which of the three states it means.
- Every one of these is paced so it cannot be farmed: the gift and the bond's daily act ride the once-a-day branch, an egg counts a day of usage once, and the recap keys off the calendar week. Adding another reward should ride an existing per-day flag rather than a new timer.
- Still open, both about motion and both needing the Codex run's art or a decision: whole-body locomotion as the walk fallback, and the frame-strip convention proposed in the checkpoint above.

## Raising another companion, 2026-09-11 night (Claude)

- `EvoBarStore.switchCurrentCompanion(to:name:at:)` moves which individual is current without graduating; the one stepping aside keeps everything including `pendingXP`. `AnimalInstance` gained `isResting` and `canBeRaisedNext` beside `isWaitingToBeRaised`, so the four states are named: current, waiting, resting, graduated. Only graduation sets `graduatedAt` and only it is irreversible.
- `PersistedSettings.lastGiftDayKey` moved the daily gift from the companion to the growth day, because switching would otherwise draw it twice. `absorbedOnCareDay` stays per companion, which is correct: that is care for that companion.
- `AppModel.raiseCompanion(instanceID:name:)`, `restingCompanions`, `companionsToRaiseNext`; the button lives on each individual's record in the collection detail, with a naming alert for one that has never been raised. Tests: `raisingAnotherCompanionSetsTheFirstAsideWithoutLosingAnything`, `switchingCompanionsDoesNotCollectTheGiftTwice`.

## The owner's app is installed, 2026-09-11 night (Claude)

- The app the product owner uses now lives at `/Applications/EvoBar.app`, installed by `Scripts/deploy-local.sh`. It had been running out of `build/EvoBar.app` inside the Drive-synced project, which every `build-app.sh` overwrites under it. Do not relaunch the owner's app from `build/`; that directory is a build artifact again. Use the deploy script when a change is meant to reach them, and leave it alone otherwise.
- The live store is `~/Library/Application Support/com.evobar.app/EvoBar-v1.json`, schema 10, and it already carries today's added fields (`careCount`, the journal dates, `incubator`, `lastGiftDayKey`, `sceneThemeID`, `lastSeenRecapWeek`) with the three existing companions intact, so every default-on-decode addition was exercised against real data rather than fixtures. The deploy script writes a timestamped copy before each install.
- Two things about that install to keep in mind. It is ad-hoc signed and unnotarized, which is fine on the machine that built it and nowhere else. And `unlockEverything` is still on, which is what grants every line: the owner's `activeProductIDs` is empty, so turning it off would lock them to the starter. Turn it off only together with real entitlements, as the release checklist says.
- Launch at Login is registered by whichever bundle called `SMAppService.register()`, and that was the old copy. Only the app can re-register, so a path change needs one off and on in Settings, Companion.

## Resume rules

- Check both the five-hour and weekly Codex remaining allowance before work and at task boundaries. Do not use reset credits.
- Below 10%, stop starting edits/heavy checks, preserve the current files, and record pending tests and the limiting window's reset time here.
- After a quota pause, wait until that reset time has passed and a live check confirms at least 10% remaining. The existing thread automation checks every 30 minutes.
- Keep this note up to date so a resumed run does not repeat completed work. Do not assume a clean worktree or overwrite another editor's changes.
- Commit and push only scoped, verified work to the existing `kitesik/EvoBar` repository. Check CI before marking a slice complete.

## Verification scope

- Eight pure geometry regressions and the full 99-test suite passed without changing actual monitor settings.
- Isolated native review passed across all six languages for the first slice (312 renders), then English/Korean/French for the feedback follow-up (168 renders). No user logs or desktop capture were used.
- Both slices passed Universal 2 packaging and isolated launch smoke checks. Check the latest GitHub CI before starting the next slice.
- Real VoiceOver/key interaction and physical monitor unplug/replug remain manual acceptance unless directly exercised.

## Quota pause

- Waiting for reset: yes. The final live check showed 10% five-hour allowance remaining; no new development block was started at that boundary.
- Resume not before: 2026-09-09T10:43:43Z (2026-09-09 19:43:43 Asia/Seoul), five-hour `resetsAt` 1788950623. Recheck actual five-hour and weekly allowance after this time; do not use reset credits.
- Unfinished local checks or failing tests: none. Both code commits passed remote CI. The remaining automation is ACTIVE with 30-minute checks; keep it active while waiting for quota recovery.

## Next scoped slice

- The feedback commit's GitHub CI passed. The renderer now expects 29 dark images per locale (field guide added, light pass removed with the dark glass panel). Do not repeat these completed changes.
- Next: consider an explicitly isolated, temporary interactive app harness for real keyboard/assistive-technology checks. Existing rendering tests are not click or VoiceOver acceptance. Do not test by mutating the user's running companion.
- Concrete remaining layout check: the standalone SwiftUI Settings scene still requests a fixed 420-by-700-point size. The status-item and detached dashboard paths now adapt; evaluate the standalone Settings path separately on short displays without changing system display settings.
- Preserve the current limits: no real dialog interactions with user data, no new services or artwork. Physical display and assistive-technology acceptance still require a genuine interactive check; do not mark them passed from static renders.

## Latest Codex verification, 2026-09-10

- See [[NATIVE_UI_QA_2026-09-10]] before resuming. The scanner fix and standalone Settings sizing are already complete; the older next-task text above is superseded for those items.
- Latest remote code passed CI, and a clean checkout passed 103 tests plus 58 English/Korean dark renders and existing native checks. The attempted in-process accessibility/sheet test could not find the hosting view's children; it was removed and is not a passing acceptance check.
- The Drive mirror has stale HEAD/mixed working files and pre-existing staged changes. It was preserved. Use a clean, verified remote checkout for further source work if that condition remains, and do not bulk-stage the mirror.
- Continue the existing 10% guard and natural-reset automation. No new quota pause was recorded at this checkpoint; no reset credits were used.

## Interactive follow-up, 2026-09-10

- [[INTERACTIVE_UI_REVIEW]] records the new opt-in fixture app and the successful English/Korean out-of-process Collection open/dismiss/search checks. Do not repeat the removed in-process accessibility-tree experiment.
- Fixed Collection accessibility copy: unhatched lines no longer announce stage zero, and unavailable-art lines announce Coming soon. The renderer now checks four summary states. All source edits preceded the passing full suite and English/Korean renderer.
- The clean checkout holds the implementation; the mixed Drive mirror and its staged changes are preserved. Source patch and this note are saved separately in the Drive project. Confirm the code commit's CI and packaging before treating the slice as fully handed off.
- Keep the current quota guard/automation. No reset credits, public release, live payments, user-data tests, or new artwork were used.

## Current weekly quota pause, 2026-09-10 11:30 Asia/Seoul

- Live allowance: five-hour 99% remaining; weekly 4% remaining. No development or heavy verification started. Weekly `resetsAt` 1789454767 is 2026-09-15 15:46:07 Asia/Seoul (2026-09-15T06:46:07Z). Resume only after that deadline and after both live windows show at least 10% remaining. Keep heartbeat `evobar` ACTIVE; do not redeem reset credits.
- The previous local quota checkpoint is absent from the currently observed file. This append restores only the waiting condition, preserving all other content and the Git index. Read [[INTERACTIVE_UI_REVIEW]] for latest source and verification notes before selecting work.
- Code `eecb81f` and checkpoint `46e8025` were pushed. Tests, EN/KO renders, Universal 2 packaging and isolated launch smoke passed. GitHub CI 34381962168 remains to be confirmed after recovery. Actual VoiceOver speech remains untested. Verify the current Git state before resuming and preserve existing changes.
