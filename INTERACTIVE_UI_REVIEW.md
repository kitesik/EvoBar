# Interactive UI review

This note records the fixture-only review tool and observed UI checks through 2026-09-20 (Asia/Seoul), with older checkpoints retained below. It supplements [[UX_REVIEW]] and [[NATIVE_UI_QA_2026-09-10]].

## Compact failed-egg scrolling — 2026-09-20, 05:22 KST

Added opt-in `./Scripts/review-interactive.sh ko compact-hatch-error`: the real Home is hosted at328x374 points with the existing synthetic ready egg and injected localized error. It keeps the opaque isolated window and does not alter the monitor or enable persisted hatch transactions. This is a presentation scenario, not another save-failure test.

Client-driven scrolling exposed the full Korean error and Open egg button in the viewport with Details & care collapsed. After expanding the disclosure, scrolling again exposed the same complete card below care/usage information. Screenshots confirmed the error and button were above the footer without overlap. A Tab attempt left focus on the window, so keyboard traversal is NOT accepted or diagnosed here; no system keyboard preference was changed. Physical keyboard/VoiceOver acceptance remains separate. Closing the fixture completed temporary cleanup.

## Open egg interaction limitation — 2026-09-20, 03:36 KST

The current isolated presentation window did not respond to Open egg from either Collection or Home. Source inspection explains a missing prerequisite: `InteractiveReviewController` does not set `AppModel.isPanelVisible`, which defaults false and is required by `openEgg`. No error/retry or successful hatch acceptance is claimed from these clicks. This is a fixture limitation, not evidence of a production hatch defect. The fixture was closed and cleanup passed; no runtime guard was weakened.

The separate synthetic disk regression was strengthened instead: failed hatch preserves complete animal records, current selection, inventory, coins and pending XP; retry creates exactly one individual and preserves the originals; rejected replay leaves both in-memory and reopened records unchanged. The focused test and all35 persistence tests passed locally. These store checks do not substitute for an AppModel ceremony/error-state test.

## Ready egg visibility — 2026-09-20, 03:03 KST

Against clean `00c7f90`, the Korean isolated Collection fixture exposed one warming egg and one ready egg. Home initially had Details & care collapsed and still exposed Ready to hatch and an enabled Open egg action. Expanding the disclosure retained that action; collapsing it and returning to Collection retained the same ready egg identifier and100% progress. Opened the waiting Fox detail, dismissed with Escape, and confirmed the same ready egg remained. Returning Home again showed the collapsed disclosure and enabled Open egg, with Mochi still displayed as the companion.

No egg was opened and no real companion was used. This verifies visibility and navigation through client-driven actions/accessibility state, not successful hatching, save persistence, physical keyboard or VoiceOver speech. The fixture window closed and its script confirmed temporary app/state cleanup. No production change was needed.

## Onboarding navigation follow-up — 2026-09-20, 02:31 KST

Verified unchanged source `92380e0` in the Korean isolated onboarding fixture. Pasted `달빛 친구`, selected Dog, went Back to provider setup and Continue to naming: Dog remained selected, the native field retained the exact name, the counter was5/24 and Start was enabled. Then went back through provider setup to Welcome and forward through both steps: the same selection, draft, counter and enabled action survived the full round trip. This completes the navigation check that previously timed out.

No completion action was submitted and no live records or provider logs were accessed. This is client-driven button/paste/accessibility evidence, not physical IME, VoiceOver or a persistence transaction. Closing the fixture window ended the script successfully and removed its temporary app/state. No production change or reinstall was needed.

## Onboarding and graduation names — 2026-09-20

The opt-in DEBUG tool accepts a second screen argument (`collection`, `onboarding`, or `graduation`). Onboarding opens directly at its name step; graduation uses the same isolated presentation animals. Release startup and the isolation guards are unchanged.

Before the fix, both screens displayed all32 pasted characters while their custom bindings kept only24; onboarding's counter already said24/24. Both fields now publish the native edit and then correct length, matching the Collection fix. Against the final source, each Korean screen visibly reduced `ABCDEFGHIJKLMNOPQRSTUVWXYZ123456` to `ABCDEFGHIJKLMNOPQRSTUVWX`, disabled submission for spaces only, and enabled submission for `달빛 친구`. Onboarding also showed the matching24/24 and5/24 counters. Returning through earlier onboarding steps was not completed before the fixture lifetime expired and is not claimed as verified.

