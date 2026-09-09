# Interactive UI review

This note records the fixture-only review tool and the observed UI checks on 2026-09-10 (Asia/Seoul). It supplements [[UX_REVIEW]] and [[NATIVE_UI_QA_2026-09-10]].

## Run the isolated app

```bash
./Scripts/review-interactive.sh en
./Scripts/review-interactive.sh ko
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
