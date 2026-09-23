# EvoBar baseline pacing

## Early evolution revision — 2026-09-23

All seven lines now reach stage2 at15 XP and stage3 at150 XP (previously50/300). Stage4 and later remain unchanged pending a separate long-term pacing review. XP earning, daily diminishing returns, existing XP, timestamps and acknowledged forms are unchanged. Lower thresholds may make an existing companion ready sooner, but evolution still requires deliberate acknowledgement; no migration rewrites animal records.

At50k/250k/500k/1m/5m/20m raw tokens per activity day, base-only stage2 timing is now3/1/1/1/1/1 days (previously10/2/1/1/1/1). Stage3 timing is30/6/3/2/1/1 days (previously60/12/6/3/1/1). These controlled calculations exclude bonus XP and items, and are not universal first-day guarantees. The first-hatch results below remain unchanged.

The saved-game walkthrough validates the new stage2 times, replay protection and exact animal-state equality across reload before deliberate evolution. Threshold and notification tests use the new14→15 and149→150 boundaries. This revision improves the first two milestones only; stage3→4 and final-form waits still require review. Do not claim complete gameplay or measured retention.

## Early discovery revision — 2026-09-23

Owner prioritizes attachment, discovery and a simple companion; business registration/payments are out of scope. The ordinary egg now costs12 earned coins instead of40. This is a deliberately small manifest-only change, not a claim of proven retention or fun. Incubation remains three distinct positive-usage days after placement, with no consecutive-day requirement. Existing XP, stage thresholds, coins, inventory, rarity and histories are untouched; there is no retrospective purchase refund or automatic egg grant.

The real-store synthetic walkthrough (minimum two gift coins/day, no random XP/eggs, no other spending, placement after usage) now yields:

| Raw tokens per active day | First evolution | Buy/place egg | First hatch | Previous first hatch |
|---|---:|---:|---:|---:|
| 50,000 | Not yet by day9 | 6 | 9 | Not previously tested |
| 250,000 | 2 | 3 | 6 | 13 |
| 500,000 | 1 | 2 | 5 | 9 |
| 1,000,000 | 1 | 1 | 4 | 7 |
| 5,000,000 | 1 | 1 | 4 | 5 |
| 20,000,000 | 1 | 1 | 4 | 4 |

These are active days, not calendar promises. The very-light50k case still waits nine activity days for a hatch; the next balancing slice must address first-evolution pacing without inventing usage or resetting existing companions. More affordable eggs also affect repeat collecting: validate duplicate satisfaction and incubator capacity before adding special egg types. This change does not solve all progression issues.

Local GameplayPacingTests and EvoBarStoreTests:38 tests passed, including real temporary-file reloads, charged purchases, insufficient balance rejection, deduplication, deliberate hatch and preservation of the original animal (build/early-discovery-tests.log). No live records or logs used. Earlier40-coin calculations below are retained as historical baseline, not current pricing.

## Historical baseline before the revision

2026-09-19, based on the current bundled animal/economy manifests and integer effective-token calculation. These are synthetic scenarios, not measured typical users or retention data. This note supports [[GAMEPLAY_PLAN]] without adding another progression system.

## What the current numbers imply

Cat/Dog first evolution is 50 XP; their seventh and final form is 7,000 XP. The ordinary egg costs 40 earned coins and requires three distinct days of positive usage **after placement**. Coins are earned at one per 100,000 daily effective tokens. A day off does not reset progress.

The table deliberately excludes lucky growth, daily gift XP, items and other spending. It counts active days with the same raw token amount each day, starting from zero. It is a reproducible base-only scenario, not an ETA shown to the player.

| Raw tokens per active day | Base XP/day | Base coins/day | First evolution | Final Cat/Dog form | Afford one egg, base coins only |
|---|---:|---:|---:|---:|---:|
| 250,000 | 25 | 2 | 2 days | 280 days | 20 days |
| 500,000 | 50 | 5 | 1 day | 140 days | 8 days |
| 1,000,000 | 100 | 10 | 1 day | 70 days | 4 days |
| 5,000,000 | 300 | 30 | 1 day | 24 days | 2 days |
| 20,000,000 | 600 | 60 | 1 day | 12 days | 1 day |

The guaranteed minimum first-growth gift adds two coins on a day when the player absorbs growth. With that minimum and no spending, egg affordability becomes 10, 6, 4, 2 and 1 active days respectively. Random egg gifts can be earlier; their timing is not promised. Placing an egg after the last usage of a day means three further working days until it can be opened. Extra same-day log records cannot accelerate that timer.

## Interpretation and next safe step

- The first evolution is attainable in one active day at 500,000 raw tokens in this base-only scenario. Do not call that a universal first-day guarantee.
- Final evolution in roughly two weeks is a heavy-use scenario with the current seven-stage manifest, not the experience of every user. Extra stages extended the original five-stage plan.
- Incubation supplies a smaller discovery loop before final evolution. The current UI should make that loop understandable before adding rarer eggs or more systems.
- Random bonuses, item spending and when growth is absorbed materially change exact timing. The development build's free items make it unsuitable for validating normal economy pacing.
- Next balancing experiment: use isolated saved games at the five rates above, buy only the ordinary egg, and record time to first evolution, first hatch and next choice. Compare the existing cadence with a manifest-only candidate; preserve live XP/stage/history and do not ship a balance change based solely on these calculations.

Calculation sources are local: `Sources/EvoBarCore/Resources/animals.v1.json`, `game-economy.v1.json`, `Sources/EvoBarEvolution/EffectiveTokenCalculator.swift`, `EvolutionEngine.swift`, and `GrowthBonusEngine.swift`. No user logs or prompt content were used.

## Saved-game walkthrough — 2026-09-20

`Tests/EvoBarPersistenceTests/GameplayPacingTests.swift` now exercises the real store at all five rates, reloading its temporary file before each active day. It explicitly charges coins for the ordinary egg, so the app's development free-item override does not affect this check. Fixed rolls provide no growth bonus, two gift coins per active day, and no gifted XP/egg. Growth is absorbed daily; the egg is placed after that day's usage. These are controlled scenarios, not averages or promises to players.

| Raw tokens per active day | First evolution, active day | Buy and place first egg | First egg ready and deliberately opened |
|---|---:|---:|---:|
| 250,000 | 2 | 10 | 13 |
| 500,000 | 1 | 6 | 9 |
| 1,000,000 | 1 | 4 | 7 |
| 5,000,000 | 1 | 2 | 5 |
| 20,000,000 | 1 | 1 | 4 |

The walkthrough also checks that insufficient funds reject early purchases, purchase subtracts the actual manifest price, same-event replay adds neither rewards nor incubation days, and a ready egg survives another disk reload. Opening it creates one waiting individual, preserving the original growing companion and its records. The fixed hatch is a duplicate Cat, a valid owned-starter outcome; species probabilities, alternate-colour odds and player enjoyment are not measured by this test.

The light-use scenario shows a potentially long wait for a purchased discovery. Daily random gifts may shorten it, but no timing is guaranteed. That is a question for player feedback, not justification to change live progression automatically. No balancing candidate or manifest change was applied. Calendar breaks, deferred growth absorption and other purchases are outside this exact scenario; the earlier incubation regressions cover breaks separately. Do not label the active-day counts as universal calendar-day estimates.
