# EvoBar development handoff

This note preserves the current UI/UX implementation boundary and restart position as of 2026-09-09. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

## Current run

- State: adaptive layout/recovery slice verified locally and ready for GitHub CI; not paused for quota.
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

## Pending verification

- Add pure geometry regression tests without changing actual monitor settings.
- Use isolated fixtures for native SwiftUI layout renders; no user logs or desktop capture.
- Run the unit/fixture suite, package a Universal 2 candidate, and run isolated launch smoke checks.
- Real VoiceOver/key interaction and physical monitor unplug/replug remain manual acceptance unless directly exercised.

## Quota pause

- Waiting for reset: no.
- Resume not before: not applicable.
- Unfinished commands or failing tests: none at start.

## Next scoped slice

- Keep Settings action feedback reachable below long scrolled sections, as already done for Shop.
- Add full-label help for compressed navigation tabs and verify feedback/keyboard accessibility semantics using isolated views.
- Preserve the current limits: no real dialog interactions with user data, no new services or artwork. Physical display and assistive-technology acceptance still require a genuine interactive check; do not mark them passed from static renders.
