# EvoBar native UI checkpoint

This note records the resumed UI/UX slice and its handoff as of 2026-09-09 evening (Asia/Seoul). It supplements [[DEVELOPMENT_HANDOFF]] and [[UX_REVIEW]] without replacing the separately added field-guide work.

## Completed

- Native Settings windows now fit the visible display, including the title bar, and preserve their SwiftUI root and selected settings group as screen sizes change. This production change is commit `5db78c2`; [its GitHub CI](https://github.com/kitesik/EvoBar/actions/runs/34342959823) passed.
- The isolated review now checks an actual hidden Settings window against synthetic short and negative-origin screens, empty screen inventories, and root detachment. It does not change real monitor settings.
- The following isolated keyboard slice verifies dashboard Command-1 through 4, Command-comma, Collection Command-F focus, and Escape clearing a fixed test search string. It also verifies no navigation from an unmodified numeral and no changes to records, entitlements, XP, or coins.
- Verification: 102 unit/fixture tests, native-window/shortcut checks in all six languages, 348 light/dark renders, Universal 2 release-configuration packaging, resource/signature/ZIP checks, and isolated packaged-app launch passed locally. Check the CI run for the commit containing this note before marking the keyboard slice remotely verified.
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
