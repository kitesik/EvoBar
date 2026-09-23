# EvoBar gameplay direction

Shop/egg expectation (2026-09-24): earned coins buy the existing Random Egg, which hatches a new individual only from animal lines already owned. The Shop now says this directly in all six locales and distinguishes new-line access as a separate, currently inactive purchase path. The two-day incubation rule remains visible in the Incubator; no hatch odds, currency price, entitlement, or saved record changed. This prevents an egg purchase from implying it can unlock a paid species.

Incubator/collection separation (2026-09-24): the Incubator card shows only held or placed eggs and their actions. A hatched individual waiting to be raised appears in "Your companions" as its own named card and remains actionable through its existing record; it is no longer repeated as a non-interactive row under the eggs. EN/KO synthetic screenshots cover a waiting-only collection and an incubator with two eggs plus a waiting Fox. No inventory, hatch or companion state changes.

Individual collection cards (2026-09-24): "Your companions" now has one tile per saved individual, including duplicates of the same species. Each tile has that individual's name, acknowledged form and current/waiting/resting status; selecting it puts that individual's record first in the existing detail sheet. Search by a name returns only the matching individual, while owned-but-unhatched and locked species remain grouped in their own sections. This changes only collection presentation and accessibility wording, not saved data, discovery counts, entitlements or progression. A synthetic native Korean fixture showed separate Mochi/Bean cards, a Bean-only search result and Bean's record first after clicking it. EN/KO renderer and the complete 196-test local suite passed; no player-enjoyment claim follows from these checks.

Collection ownership refinement (2026-09-24): named individuals remain under "Your companions"; a purchased but not-yet-hatched line appears separately as "Owned"; only genuinely locked lines appear under "Shop". An owned silhouette opens its line details instead of bouncing the player to the Shop. The undiscovered detail uses the black first-stage silhouette with a white question mark, not a coloured egg, and omits the redundant first-hatch instruction. This changes presentation/navigation only, not entitlements, hatch odds, coins, or stored records. Synthetic EN/KO renders cover raised, owned-unhatched, and locked lines; direct owner feedback on the grouping is still needed.

Locked-line preview (2026-09-24): selecting a locked line in Collection opens that exact animal's existing Shop preview in the same panel, instead of dropping the user on the Shop's first screen. The selection is transient view state, so a second dashboard window cannot consume the request. It does not change purchase rights or prices. In an isolated native fixture, searching for the locked Mammoth and activating its Collection card opened the Mammoth preview with its journey, locked final silhouette and $3.99 preview tier; Done returned to the filtered Collection. The fixture did not make a charge; live payments remain inactive. Owned-but-unhatched accessibility wording now says "not discovered yet" instead of calling an entitlement an egg.

Current incubation rule (2026-09-24): two distinct positive-usage days after placement. The three-day references below describe the earlier design; see [[GAMEPLAY_PACING]] for the current synthetic walkthrough.

The hatch result now labels only another individual of an already-met species, using existing six-language copy. A first encounter does not show the previously rejected "first friend" heading. This is presentation only: no species odds, inventory or stored records changed. EN/KO isolated review covers both result states; whether repeats feel worthwhile still needs player feedback.

Earlier collection ownership pass (2026-09-24, overview grouping superseded above): a line tile counted actual individual companions (including repeats), while the detail sheet led with their named records instead of the species encyclopedia. Each record showed its own form, or the existing front portrait at the final stage. The journey and field guide remain below. This changed presentation only, not discovery counts, ownership, XP or stored history. Local synthetic EN/KO renders covered a repeat Cat and a final Shiny Mammoth; actual owner feedback on attachment is still needed.

Final evolution celebration (2026-09-24): only the final-stage reveal now centers a larger front portrait with a restrained glow and ring; intermediate evolutions retain their before/after comparison. Reduce Motion shows a static result without the white flash. This is a presentation change, not new art or growth rules. The final form and record are already persisted on evolution. Home now offers "View collection" rather than pretending to save; the current companion remains active. A separate "Next companion" action on that final individual's Collection record opens the existing selection sheet only when deliberately chosen. This changes navigation, not graduation or stored data; the owner deferred detailed feedback on the next-companion sheet.

Shop clarity (2026-09-24): animal-line access is a separate, currently inactive purchase path; ordinary eggs, care items and scenery use only earned Token Coins. The six-language section headings now say which path applies. Preview USD tiers in the manifest are Cat/Dog $1.99, Fox/Capybara $2.99, and Raptor/Mammoth/Pterosaur $3.99; these are not live charges or finalized regional prices. The isolated locked-line preview states that its debug purchase is mock-only. Coin earnings, egg odds and existing ownership are unchanged. Business registration, payment activation and public release remain excluded.

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