These are client-driven paste/accessibility checks, not physical IME or VoiceOver acceptance. Neither onboarding completion nor graduation was submitted; persistence behavior is covered separately by synthetic store regressions. No live records, logs or artwork were used.

## Waiting-companion naming — 2026-09-20

The interactive DEBUG fixture now includes the existing incubator presentation scenario: a warming egg, a ready egg and a waiting Shiny Fox, alongside the original current/resting individuals. These remain presentation-only IDs absent from the isolated store; a switch fails safely without modifying a real animal. The branch still requires the dedicated review bundle ID and isolated runtime.

The Korean client-driven walkthrough exposed two native-alert display bugs that model-only tests missed: a second presentation could show an empty field despite a retained draft, and a32-character paste remained fully visible although the binding silently kept only24. The input now has a fresh identity per presentation; length correction is published after the native edit so the displayed text also updates. No stored name is migrated or truncated by this change.

Observed against the final input implementation:

- Whitespace-only input disabled Start raising this one; pasting `달빛 친구` re-enabled it.
- Pasting `ABCDEFGHIJKLMNOPQRSTUVWXYZ123456` visibly produced exactly `ABCDEFGHIJKLMNOPQRSTUVWX` (24characters).
- Submitting the valid Korean name reached the expected missing-individual error and kept the detail open. Retrying showed `달빛 친구` both in the accessibility tree and screenshot, with no empty placeholder.
- Cancel then reopen also retained the Korean draft. Cancel/Escape returned to Collection with the original Mochi, Biscuit and Fox entries and unchanged displayed stages. All temporary fixture apps exited and their scripts confirmed cleanup.

The first key-synthesis attempt did not enter Korean characters; that attempt is not accepted evidence. Clipboard paste with the client's clipboard restoration was used for the passing Korean check. This is not physical Korean IME or VoiceOver acceptance. Successful persistence and forced disk failure/retry remain covered by the separate synthetic AppModel/store regression, not these deliberately absent presentation IDs. Final pipeline/install results belong in [[DEVELOPMENT_HANDOFF]].

## Companion-switch follow-up — 2026-09-19

Verified the installed source revision `a65af19` using the Korean, separately bundled interactive fixture. The live app and its companion store were not used. This is client-driven button/key interaction, not physical-keyboard or VoiceOver speech acceptance.

- Opened the synthetic resting Dog, Biscuit, and pressed Raise this one again. Its presentation-only ID is deliberately absent from the isolated store, so the action failed without changing the companion. The detail sheet stayed open and exposed the localized error plus Dismiss message action in the accessibility tree.
- Dismissed only the message; the detail stayed open. Retried, pressed Escape, and observed the same error on Collection, with Mochi still marked current and Biscuit still at stage4.
- Dismissed Collection feedback, used Command-F to search Biscuit, reopened its detail, and pressed Escape. The search text and its one-result filter survived; the resting record still showed900XP.
- Closed only the fixture window. The UI client timed out fetching the already-closed app, but the owning script exited0 and confirmed cleanup; a filesystem check confirmed its temporary app/state directory was removed.

This adds interactive acceptance for failure visibility, message dismissal and return navigation. It does **not** exercise the waiting-animal naming alert or a successful persistent switch; those remain covered only by source/model checks and the separate synthetic save-failure/retry regression. The earlier full168-test/native-render/package verification remains the evidence for the unchanged production code. No new CI run or reinstallation was needed for this documentation-only checkpoint.

## Run the isolated app

```bash
./Scripts/review-interactive.sh en
./Scripts/review-interactive.sh ko
./Scripts/review-interactive.sh ko onboarding
./Scripts/review-interactive.sh ko graduation
# Optional lifetime, 10–3600 seconds; default 900:
EVOBAR_REVIEW_SECONDS=300 ./Scripts/review-interactive.sh en
```

The command builds a temporary DEBUG app named **EvoBar UI Review**, seeds presentation fixtures, and opens the real dashboard in a separate window. Use the full app path printed by the script when connecting a UI client: macOS may retain an old registration for the shared review bundle ID after its temporary app has been deleted.

