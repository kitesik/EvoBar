# EvoBar development handoff

This note preserves the current UI/UX implementation boundary and restart position as of 2026-09-09. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

## Current run

- State: adaptive layout/recovery slice `f5c7595` passed GitHub CI run `34317111912`; dismissible Settings/Shop feedback is locally verified and ready for its commit/CI checkpoint. Not paused for quota.
- Starting commit: `1b3de70`, with a clean worktree and passing CI.
- Focus: adaptive popover/dashboard sizing, screen-disconnection recovery for windows and the desktop pet, then keyboard/accessibility and recoverable states.
- Implemented: screen-aware layout and window recovery, compact detail/privacy/graduation sheets, persistent graduation actions, Command-F search, spoken stages/selection, direct Tracking navigation, and non-destructive startup Retry.
- 99 unit/fixture tests and 312 native renders across six languages passed, including startup retry and Tracking navigation checks. Release packaging and CI results are recorded at the checkpoint below.
- Local checkpoint: Universal 2 packaging, resource/signature/ZIP verification, and isolated app launch passed. GitHub CI must be checked against the commit containing this note before considering the slice fully handed off.
- No animal-image changes, live payments, public releases, user-data changes, or new service integrations.

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

- Waiting for reset: no.
- Resume not before: not applicable.
- Unfinished local checks or failing tests: none. The feedback commit's remote CI should be confirmed.

## Next scoped slice

- Confirm the feedback commit's GitHub CI. The renderer now expects 56 images per locale; English/Korean/French review has passed.
- Next: consider an explicitly isolated, temporary interactive app harness for real keyboard/assistive-technology checks. Existing rendering tests are not click or VoiceOver acceptance. Do not test by mutating the user's running companion.
- Concrete remaining layout check: the standalone SwiftUI Settings scene still requests a fixed 420-by-700-point size. The status-item and detached dashboard paths now adapt; evaluate the standalone Settings path separately on short displays without changing system display settings.
- Preserve the current limits: no real dialog interactions with user data, no new services or artwork. Physical display and assistive-technology acceptance still require a genuine interactive check; do not mark them passed from static renders.
