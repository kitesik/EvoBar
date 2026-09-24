# EvoBar baseline pacing

## Earned-coin pacing — 2026-09-24

Newly recorded usage days can earn at most **three base Token Coins from work**. The existing first-growth daily gift (two to five coins), occasional golden bonus, and occasional free egg are separate and unchanged. Raw token totals and XP are unchanged. This bounds the incentive to generate more tokens merely for coins and keeps the ordinary 12-coin egg from being purchased on the first ordinary workday solely through token volume. It does not impose a cooldown or guarantee a day-three egg: gift rolls and earlier saved balances can make a purchase sooner, while very light/cache-heavy use can take longer.

The daily aggregate persists a coin-curve version. Days already recorded by an older build retain their uncapped coin rule on append, rescan and relaunch; the existing balance is never reduced. The cap applies only when a previously unseen day is first recorded after this change. This is a prospective economy change, not a migration of earned rewards.

With the existing 12-coin egg, minimum two-coin gift, no lucky coins or free egg, daily reload, and a charged purchase after work, the synthetic store walkthrough now gives:

| Daily raw tokens / cache read | First evolution | Stage 3 | Buy/place egg | First hatch |
|---|---:|---:|---:|---:|
| 500k / 50% | active day 1 | 3 | 3 | 5 |
| 1M / 90% | 1 | 3 | 4 | 6 |
| 2M / 90% | 1 | 3 | 3 | 5 |
| 5M / 80% | 1 | 2 | 3 | 5 |

These are controlled active days, not calendar-day promises or observed user outcomes. An uneven-workday regression still buys the egg on its third active day (calendar day 4), and rest days still do not warm it. A single user's existing history was checked only through token-count metadata: it was cache-heavy and variable, while its stored XP/coin days were under older rules. Those observations support testing both light and heavy scenarios but cannot prove a representative retention or revenue effect. No real usage values or animal records are included in fixtures. Review the item's 12-coin price and repeat-hatch satisfaction with players before making further changes.

## Uneven-workday regression — 2026-09-24

An isolated, charged-egg fixture alternates cache-heavy and lighter-cache use on calendar days 1, 3, 4, 6 and 8, with days 2, 5 and 7 off. The companion reaches stage 2 on day 1 and stage 3 on the third **active** day (calendar day 4). Earned coins buy one ordinary egg after work on day 4; it warms on days 6 and 8, not on the intervening rest days. Every day reloads the saved state, and duplicate usage events award nothing again. `GameplayPacingTests.unevenWorkdaysDoNotTurnRestIntoGrowthOrEggWarmth` checks the actual store flow. This is a synthetic regression scenario, not a user-usage sample or a promise of calendar-day timing; no thresholds, prices, saved data or gameplay mechanics changed.

## Early-growth XP curve — 2026-09-24

New activity days award XP from credited growth tokens with a continuous, diminishing-return curve: the first 100k earns up to 36 XP, the next 100k up to 16, the next 200k up to 18, the next 4.6M up to 230, the next 15M up to 300, and each further 200k up to one XP. Integer division floors each band's contribution. Cache reads count at 10%; other input, output, and cache writes count in full. At 1M/5M/20M credited tokens the curve still awards 100/300/600 XP, matching the old anchors. At this XP-only revision, Token Coins, raw usage totals, and the seven/eight-stage manifest thresholds did not change; the newer coin rule is above. This front-loads the first couple of evolutions without adding a daily login bonus or a new system.

The persisted daily aggregate carries the XP curve version. A day recorded by an older build, including a day later appended or rescanned, keeps its original linear curve. A newly recorded day uses the balanced curve. Already awarded XP, coins, stages, and companions are not rewritten. This is a compatibility rule; older saves without a curve field deliberately decode as the legacy curve.

Before the coin cap above, the charged-egg, no-lucky-rewards, daily-reload synthetic walkthrough yielded:

| Daily raw tokens / cache read | Credited growth tokens | New base XP/day | First evolution | Stage 3 | Buy/place egg | First hatch |
|---|---:|---:|---:|---:|---:|---:|
| 500k / 50% | 275k | 58 | day 1 | day 3 | day 3 | day 5 |
| 1M / 90% | 190k | 50 | day 1 | day 3 | day 4 | day 6 |
| 2M / 90% | 380k | 68 | day 1 | day 3 | day 3 | day 5 |
| 5M / 80% | 1.4M | 120 | day 1 | day 2 | day 1 | day 3 |

These are active days, not calendar promises or observed user data. The medium profile's stage 3 still arrives on day 2 and its final form on day 19 in the controlled base-only walkthrough; the lighter profiles now reach stage 3 on day 3. No one should be prompted to spend tokens merely to earn XP. Continue to validate the feel of later waits and duplicate hatches with users; this synthetic check is not retention evidence.

## Cached-context credit, previous linear XP curve — 2026-09-24

This section records the immediately preceding, now historical, XP rule. It introduced 10% cache-read credit for XP and earned Token Coins, followed by the original daily diminishing-return bands. New input, output, and cache creation retained full credit. The usage monitor, cumulative raw-token records, and provider breakdown showed the full raw token count. For example, a synthetic day with 5 million total tokens and 4 million cache-read tokens credited 1.4 million growth tokens: 120 base XP and 12 base coins instead of 300 XP and 30 coins. A synthetic first day with 1 million total tokens and 90% cache reads earned 19 base XP, enough for stage 2 at 15 XP. The new curve above changes that latter XP result to 50 while preserving the coin calculation.

