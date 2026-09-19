# EvoBar baseline pacing

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
