# Native UI QA, 2026-09-10

This note records the latest-code verification and the limits of the native UI experiment on 2026-09-10 (Asia/Seoul). It supplements [[DEVELOPMENT_HANDOFF]], [[NATIVE_UI_CHECKPOINT]], and [[UX_REVIEW]]; it does not introduce a new product direction.

## Verified baseline

- Reviewed GitHub main at `fd9de6f`, whose code parent is `1a22ad2`. [CI 34350359168](https://github.com/kitesik/EvoBar/actions/runs/34350359168) passed unit tests, native renders, release-candidate packaging, and isolated launch. The later commit changes only the handoff.
- The previous localization failure is already fixed by `1a9a1cf`: the shared static-string scanner has an identifier boundary and a regression test. Do not repeat that fix or add the fixture string to production translations.
- In a clean checkout outside Google Drive, after removing the experiment described below, `./Scripts/check.sh` passed all **103 tests**, and `./Scripts/review-ui.sh en ko` passed with **29 dark screens per language, 58 total**, including the existing Settings-window and keyboard checks.
- The English Home and Korean Collection renders were inspected. The compact 360-by-540 panel, footer controls, seven-stage indicators, and unhatched egg presentation are present. Counts and names are fixtures, not the user's usage.
- No production source, graphics, payments, credentials, or user data were changed by this QA slice. No public release or new local release candidate was produced in this run; the packaging evidence above is the verified remote CI result.

## Sheet/accessibility experiment: not accepted as a passing test

A temporary DEBUG review attempted to locate the Collection cat button by its accessibility identifier, press it, dismiss its detail sheet with Escape, and verify that Command-F could focus search again.

In this host/process, the hosting view returned zero accessibility children, both while hidden and after its fixture-only window was ordered behind other apps without activation. The experiment therefore timed out before pressing the card. It did not reach sheet opening, dismissal, or focus return.

This is a limitation of the attempted test approach, not evidence that the product's card or VoiceOver interaction is broken. No physical keyboard or screen-reader acceptance is claimed. The temporary review file and its invocation were removed, its own windows were closed, and the unchanged baseline was rechecked. No failing experiment was committed or enabled in CI.

## Working copy safety

- The Google Drive mirror's local HEAD was still `bc6d53a`, while GitHub main was six commits ahead. Its working files contain a mixture of later changes and older versions; for example, the local AppDelegate lacked the already-committed keyboard-review invocation.
- The mirror also has the pre-existing staged field-guide reversal and three untracked `(1).swift` copies. These files and staged contents were not deleted, reset, committed, or force-synchronized.
- The staged patch SHA-256 remained `60f0b485ae5172a0a0a5964cde342321723fbb58cda9d2d1577a3994b8edd444`. Fetch updated only the mirror's remote-tracking information.
- Verification used the clean `NativeQA.4cG0jj/repo` checkout under EvoBar's local cache. This documentation is also saved in the Drive project. Before any future source edits, compare local HEAD, origin/main, and working changes; use a clean checkout of the verified remote baseline if the mirror remains inconsistent. Do not bulk-stage the mirror.

## Next safe scope and release boundary

- The standalone Settings fitting and scanner regression are completed. Next investigate an explicitly isolated interactive review app with an out-of-process UI client, or an equivalent supported UI-test setup, to verify actual sheet opening, dismissal, and focus return. Keep synthetic input, actual keyboard use, and VoiceOver results separate.
- Do not infer missing Accessibility permission solely from the zero-child result. Check the chosen client and its actual permissions before deciding what user action, if any, is required.
- Preserve the owner's recent compact dark panel, walking scene, egg presentation, and longer evolution ladders.
- Code inspection confirmed that the existing `unlockEverything` configuration is currently consumed without a DEBUG-only gate: it makes all lines appear owned and skips item coin charges. This remains the owner's development setting; it was not changed here. Disabling/restricting it and verifying release ownership is a required pre-launch check, not evidence of a ready paid release.
- The old quota deadline passed before this run and live allowance was checked. Continue the existing 10% guard for both windows and do not redeem reset credits. At the latest pre-documentation check, five-hour remaining was 32% and weekly remaining was 12%; no new quota pause had been recorded.

