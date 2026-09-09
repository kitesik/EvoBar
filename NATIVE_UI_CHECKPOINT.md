# EvoBar native UI checkpoint

This note records the resumed UI/UX slice and its handoff as of 2026-09-09 evening (Asia/Seoul). It supplements [[DEVELOPMENT_HANDOFF]] and [[UX_REVIEW]] without replacing the separately added field-guide work.

## Completed

- Native Settings windows now fit the visible display, including the title bar, and preserve their SwiftUI root and selected settings group as screen sizes change. This production change is commit `5db78c2`; [its GitHub CI](https://github.com/kitesik/EvoBar/actions/runs/34342959823) passed.
- The isolated review now checks an actual hidden Settings window against synthetic short and negative-origin screens, empty screen inventories, and root detachment. It does not change real monitor settings.
- The following isolated keyboard slice verifies dashboard Command-1 through 4, Command-comma, Collection Command-F focus, and Escape clearing a fixed test search string. It also verifies no navigation from an unmodified numeral and no changes to records, entitlements, XP, or coins.
- Verification: the 102-test local run passed before the final Escape-search fixture addition; native-window/shortcut checks in all six languages, 348 light/dark renders, Universal 2 release-configuration packaging, resource/signature/ZIP checks, and isolated packaged-app launch passed after that addition. The final committed source failed the localization test in CI; see the quota checkpoint below. Do not mark this keyboard slice fully verified yet.
- The packaged candidate is still ad-hoc signed, not notarized or publicly released. No live payments, new services, user data, or animal-image changes were made.

## Existing working-state boundary

- This run began with separately authored field-guide content in HEAD and on disk, but an index staging its reversal (including deletions of the four field-guide files). The field-guide files remain present and unchanged. Do not mistake these pre-existing staged changes for this run's work or include them in an ordinary commit.
- Only clean, explicitly named paths were committed using scoped commits. The pre-existing staged patch's SHA-256 remained `60f0b485ae5172a0a0a5964cde342321723fbb58cda9d2d1577a3994b8edd444` after the Settings commit. Do not reset, rebuild, or clear the index merely to obtain a clean status.
- The local handoff receives an appended checkpoint link, left unstaged to preserve that pre-existing index. This note is the independently committed checkpoint for a fresh checkout.

## Resume and next scope

- The previous 19:43 quota deadline passed and a live check confirmed recovery before this run. Continue checking both five-hour and weekly remaining allowance; below 10%, stop new work and record the relevant natural reset deadline. No reset credits are authorized.
- The existing 30-minute automation remains active. If a new quota pause is recorded in the local handoff, wait for its deadline and a live allowance check before resuming.
- Do not repeat the standalone Settings fix or the already verified shortcut checks. Next, safely extend the isolated harness to test sheet opening/dismissal and focus return, or evaluate the accessibility tree of Collection/Shop controls. Keep physical keyboard and actual VoiceOver checks explicitly separate from programmatic assertions.
- Preserve the user's running companion and all field-guide work. No live account dialogs, payment setup, public release, new art, or additional integrations are authorized by this checkpoint.

## Quota stop and CI correction, 2026-09-09 evening

- Waiting for natural reset: yes. Live five-hour allowance fell to 7% (weekly 25%). No new implementation or heavy verification was started after that check; no reset credit was consumed.
- Resume not before **2026-09-09T15:45:14Z / 2026-09-10 00:45:14 Asia/Seoul**, five-hour `resetsAt` **1788968714**, and only after a live check confirms both windows have at least 10% remaining. The active automation checks every 30 minutes, so this is an earliest eligible time, not an exact wakeup promise.
- Keyboard commit `1f2ddd9` [failed CI](https://github.com/kitesik/EvoBar/actions/runs/34343531081) at `LocalizationResourceTests.staticSwiftUIStringsArePresentInLocalizationCatalog`. The regex lacks an identifier boundary and matches the `Text("...")` suffix inside the test harness's `editor.insertText("evobar-fixture-search-no-match", ...)`. The resulting false-positive key was reported as missing. Native UI review/packaging did not run in this CI attempt because unit tests failed first.
- The earlier local 102-test run was already in progress when the final Escape fixture edit was made. Although the later render and packaging checks passed, that unit result must not be treated as validation of the final committed source. On resumption, finish edits before starting the final full suite.
- No fix has been applied. First scoped action: add a proper identifier boundary to the static-UI-string extraction regex, share that extraction with a regression test proving real `Text`, `TextField`, and `.help` literals are collected while `insertText`/other identifier suffixes are not. Do not add a fake fixture string to production localization catalogs or disable localization coverage.
- Then rerun the complete suite (expected 103 tests after one added regression), English/Korean native review, commit only explicitly scoped clean paths, push, and inspect CI. Existing field-guide staged changes must remain preserved. The staged-patch hash still matched the recorded value after both code commits.

## Scanner fix applied by the other editor, 2026-09-09 night

- Claude applied the first scoped action above while this run was paused: `LocalizationResourceTests` now extracts static UI strings through one shared function with an identifier boundary before the view name, and a regression test proves `Text`, `TextField`, `Button` and `.help` literals are collected while `insertText("...")` and `myLabel("...")` are not. Suite: 103 tests. No fixture string was added to the catalogs and coverage was not disabled.
- Landed together with the compact dark glass panel (360 by 540, fixed dark appearance, Settings in the footer); see `UX_REVIEW.md` and `DEVELOPMENT_HANDOFF.md`. The keyboard review passed against that panel in the isolated Korean/English run. Check the CI result of the latest commit on `main` before resuming; do not repeat this fix.