Days saved before that change retained their original award rule, including any later append or rescan on the same day. Nothing already earned was removed. At that point new days used the 10%-cache linear rule; the raw-token total never shrank. The Home growth gauge explains the cache treatment in its hover and accessibility hint. Existing no-cache simulations below remain valid as historical comparisons; their figures are not forecasts for cache-heavy sessions. No real usage or companion data belongs in repository fixtures.

Four normal-economy cached-context walkthroughs now run through the real store, reload it each activity day, purchase and place one ordinary egg with earned coins, deliberately acknowledge each ready evolution, open the egg, and prove replay grants nothing twice. A fixed minimum two-coin daily gift applies; lucky XP and free eggs do not.

| Synthetic daily total / cache read | Base XP/day | First evolution | Stage 3 | Buy/place egg | First hatch |
|---|---:|---:|---:|---:|---:|
| 500k / 50% | 27 | day 1 | day 6 | day 3 | day 5 |
| 1M / 90% | 19 | day 1 | day 8 | day 4 | day 6 |
| 2M / 90% | 38 | day 1 | day 4 | day 3 | day 5 |
| 5M / 80% | 120 | day 1 | day 2 | day 1 | day 3 |

These were **active days**, not calendar promises or user-derived data. Before the new curve, the three lighter profiles waited four to eight active days for stage 3, beyond the desired two-to-three-day rhythm. This motivated the bounded early-XP change above, not a daily quest or extra reward system.

The medium cached-context walkthrough continues through the complete seven-stage Cat line with an actual store reload and explicit evolution acknowledgement each activity day. Stages 2–7 occur on days **1, 2, 4, 7, 12, 19**; gaps after the first are **1, 2, 3, 5, 7** active days. Its first egg can be bought after day 1's work and opened on day 3, without cash purchases or lucky gifts. This remains true under the new curve at 1.4M credited tokens/day. The gap from stage 2 to 3 is still only one more activity day; retain the manifest thresholds until broader fixture profiles and player feedback justify a specific adjustment. Do not inflate real tokens or grant XP simply for opening the app.

## First-hatch cadence — 2026-09-24

An ordinary incubated egg now needs **two distinct days with positive usage after placement** (previously three). Rest days do not reset it, replayed events do not add days, and opening remains a deliberate action. This shortens the first discovery loop without changing token/XP accrual, coin price, rarity, or existing companion records. Eggs already at two or three counted days become or remain ready; progress is never taken away. This is a design hypothesis to check with players, not evidence of measured retention.

In the deterministic saved-game walkthrough below, the egg is bought and placed *after* that day's usage, then the app is reloaded daily. Minimum gift coins and no lucky drops apply. Current first ready/open days at 50k/250k/500k/1m/5m/20m raw tokens per activity day are **8/5/4/3/3/3** respectively. These are active days, not guaranteed calendar-day outcomes. Earlier sections retain the three-day historical results for comparison.

Local checks: 51 focused Core/Persistence/Localization tests passed, EN/KO screen renders completed, Universal 2 package/resource/signature verification and isolated launch passed. No remote CI or real-player enjoyment claim. Next small product check: assess whether a duplicate hatch still feels worthwhile in a clean-save walkthrough before changing species odds or adding rewards.

## Full-line revision — 2026-09-23

Current seven-stage ladder: **0,15,150,400,800,1400,2200 XP**. Eight-stage lines share it and end at **3200 XP**. Earlier sections below are historical. First two evolutions stay unchanged; later required increments now rise135/250/400/600/800/1000 instead of jumping to750 and eventually3000–3500. This manifest-only change keeps the existing XP earning, diminishing returns, random rewards, egg economy, stored XP, acknowledged stages and dates. Existing companions may become ready sooner, but no automatic evolution or graduation occurs.

Design choice: reduce long periods without a visual change and make completing one companion more attainable before raising another. Do not add a daily chore, cap, forced cooldown or extra currency to equalise every usage profile. This is a deliberate balance adjustment supported by controlled comparisons, not retention research or a universal two-week promise.

| Daily raw tokens | Seven-stage base final, old→new | Longest base interval, old→new | Seven-stage seeded final, old→new | Eight-stage base final, old→new | Eight-stage seeded final, old→new |
|---|---:|---:|---:|---:|---:|
|50,000|1400→440|600→160|422→138|1900→640|576→200|
|250,000|280→88|120→32|183→56|380→128|248→83|
|500,000|140→44|60→16|106→33|190→64|144→48|
|1,000,000|70→22|30→8|57→18|95→32|79→27|
|5,000,000|24→8|10→3|21→7|32→11|28→10|
|20,000,000|12→4|5→1|11→4|16→6|15→5|

All numbers are **active days**, not calendar promises. Base excludes all bonuses; seeded figures are the lower middle observation of32 fixed-seed simulations using actual GrowthBonusEngine/DailyGiftEngine and the manifest's60-XP gift. One absorption per day, minimum-independent coin roll, no purchased items or missed days; daily gift/bonus rolls use the same stream for old/new comparisons. This is a sensitivity check, not a statistically representative user sample. At500k, revised seven-stage seeded results ranged28–37 active days; at1m,17–21. At50k,109–173: very-light users still need a long time. At20m,3–4: heavy users may complete quickly and move to another companion. Do not encourage spending tokens to match these scenarios.

Evidence: GrowthPacingTests covers six rates and both ladders, unchanged first milestones and strictly shorter maximum base interval; ManifestTests checks every line uses the correct ladder; EvolutionEngineTests checks below/at every stage threshold for all seven lines. GameplayPacingTests reconstructs old-curve stage3/6/7 synthetic records with400/4000/7000 XP, reloads real temporary storage, verifies exact animal equality/history, then explicitly advances ready stages without altering XP. Earlier first-hatch/replay checks still run. No owner data is used. Installation and actual validation results are in DEVELOPMENT_HANDOFF.

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
