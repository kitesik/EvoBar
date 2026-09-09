# EvoBar development handoff

This note preserves the current UI/UX implementation boundary and restart position as of 2026-09-09. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

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
- [ ] C. Longer evolution ladders: cat and dog 7 stages, the other lines 7 to 8 stages within plausibility, with prehistoric relatives promoted to stages where they fit. Touches the manifest and its validation, ManifestTests and LoreTests, the "Stage %lld / 5" strings, EvolutionJourney and the collection capsules, lore pages, stage names in six catalogs, sprite file renames and a per-stage artwork fallback.
- [ ] D. Artwork for every line and every new stage: prompts and extraction grid entries prepared for the image-generation run. This editor cannot generate images; the Codex run can (see ARTWORK.md provenance). Motion is procedural and needs no extra art.
- [ ] E. Quota rule from the product owner: stop below 10% remaining and resume after the reset; record any pause here.

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