The interactive branch requires the explicit review flag, the dedicated bundle identifier, and the existing isolated smoke runtime. It is absent from RELEASE. The window has an opaque background so screenshots cannot reveal other apps through the production glass material. Closing the window or quitting ends the review; the script removes only its own temporary app and state. The timeout also closes only that process.

Provider detection/scanning, background tracking, update/status/quota requests, notification authorization/delivery, and login-item changes are blocked in the isolated runtime, including manual refresh. These guards do not affect ordinary app runs. Existing smoke/review startup remains isolated as before.

This is a **presentation and interaction fixture**, not a simulator of every persistence transaction. Do not use it to claim that feeding, purchases, export dialogs, system settings, or live provider accounts have been exercised. Those require their separate scoped tests. The developer-wide unlock setting is unchanged and remains a pre-release concern.

## Observed interactions

An out-of-process computer-use client inspected only the dedicated review app:

- English: opened Cat from Collection and closed with Escape; focused search with Command-F; filtered to Biscuit; opened Dog and closed with Done; the search string and focus survived dismissal.
- English: a non-matching query showed the empty-search explanation; Clear search restored the collection.
- Korean: opened the unhatched Fox detail and dismissed with Escape; Command-F and the name Mochi returned the Cat result.
- Korean: confirmed the corrected accessibility descriptions for unhatched Fox/Capybara and unavailable-art lines. Manual Command-R left fixture state unchanged.
- Both review app instances closed and their script cleanup completed.

This resolves the earlier in-process zero-child limitation for these flows. It is client-driven button/key interaction, **not a physical-keyboard or VoiceOver speech test**. Physical monitor changes, real screen-reader behavior, and production glass over different wallpapers remain separate acceptance checks.

## Accessibility correction and regressions

Collection previously announced an unhatched owned line as stage zero. `CollectionAccessibility.summary` now announces Waiting to hatch or Coming soon as appropriate. Hatched individuals retain their name and real stage count; locked lines do not expose a private individual name or discovered stage.

The existing native renderer now checks hatched, unhatched, unavailable-art, and locked summaries using the same helper as the view. It runs with each requested locale. The 103-test suite and English/Korean renderer (58 images plus native checks) passed after all source edits. The interactive tool is opt-in, not a new default CI window-driving dependency.

## Source and handoff

Source work uses the clean remote checkout because the Drive mirror still contains stale/mixed files and pre-existing staged changes. The mirror is not reset or bulk-staged. The implementation patch is saved separately as `INTERACTIVE_UI_REVIEW.patch` in the Drive project; apply it only against its recorded Git base in a clean checkout, not blindly over the mixed mirror.

No real logs, user companion state, credentials, live payments, new services, or animal art were used or changed.


## Quota pause and handoff, 2026-09-10

- Implementation is committed and pushed to GitHub as `eecb81fe9e1c28265766ed454389c479a541e032` (base `618f54a9fb94e7b933901c6bdfc7aff5d21a0a37`). [[INTERACTIVE_UI_REVIEW.patch]] contains only the source/script changes; apply only to a compatible clean checkout, not the mixed Drive mirror.
- Passed: 103 unit tests; 58 EN/KO dark renders plus native checks; Universal 2 packaging; isolated packaged-app launch smoke test. Packaging uses an ad-hoc signature, not Developer ID/notarization or a public release.
- GitHub CI was still running at the last check: https://github.com/kitesik/EvoBar/actions/runs/34381962168 . Check its result first on resumption; do not claim a pass yet.
- Paused because five-hour allowance is 9% remaining (91% used); weekly allowance is 85% remaining. No reset credit was used.
- Resume no earlier than 2026-09-10 07:02:34 Asia/Seoul (2026-09-09T22:02:34Z, `resetsAt` 1788991354), and only after live checks show both windows at least 10% remaining. Keep heartbeat `evobar` active; 30-minute checks may resume later than the exact reset time.
- Next: check CI, inspect clean checkout state, then choose the next bounded UI/UX slice. Actual VoiceOver speech remains untested; do not confuse accessibility-tree checks with VoiceOver acceptance.
- The Drive mirror's pre-existing staged patch was not changed (SHA-256 `60f0b485ae5172a0a0a5964cde342321723fbb58cda9d2d1577a3994b8edd444`).
