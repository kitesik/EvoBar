# EvoBar development handoff

This note preserves the current UI/UX implementation boundary and restart position as of 2026-09-09. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

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
