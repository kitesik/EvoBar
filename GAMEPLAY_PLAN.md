# EvoBar gameplay direction

Current incubation rule (2026-09-24): two distinct positive-usage days after placement. The three-day references below describe the earlier design; see [[GAMEPLAY_PACING]] for the current synthetic walkthrough.

The hatch result now labels only another individual of an already-met species, using existing six-language copy. A first encounter does not show the previously rejected "first friend" heading. This is presentation only: no species odds, inventory or stored records changed. EN/KO isolated review covers both result states; whether repeats feel worthwhile still needs player feedback.

Collection ownership pass (2026-09-24): a line tile counts actual individual companions (including repeats), while the detail sheet leads with their named records instead of the species encyclopedia. The current companion appears first; each record shows its own form, or the existing front portrait at the final stage. The journey and field guide remain below. This changes presentation only, not discovery counts, ownership, XP or stored history. Local synthetic EN/KO renders cover a repeat Cat and a final Shiny Mammoth; actual owner feedback on attachment is still needed.

Current simplification direction (2026-09-23): see [[PRODUCT_DIRECTION]]. The animal and discovery loop stay central; optional shop items and advanced tracking controls are progressively disclosed without changing records, inventory or growth rules. The active catalog is seven lines; older ten-line descriptions below are historical.

2026-09-19: product direction after the owner's request to prioritize the enjoyment of playing and collecting. This is a gameplay plan, not a claim that feature parity or equivalent player enjoyment has been achieved. See [[SPEC]], [[UX_REVIEW]] and [[DEVELOPMENT_HANDOFF]].

## What to reproduce

The [PokeTokenBar README](https://github.com/chattymin/PokeTokenBar/blob/main/README.md), reviewed on 2026-09-19, describes surprise hatches, weighted rarity, alternate-colour individuals, personality, evolution celebrations, graduation, collection history, earnable items and graded eggs. These mechanics suggest four motivations: anticipation, surprise, attachment and collecting. That interpretation is a design hypothesis, not measured retention evidence.

EvoBar must use its own animals, terminology and assets. No third-party character service or art is needed. No paid random draws, quota-exhaustion rewards or pressure to waste tokens.

## Existing foundation and gaps

| Motivation | Existing EvoBar | Gap to address |
|---|---|---|
| Anticipation | Three active-day incubator, evolution progress | Incubator was buried in Collection; eggs opened automatically on Home |
| Surprise | Weighted random species, nature, alternate colours, hatch ceremony | The result disappeared after five seconds, without a deliberate discovery acknowledgement |
| Attachment | Named individuals, affection, care, journal, preserved progress | Make repeat species feel like separate friends, not discarded duplicates |
| Collecting | Field guide, revealed forms, individual history, graduation | Ten lines cannot offer the same breadth as hundreds of starters; strengthen attainable collection goals before expanding content |
| Agency | Earned coins, items, selecting who grows | Show transparent outcomes and useful choices; avoid more disconnected menus |

## First slice: deliberate discovery

- Show active eggs and held eggs on Home as well as Collection.
- A ready egg stays unopened until the user presses Open egg. Work-day thresholds and randomness are unchanged.
- Resolve and save the individual before playing the ceremony. Leave a result card until acknowledged; distinguish a first species discovery from another individual of the same species.
- Show species, nature, rarity and alternate-colour status. Link to Collection; do not automatically replace the current growing animal.
- The result card is session-local, but the individual is permanently recorded. After a quit during the ceremony, Collection retains the saved individual and the egg cannot be rolled again.
- Never lose eggs on a failed save; reject repeated opening of a consumed egg.
- Keep all six UI languages consistent with manual opening. Remove obsolete claims that eggs are only usable after graduation.

Acceptance: ready eggs survive relaunch; a chosen egg creates exactly one saved individual; the active companion is unchanged; failed placement/opening restores inventory and state; EN/KO compact screens are legible; no real user save is mutated by test fixtures.

## Next slices, in priority order

1. **A readable collection goal.** Let a player identify the next discoverable form and newly discovered entries in one glance. Separate owned licenses from discovered companions. Do not revive the removed mastery/recap/bond-ladder systems as extra currencies or chores.
2. **Meaningful existing choices.** First validate saving for the existing egg and choosing which friend grows. Graded eggs are deferred under the owner's simplicity direction below; do not add more item classes just for reference-product parity. Never sell randomized results for cash.
3. **A satisfying repeat loop.** Review duplicate personalities, graduation and raising the next individual as one coherent flow. Preserve existing records and avoid automatic retirement. Test whether a duplicate feels worthwhile before introducing another growth multiplier.
4. **First-session pacing.** Play-test from a clean save with light, ordinary and heavy fixture usage. Check that there is something satisfying in the first session without granting fake usage or forcing three consecutive days. Keep all thresholds manifest-driven; rebalance only with recorded fixture evidence.

## How to judge improvement

Use local, synthetic walkthroughs plus direct user feedback; no analytics backend is introduced. A new player should understand what is growing, what comes next, how to open an egg and where the new individual went without consulting documentation. A returning player should have one clear next goal. Time away must not erase incubation progress. Functionality alone cannot prove fun: compare these walkthroughs before adding more mechanics.

The currently installed development build unlocks all lines and makes items free. It is useful for inspecting flows, but cannot validate saving up coins or meaningful shop choices. Keep that existing owner configuration intact in this slice; a later economy play-test must explicitly use an isolated save without the development free-item override. As of the 2026-09-19 art delivery, all10 lines have dedicated normal and alternate-colour state art. Motion is hybrid (60 authored form/colour cycles and84 procedural quadruped combinations), not144 hand-drawn cycles. See [[ARTWORK]] for the remaining Fox anatomy limitation; do not restart completed art work based on older checkpoints.

## Simplicity guardrails — 2026-09-19 follow-up

The owner explicitly does not want a maximal service. Continuing work means improving the existing loop, not exhausting a feature backlog.

- Home defaults to the animal, its name and growth progress. The owner clarified that the screen is too busy, not that functionality should be removed. Put traits, affection, care buttons, the daily summary and unfinished eggs behind one initially closed Details & care disclosure. Keep evolution/graduation actions, ready eggs and actionable failures visible. Detailed provider, price and chart information remains in Usage. Preserve existing functions and all records; do not compensate for the simpler screen by adding new features.
- Collection measures actual encounters and revealed forms, not license ownership. Duplicate hatches, switching and retirement must preserve previously revealed progress.
- Show the next undiscovered stage in existing journey details without spoiling its appearance. Do not introduce quests, streaks, multiple new currencies, battle stats or another destination.
- Keep one ordinary egg for now. More rarities of eggs, guarantees and permanent upgrades can wait until the simple loop has been play-tested.
- Respect Reduce Motion with a static reveal, not flashing or bouncing. Do not add notification prompts to make the player return.
- Correct incubation to distinct positive-usage days after placement. Keep existing earned progress; older saves restore their day ledger from local usage only.
- [[GAMEPLAY_PACING]] records baseline pacing and its limits. Do not describe a 10–14-day completion time as universal or rebalance an existing companion silently.
