# EvoBar development handoff

## Complete Fox line and static fitting passed full verification — 2026-09-21

- Fixed verify27876 TERMINAL exit0. build/v2-fox-complete-verify-fixed.log:172 tests passed559.571s; EN/KO isolated UI render, Universal2 package validation and isolated packaged launch smoke passed. EN/KO home-dark visually inspected, both Fox state contacts inspected using production fitter. Local only, no remote CI/public release.
- Verified coverage56/144 V2 variants,224 states/224 motion phases; complete Cat/Dog/Fox plus other babies. Legacy-plus-new108 authored/36 procedural. Ready scoped commit/push then deploy-local preserving prior app/store; installed9e5ad90 until confirmed.
- While verification ran, generated but DID NOT import Capybara2 and3 normal/Shiny Motion/States PNGs under PersonalityV2/Stage02 and Stage03. Eight new source PNGs intentionally excluded from Fox commit. Capybara2 elongated muzzle/deadpan/O-mouth ready;3 higher rounded back/lower head/tiny tooth/giant yawn. Normal caramel then chestnut; Shiny dusty rose then plum. Source provenance from built-in image tool, not procedural recolours. They need alpha gates/import, coverage tests and96/24px review AFTER Fox deployment; do not regenerate blindly. Preserve other unrelated untracked files and Drive mirror. Goal active.

## Static pose fitting fixed; clean full verification live — 2026-09-21

- Previous verify82694 is TERMINAL exit1:170 tests, one SpriteGaitTests standing leg-ratio failure (fox.7 normal0.06);575.441s. No packaging success. Do not restart/poll it. The ratio used PNG height including nearly invisible haze, not anatomy.
- Added SpritePosePresentation to AnimalAssets.swift: display-only crop ignoring alpha1–2 with4.5% padding, bounded400px inputs, all alpha>2 pixels preserved without mutating PNGs. AnimalSpriteImage.load caches fitted still images; motion and source import unchanged. review-artwork.swift now links the actual production fitter. Both Fox contacts visually inspected: normal/Shiny scale discrepancy resolved. Review8467 terminal exit0.
- Added synthetic still fitting/pixel-preservation/rectangle/edge/empty tests. Legacy rig leg-ratio test now divides by analysis.bodyHeight rather than transparent canvas height; thresholds unchanged. Targeted8 tests passed43.718s, log build/fox7-pose-fit-tests.log;84473 terminal exit0. No raw logs/save data used.
- NEW full verify-local en ko LIVE session27876, build/v2-fox-complete-verify-fixed.log. This includes2 new tests (expected172). Poll exactly this session; no duplicate run or runtime/source changes during verification. No full pass/commit/push/install yet. All Fox7 plus fitter changes uncommitted; reviewed source coverage56 pending full verification, ledger54, installed9e5ad90.
- Next finish live verification, inspect EN/KO renders, scoped commit/push and deploy-local preserving prior app/store. Then update ledger56/144 and proceed Capybara2; preserve unrelated untracked art/Drive mirror. Goal active.

## Fox final form imported; full verification live — 2026-09-21

- Fox7 Celestial normal/Shiny generated and imported under PersonalityV2/Stage07, four walks/four states each. Longer legs/angular ruff and swept nine tails; ivory/navy/gold normal vs violet/cyan Shiny. First motion needed one added tail and margins correction. Import41630 terminal exit0; exact alpha conservation passed. No commit/push/install yet.
- Review93761 terminal exit0, production decoder108 strips and both96/24px motion/state contacts inspected. AnimationCoverageTests expects all Cat/Dog/Fox authored,108 authored/36 procedural including legacy. Full verify-local en ko LIVE session82694, build/v2-fox-complete-verify.log. Poll this exact session; do not restart on quiet log or observation timeout.
- Visual issue to resolve BEFORE installation: normal7 idle appears smaller than Shiny7 idle. SourceBounds normal idle y21..723 vs Shiny y167..607 despite similar visible figure, indicating very faint alpha extending bounds. Other7 states have similar excess bounds. Inspect rendering/import policy and resolve visible scale consistently without deleting real artwork or relaxing alpha-conservation tests. Do not modify runtime assets while current full verification runs; validate correction afterward.
- Source/application coverage56/144 pending verification, ledger intentionally stays verified54. Installed9e5ad90 unchanged, no remote CI. Preserve unrelated untracked artwork/Drive mirror. Goal active. Next finish live test, fix scale issue, reverify then scoped commit/push and safe deploy complete Fox batch.

## Fox stage six connected and verified — 2026-09-21

- Built-in generation produced Nine-Tailed Fox normal/Shiny four-phase walks and four states under PersonalityV2/Stage06. White/silver with teal tips normal, lavender/plum with violet tips Shiny. Tail-count errors required focused edits before import; nine fan tips reviewed at source scale, closed sleeping eye and tongue-out ready preserved. Exact alpha conservation passed.
- Seven artwork/animation tests passed in7.044s (build/fox6-tests.log), Universal2 build/isolated smoke passed (build/fox6-build.log). Production review106 strips and both96/24px motion/state contacts inspected. Session68063 terminal exit0. No full suite/remote CI for this slice.
- V2 coverage54/144,216 states/216 phases; legacy-plus-new106 authored/38 procedural. Installed checkpoint9e5ad90 unchanged. Preserve unrelated untracked artwork/Drive mirror; goal active.
- Next Fox7 Celestial Fox: distinguish from6 by taller mature body, angular layered ruff and swept flowing nine-tail silhouette, not palette alone; retain restrained deadpan face and coarse flat pixel style. Then full Fox verification and safe deploy.

## Fox stage five connected and verified — 2026-09-21

- Built-in generation produced Snow Fox normal/Shiny four-phase walks and four states under PersonalityV2/Stage05. First motion was too close to lean predecessor and regenerated: short rounded ears, compact deep torso, thick ruff, stout paws and curved tail. White/blue-gray normal, peach-ivory/lavender Shiny; deadpan grin and tongue-out ready preserve playful character. Closed sleeping eye reviewed. Exact alpha conservation passed.
- Seven artwork/animation tests passed in7.153s (build/fox5-tests.log), Universal2 build/isolated smoke passed (build/fox5-build.log). Production review104 strips and both96/24px motion/state contacts inspected. Session45103 terminal exit0. No full suite/remote CI for this slice.
- V2 coverage52/144,208 states/208 phases; legacy-plus-new104 authored/40 procedural. Installed checkpoint9e5ad90 unchanged. Preserve unrelated untracked artwork/Drive mirror; goal active.
- Next Fox6 Nine-Tailed Fox: original mature fox silhouette with nine clearly separable tail tips, coarse flat pixel style and restrained goofy expression. Then distinct Fox7, full Fox verification and safe deploy.

## Fox stage four connected and verified — 2026-09-21

- Built-in image generation produced Qiu's Fox normal/Shiny four-phase walks and four states under PersonalityV2/Stage04. Tawny-gray saddle normal and dusty rose/plum Shiny, narrow fox muzzle, smug tilted idle and proud tail-up ready; closed sleeping eyes. Exact alpha conservation passed.
- Seven artwork/animation tests passed in6.495s (build/fox4-tests.log), Universal2 build/isolated smoke passed (build/fox4-build.log). Production review102 strips and both96/24px motion/state contacts inspected. Session73508 terminal exit0. No full suite/remote CI for this slice.
- V2 coverage50/144,200 states/200 phases; legacy-plus-new102 authored/42 procedural. Installed checkpoint9e5ad90 unchanged. Preserve unrelated untracked artwork/Drive mirror; goal active.
- Next Fox5 Snow Fox: compact fluffy outline, shorter rounded ears and icy palette, retaining deadpan B-grade expression; avoid realistic fur. Then Fox6/7, full Fox verification and safe installation.

## Fox stage three connected and verified — 2026-09-21

- Built-in generation produced Silver Fox normal/Shiny four-phase walks and four states under PersonalityV2/Stage03. Narrow muzzle, fuller cheek ruff/large tail, sly half-lidded grin; charcoal silver normal/dusty plum lavender Shiny. First normal sleeping eye was open and corrected before import. Exact alpha conservation passed.
- Seven artwork/animation tests passed in6.494s (build/fox3-tests.log), Universal2 build/isolated smoke passed (build/fox3-build.log). Production review100 strips and both96/24px motion/state contacts inspected. Session41974 terminal exit0; no full suite/remote CI for this slice.
- V2 coverage48/144,192 states/192 phases; legacy-plus-new100 authored/44 procedural. Installed checkpoint9e5ad90 unchanged. Preserve unrelated untracked artwork/Drive mirror; goal active.
- Next Fox4 Qiu's Fox: keep recognizable fox anatomy and coarse playful style, introduce stronger mature proportions/tawny-gray coat without sudden realistic fur. Continue full Fox batch then verify/deploy.

## Fox stage two connected and verified — 2026-09-21

- Built-in generation produced Red Fox normal/Shiny four-phase walks and four states under PersonalityV2/Stage02. Longer slim body/legs and horizontal tail distinguish adolescent from upright-tail baby; huge ears/dot eyes/head tilt and playful crouch preserve goofy charm. Vermilion normal/lilac Shiny. Exact alpha conservation passed.
- Seven artwork/animation tests passed in6.846s (build/fox2-tests.log), Universal2 build/isolated smoke passed (build/fox2-build.log). Review98 strips and normal/Shiny96/24px plus all state contacts inspected. Session96432 terminal exit0. No full suite/remote CI for this slice.
- V2 coverage46/144,184 states/184 phases; legacy-plus-new98 authored/46 procedural. Installed checkpoint9e5ad90 remains unchanged. Preserve unrelated untracked artwork/Drive mirror. Goal active.
- Next Fox3 Silver Fox: fuller silver-charcoal ruff/tail and longer narrow fox muzzle, retain sly goofy face, gradual maturity not realistic fur. Batch rest of Fox line then full verify/deploy.

## Complete Dog line installed — 2026-09-21

- Commit9e5ad90 pushed to origin/main and safely installed; deploy session66331 exit0 (build/v2-dog-complete-deploy.log). Build/isolated smoke passed again and /Applications/EvoBar.app running. Local ad-hoc install only, no public release or remote CI.
- Previous app preserved as EvoBar-20260921-033502.app in system temporary EvoBar-replaced directory. Live store copied to EvoBar-v1.json.before-install-20260921-033502 without inspecting contents. Launch-at-login may need off/on in app to re-register.
- Installed coverage44/144 V2 variants: complete Cat/Dog normal/Shiny plus other babies. Remaining100 variants incomplete. Next independent slice Fox2 Red Fox; keep mischievous early B-grade face and introduce slender fox muzzle/legs with larger tail. Goal remains active.

## Complete Dog line passed full verification — 2026-09-21

- Existing session60336 completed exit0; do not restart. build/v2-dog-complete-verify.log proves170 tests passed in521.992s, EN/KO isolated UI rendering, Universal2 packaging validation and packaged app isolated launch smoke all passed. Local verification only, not remote CI or public release.
- All seven Dog stages normal/Shiny now verified V2; total44/144 variants,176 states/176 phases. Motion96 authored/48 procedural includes legacy; strict144 gate still intentionally off, not full V2 completion.
- Ready for scoped commit/push and deploy-local. Installed checkpoint remains2560ca4 until deployment is confirmed; preserve previous app/store backups and unrelated untracked art. Next after deployment: Fox2. Goal active.

## Complete Dog line imported; full verification running — 2026-09-21

- Dog7 Fenrir normal/Shiny four-phase walks and four states generated with built-in image tool and imported under PersonalityV2/Stage07. Midnight/icy-teal normal and ivory/antique-gold Shiny; layered ruff and fur tail retain restrained deadpan style. Exact alpha conservation passed.
- Production decoder review96 strips completed (session74359 exit0, build/dog7-review.log). Both96/24px motion sheets and all seven-stage state contacts inspected. AnimationCoverageTests now expects all Cat/Dog authored,96 authored/48 procedural legacy-plus-new.
- Full verify-local en ko is LIVE session60336, log build/v2-dog-complete-verify.log. Poll this exact session; do not restart on observation timeout or quiet buffered log. No full-suite pass, commit, push, or deployment yet for Dog7. Prior terminal importer75267 exit0.
- Source/application coverage is44/144 variants,176 states/176 phases, pending full verification. STATUS ledger intentionally remains last verified42. Installed app remains2560ca4. Preserve all unrelated untracked art and Drive mirror.
- Next: finish existing verification, record actual outcome, scoped commit/push then deploy-local preserving old app/store. Only then mark Dog batch installed and proceed to Fox2. Goal remains active; eight other lines still need later forms.

## Dog stage six connected and verified — 2026-09-21

- Built-in generation produced normal/Shiny Epicyon four-phase walking and four states under PersonalityV2/Stage06. Broad dark muzzle mask, small triangular ears, ochre normal/ivory gold Shiny and giant yawn distinguish this form while retaining coarse playful style.
- Initial normal motion failed edge-alpha gate; initial Shiny failed horizontal separation gate. Both regenerated with generous transparent gaps/margins. Gates unchanged; final exact alpha conservation passed. Failed commands terminal; no processes left to restart.
- Seven artwork/animation tests passed in6.201s (build/dog6-tests.log), Universal2 build and isolated launch smoke passed (build/dog6-build.log). Production decoder review94 strips, both96/24px motion and state contacts inspected. Full suite/remote CI not run.
- Coverage42/144 V2 variants,168 states/168 phases; legacy-plus-new94 authored/50 procedural. Installed checkpoint still2560ca4; unrelated artwork and Drive mirror preserved. Goal active.
- Next Dog7 Fenrir: original mature mythic wolf, prominent layered ruff and flowing fur tail, cool indigo/teal normal vs ivory/gold Shiny, restrained deadpan expression rather than sudden realistic style. Then full verification and safe deploy complete Dog batch.

## Dog stage five connected and verified — 2026-09-21

- Built-in generation produced normal/Shiny Dire Wolf four-phase walks and four states under PersonalityV2/Stage05. Thick chest, broad muzzle, small ears, heavy paws, low tail and deadpan tongue-out face distinguish maturity without realistic fur. Normal charcoal slate; Shiny ivory lavender. Exact alpha conservation passed.
- Seven artwork/animation tests passed in5.901s (build/dog5-tests.log). Universal2 build and isolated app smoke passed (build/dog5-build.log). Production decoder review at92 strips and normal/Shiny96/24px motion plus all state contacts inspected. No full suite/remote CI for this slice.
- Coverage40/144 V2 variants,160 states/160 phases; legacy-plus-new92 authored/52 procedural. Installed checkpoint remains2560ca4. Other editor art and Drive mirror untouched. Goal active.
- Next Dog6 Epicyon: robust bone-crushing canid silhouette with broader skull and shorter muzzle, not a bear; ochre coat distinguishes it. Then Dog7 Fenrir, full verification and safe deployment of complete Dog batch.

## Dog stage four connected and verified — 2026-09-21

- Built-in image generation produced Gray Wolf normal/Shiny four-phase motion and four states, stored under PersonalityV2/Stage04. Upright ears, modest ruff, slate/cream normal and ivory/champagne Shiny, earnest comic howl retain coarse playful style without legacy realistic fur. Exact alpha conservation passed.
- Seven artwork/animation tests passed in 6.407s (build/dog4-tests.log). Universal2 build and isolated app smoke passed (build/dog4-build.log). Production decoder review at90 strips and both96/24px motion/state contacts inspected. Full suite and remote CI not run for this slice.
- V2 coverage38/144,152 states/152 phases; legacy-plus-new90 authored/54 procedural. Installed checkpoint remains2560ca4; no new installation claimed. Other editors' untracked art and Drive mirror untouched.
- Next: Dog5 Dire Wolf, a noticeably deeper chest, broader muzzle, heavier paws and dark cool coat, while retaining silly restrained expression. Then6 Epicyon and7 Fenrir; complete Dog batch then full verify and safe deploy. Goal active.

## Dog stage three connected and verified — 2026-09-21

- Normal/Shiny Wolfdog motion and four states imported from PersonalityV2/Stage03. Longer muzzle, partly upright ears, saddle marking and bushy tail distinguish the adolescent form while retaining tongue-out goofy expression. Exact source alpha conservation passed.
- Seven artwork/animation tests passed in 6.135s (build/dog3-tests.log), Universal2 build and isolated launch smoke passed (build/dog3-build.log). Production decoder review passed at 88 strips; both colours inspected at 96/24px and state contacts. Full suite and remote CI not run for this slice.
- V2 coverage36/144,144 states/144 phases; legacy-plus-new88 authored/56 procedural. Installed checkpoint remains2560ca4. Goal active; preserve unrelated untracked art and Drive mirror.
- Next: Dog4 Gray Wolf, gradually mature gray saddle/longer legs/upright ears but keep coarse playful pixel expression, not legacy realistic fur. Complete Dog line then full verify/deploy with backups.

## Dog stage two connected and verified — 2026-09-21

- Generated/imported normal and Shiny Dog stage two under PersonalityV2/Stage02/{Motion,States,ShinyMotion,ShinyStates}/Dog.png with extraction reports. Longer adolescent torso/legs and smaller relative head preserve floppy ears, blank eyes and sideways tongue. Ready pose is a full-body play bow; sleeping eyes closed. Built-in generation, not scripted recolouring.
- Seven artwork/animation tests passed in 5.613s (build/dog2-tests.log), Universal2 build and isolated launch smoke passed (build/dog2-build.log). Production decoder review passed at 86 strips; both colours reviewed at 96/24px and state contacts. Full suite/remote CI not run for this narrow slice.
- V2 coverage34/144,136 states/136 phases; legacy-plus-new86 authored/58 procedural. Installed app still2560ca4; no installation claimed for Dog2. Preserve unrelated untracked art/Drive mirror. Goal active.
- Next: Dog3 Wolfdog, longer muzzle and partly upright ears as gradual transition; retain goofy youthful personality before mature wolf stages. Batch remaining Dog line then full verify/deploy with backups.

## Complete Cat line installed — 2026-09-21

- Commit 2560ca4 pushed to origin/main and installed successfully via deploy-local (session 57491 exit 0, build/v2-cat-complete-deploy.log). /Applications/EvoBar.app running; build and isolated launch smoke passed again. Local ad-hoc installation only, no public release or remote CI.
- Store backup EvoBar-v1.json.before-install-20260921-023935 and previous app EvoBar-20260921-023935.app in the system temporary EvoBar-replaced directory retained. Contents were not inspected. Launch-at-login may need off/on from app settings to re-register the installed bundle.
- Coverage 32/144 V2 variants: every Cat stage normal/Shiny plus all other babies. Remaining 112 variants are not complete. Next independent slice: Dog stage two, using existing baby source as reference; preserve goofy early expression and introduce longer body/legs/muzzle gradually. Goal active.

## Complete Cat line passed full verification — 2026-09-21

- Session 55827 ended successfully (exit 0). build/v2-cat-complete-verify.log: 170 tests passed in 456.807s, EN/KO isolated UI renders, Universal 2 package validation and isolated app launch smoke passed. Local verification only, not remote CI or notarization.
- Stage07 artwork is ready for scoped commit/push and safe deploy-local. All 14 Cat variants have V2 motion and four states; total V2 coverage 32/144, 128 states/128 phases. Legacy-plus-new motion 84 authored/60 procedural; strict full-line gate remains off because other lines remain unfinished.
- Next: record actual commit/install result after deploy; preserve app/store backups. Then Dog stage two. No existing animal records were read for validation. Goal remains active.

## Complete Cat line imported; full verification running — 2026-09-21

- Stage07 normal/Shiny Astral Tiger motion and four state poses generated/imported. Shiny sleeping eye was open in first result and corrected before import. Sources under PersonalityV2/Stage07; alpha extraction passed for all sheets. All Cat stages now connected; source coverage becomes 32/144 variants (128 state portraits/128 phases), pending final full verification. STATUS ledger still reflects last committed 30 until validation checkpoint.
- Production-decoder review at 84 strips completed; both colours inspected at 96/24px plus state contacts. AnimationCoverageTests updated for every Cat stage: 84 legacy-plus-new authored/60 procedural. Strict all-line completion gate remains intentionally off.
- Full verification started once: exec session 55827, log build/v2-cat-complete-verify.log. Poll this exact session; do not start duplicate on timeout. Review session 21855 completed. Not yet claiming full tests/build/smoke, commit/push or installation. Installed app remains b97672b; last pushed commit 4c08afe. Goal active.
- Next: await session 55827 and inspect all stages of its result, update ledger, scoped commit/push Stage07 and records, safe deploy-local with backups if passing. Then continue Dog stage two. Preserve unrelated untracked concepts/Drive mirror; no actual animal data in tests.

## V2 Cat stage six connected — 2026-09-21

- Imported normal/Shiny Smilodon four-phase motion and four state poses under PersonalityV2/Stage06. Saber canines, heavy paws, short tail and ochre spots distinguish it from Tiger; Shiny uses ivory/slate-lavender. First state generation had a cropped evolution-ready bust and was rejected/redrawn as full body. Built-in image generation, no scripted recolouring; all selected sources passed alpha-preserving extraction.
- Seven artwork/animation tests passed in 5.557s (build/cat6-tests.log). Production decoder review passed at 82 strips; normal/Shiny motion at 96/24px and all state contact sheets inspected. Strict completion gate intentionally skipped. Full suite, remote CI and deployment not run for this slice.
- V2 coverage 30/144 variants, 120 states/120 phases. Legacy-plus-new 82 authored/62 procedural. Installed app remains b97672b. Goal active, unrelated untracked concepts and Drive mirror preserved.
- Next: Cat final Astral Tiger. Stage07/Motion/Cat.png is a prepared normal source, not runtime-imported/counted. It passed non-export preflight; layered cheek ruff and tufted tail add silhouette changes, midnight/gold palette remains tiger-like. Finish states and Shiny, then full verification and safe deploy of complete Cat line before continuing other lines.

## V2 Cat stage five connected — 2026-09-21

- Imported normal/Shiny Tiger four-phase motion and four state poses under PersonalityV2/Stage05. Broad shoulders, round ears, long ringed tail and bold stripes distinguish Tiger from Lynx; Shiny is ivory/navy white tiger. Built-in generation, no scripted recolouring. All sources passed alpha-conserving extraction.
- Seven artwork/animation tests passed in 6.179s (build/cat5-tests.log). Production decoder review passed at 80 strips; both colours reviewed at 96/24px plus all state contact sheets. Strict completion gate intentionally skipped; no full suite, remote CI or installation for this slice.
- V2 coverage 28/144 variants, 112 states and 112 phases. Legacy-plus-new motion 80 authored/64 procedural. Installed app remains b97672b. Existing other-editor concepts and Drive mirror preserved; goal active.
- Next: Cat stage six Smilodon. Normal motion source prepared in Stage06/Motion/Cat.png, not runtime-imported or counted. Finish matching states and Shiny, then Astral Tiger stage seven. Run full verification and deploy complete Cat line with save/app backups. Final all-line completion remains far beyond this Cat slice.

## V2 Cat stage four connected — 2026-09-21

- Generated and imported normal/Shiny Lynx four-phase motion and four state portraits under PersonalityV2/Stage04. Tufted ears, cheek ruff, longer legs, spots and bobtail distinguish it from Wildcat while retaining coarse pixels and deadpan character. Built-in image generation, no scripted recolouring; all four sources passed extraction/alpha checks.
- Seven artwork/animation tests passed in 5.798s (build/cat4-tests.log). Production decoder review passed with 78 strips; both colours reviewed at 96/24px and all four state contacts inspected. Strict completion gate still intentionally skipped. No full-suite, remote CI or installation claimed for this slice.
- V2 coverage 26/144 variants, 104 states/104 phases. Legacy-plus-new 78 authored/66 procedural. Installed app remains b97672b. Goal active; preserve unrelated untracked concepts and Drive mirror.
- Next: finish Cat stage five Tiger. A normal motion source is prepared in Stage05/Motion/Cat.png but not runtime-imported or counted complete. First draft had an incorrect bobtail; selected revision has a long ringed tail. Generate matching states and Shiny sheets, import/review/test, then stages six/seven. Batch full verification and deploy after complete Cat line.

## V2 Cat stage three connected — 2026-09-21

- Generated and imported normal/Shiny Wildcat four-phase motion and four state portraits under PersonalityV2/Stage03. Broader muzzle, rearward ringed tail, wildcat stripes and deadpan expression bridge the domestic form toward maturity. Built-in image generation; no scripted recolouring. Initial Shiny motion failed border-alpha validation and was redrawn with larger margins; replacement passed exact pre-resize alpha conservation.
- Seven artwork/animation tests passed in 6.369s (build/cat3-tests.log); full-completion gate remains intentionally skipped. Production decoder review passed at 76 motion strips; normal/Shiny stages 1–3 inspected at 96/24px and normal state contact inspected. Full suite, remote CI and deployment were not run for this slice.
- V2 coverage 24/144 variants, 96 states and 96 phases. Legacy-plus-new coverage is 76 authored/68 procedural; do not confuse this with V2 completion. Installed app remains b97672b, later Cat stages await batch verification/install. Other editors' untracked concepts and Drive mirror untouched.
- Next: Cat stage-four Lynx with tufted ears, short tail and longer legs, retaining coarse pixels and understated B-grade character. Avoid abrupt realistic-fur jump visible in current legacy stages 4–7. Continue remaining lines; goal active.

## V2 Cat stage two normal and Shiny connected — 2026-09-21

- Imported the prepared four Stage02 Cat sheets with explicit `--stage=2`: eight state portraits and eight motion phases. Longer body/legs, taller ears and thinner hooked tail distinguish the house cat from the baby; belly and unimpressed face preserve early B-grade personality. Sources and reports live in `PersonalityV2/Stage02/{Motion,States,ShinyMotion,ShinyStates}`.
- ArtworkCoverageTests/AnimationCoverageTests passed: seven reported tests in 5.669s, strict full-completion gate intentionally skipped. Production-decoder motion review passed with 74 strips; visually compared stages one/two at 96px and 24px in both colours and checked all four state poses. Later Cat stages visible in the contact sheet remain legacy and are not approved V2.
- V2 coverage is 22/144 variants (88 state portraits and 88 motion phases), legacy-plus-new motion count 74 authored/70 procedural. Installed app remains b97672b (complete babies). No full-suite, remote CI or installation is claimed for this narrow stage-two slice. Preserve unrelated concepts and Drive mirror.
- Next: create Cat stage-three Wildcat with broader muzzle/shoulders and recognizable wildcat markings, still visibly related to stage two; gradually introduce maturity without returning to detailed realistic fur. Then continue stage four and later. Batch full verification and deployment after a coherent later-stage set. Goal remains active.

## All V2 babies verified — 2026-09-21

- Commit `b97672b` was pushed and installed successfully with `deploy-local.sh`; `/Applications/EvoBar.app` is running. Its build and isolated smoke passed. Previous app preserved as `EvoBar-20260921-014707.app` in the system temporary `EvoBar-replaced` directory, store backup `EvoBar-v1.json.before-install-20260921-014707`. No live contents were inspected. This is local ad-hoc installation, not public notarized release.
- Session 67831 completed successfully. `build/v2-all-babies-verify.log` records 170 tests passed in 419.254s, EN/KO isolated UI renders, Universal 2 packaging and isolated app launch smoke. Local verification only; remote CI was not dispatched. V2 coverage remains 20/144 variants; all later stages remain unfinished.
- Ready for scoped commit/push and deploy-local of the complete baby set. Stage02 Cat source sheets were prepared while tests ran, but not imported into runtime: normal/Shiny four-phase motion and four state poses, with longer body/legs/ears and hooked tail while keeping the unimpressed belly-heavy style. Built-in generation only; source sheets in `PersonalityV2/Stage02/{Motion,States,ShinyMotion,ShinyStates}/Cat.png`. Both variants passed non-export preflight with `--single-stage --stage=2` (plus `--shiny`); preserve these untracked sources for the next slice.
- Next: record installation outcome, then import/review/test both Cat stage-two variants. Do not count prepared Stage02 sources as completed until runtime checks pass, and do not overwrite the existing baby source paths.

## Personality V2 complete baby sources, verification running — 2026-09-21

- Generated/imported the remaining Shiny babies with built-in image edits: mint Pterosaur, apricot-coral Dragon, violet/cobalt/cyan Phoenix, ivory/gold-spotted Kirin. All retain the normal source anatomy and distinct state/locomotion poses. Source PNGs and extraction JSON reports are in `PersonalityV2/ShinyMotion/` and `ShinyStates/`; no full prompts are saved.
- All four import pairs passed alpha/border/separation checks. ArtworkCoverageTests and AnimationCoverageTests passed (seven reported tests, strict full-completion test intentionally skipped) in 5.829s. Reviewed the state contact sheet and each new variant's actual decoder frames at 96px/24px. Motion review completed with 72 strips; this includes legacy art and is NOT V2 completion.
- V2 source/runtime coverage is 20/144 variants: all ten babies normal/Shiny, 80 portraits and 80 motion phases. All 124 later-stage normal/Shiny variants still need V2 redesign. The motion test now requires dedicated frames for every stage-one variant, not a growing hard-coded subset.
- Full `./Scripts/verify-local.sh en ko > build/v2-all-babies-verify.log 2>&1` started, tool session **67831**. Poll that exact handle or confirm its terminal state before starting another run. No full-suite, packaging or installation success is claimed yet. Current installed source remains 5296817; new four-animal slice is uncommitted pending full verification. Earlier Fox/trio sources are pushed.
- Next: finish this full run, commit/push scoped verified resources, deploy-local with backups, then tackle later stages. Existing concept README explicitly warns that Mammoth/Phoenix/Pterosaur sheets are not directly importable; preserve but refine those anatomy/transition issues, do not blindly import them. Drive mirror and earlier untracked concepts remain untouched. Goal stays active.

## Personality V2 Shiny Capybara, Raptor and Mammoth — 2026-09-21

- Built-in image edits produced three dedicated stage-one Shiny pairs, preserving the approved normal anatomy/poses: strawberry-pink Capybara, sky-blue Raptor, ivory/gray-lilac Mammoth. Sources and extraction reports are in `PersonalityV2/ShinyMotion/` and `ShinyStates/`; full generation prompts are not stored. Twelve state portraits and twelve authored motion phases were imported, with no live save or progression changes.
- Both importers passed border/body-separation/source-alpha checks for all three. Final ArtworkCoverageTests and AnimationCoverageTests passed (seven reported tests, including the intentionally skipped strict completion gate) in 5.667s. Production-decoder contact sheets were reviewed at 24px/96px for each new motion variant, plus the state contact sheet. Log: `build/shiny-baby-trio-tests.log`; motion review expected 71 strips.
- V2 coverage is 16/144 variants, 64 state portraits and 64 motion phases. Legacy-plus-new authored motion is 71/144: Raptor replaced an existing legacy strip, while Capybara and Mammoth gained authored strips. Later Raptor stages in the review remain legacy and do NOT count as approved V2.
- Installed app remains 5296817; this slice and Fox are not yet installed. No full-suite/remote-CI/packaging claim for these narrow art checkpoints. Next: Pterosaur, Dragon, Phoenix and Kirin Shiny babies, then full local verification and safe deployment before continuing later stages. Preserve Drive mirror and earlier untracked concepts. Goal remains active.

## Personality V2 Shiny Fox — 2026-09-21

- Imported the prepared lavender/ivory Fox stage-one Shiny source sheets: four authored walk phases and idle/working/evolutionReady/sleeping portraits. Both importers passed transparent-border, body-separation and source-alpha conservation checks. State portraits use the corrected 400px packaging limit.
- ArtworkCoverageTests and AnimationCoverageTests passed: seven reported tests, including the intentionally skipped strict 144-motion completion gate. The production-decoder motion reviewer processed 69 strips in 17 groups; Fox's four frames were visually checked at 96px desktop and 24px menu sizes, plus the state contact sheet. No full-suite or remote CI is claimed for this slice.
- V2 coverage is 13/144 variants (52 state portraits and 52 motion phases). The legacy-plus-new motion count is 69 authored / 75 procedural; these numbers do not imply V2 completion. Installed app remains 5296817, so Fox is not yet installed. Preserve earlier untracked concepts and Drive mirror.
- Next: create and import Shiny Capybara, Raptor, Mammoth, Pterosaur, Dragon, Phoenix and Kirin baby sets; then later normal/Shiny stages with gradual species-specific maturity. Batch the next full local verification and installation after the remaining baby set, rather than treating this narrow art test as full app acceptance. Goal stays active.

## Personality V2 packaging correction — 2026-09-21

- Full local validation exposed oversized V2 state portraits that the earlier narrow animation tests did not cover. Kept the 400px artwork limit: the importer now scales the complete extracted body with nearest-neighbour sampling, then restores a 12px transparent gutter. Integer sizing avoids a 401px floating-point rounding edge case. Repacked 48 normal/Shiny baby state portraits; source sheets remain unchanged.
- Final targeted ArtworkCoverageTests and AnimationCoverageTests passed (seven reported tests, including the intentionally skipped full-completion gate). Normal baby and Shiny Cat/Dog contact sheets were visually reviewed after repacking. Full `verify-local.sh en ko` passed: 170 reported tests in 399.122 seconds, isolated English/Korean rendering, Universal 2 packaging and isolated launch smoke. Log: `build/personality-v2-verify-fixed.log`. This is local verification, not remote CI. Installation follows this checkpoint.
- Both importers now accept `--single-stage --stage=N`, with catalog bounds and duplicate/invalid flag rejection. Isolated temporary export verified Dog stage-two state filenames and Shiny motion routing without overwriting production stage-two art. The temporary input was existing authored art used only to test routing, not a new approved evolution form.
- Prepared lavender Shiny Fox source sheets using built-in image edits preserving the approved baby anatomy and poses. `ShinyMotion/Fox.png` and `ShinyStates/Fox.png` passed preflight but are NOT exported to runtime or counted as completed V2 coverage yet. Next: finish the packaging checkpoint and local installation, then import/review/test Fox and the remaining seven Shiny babies before later stages.
- Packaging fix `5296817` was pushed and installed through `deploy-local.sh`; its build and isolated launch smoke passed and `/Applications/EvoBar.app` is running. Previous app is preserved as `EvoBar-20260921-011100.app` in the system temporary `EvoBar-replaced` directory; the existing store was backed up as `EvoBar-v1.json.before-install-20260921-011100` without reading its contents. This is an ad-hoc local installation, not a notarized release.
- Goal remains active. Drive mirror, earlier untracked concepts and live records were not used as fixtures. No remote CI, public release, or payment operation was run. Fox source PNGs remain untracked pending the next validated import; preserve them. Completed V2 runtime coverage remains 12/144 variants, not the 68/144 legacy-plus-new authored-motion count.

## Personality V2 Shiny Dog — 2026-09-21

- Added honey-gold/ivory Dog stage-one Shiny motion and four state portraits matching the approved floppy-eared puppy. Built-in image edits only; source sheets and exact-alpha extraction reports are under `PersonalityV2/ShinyMotion/Dog.*` and `ShinyStates/Dog.*`.
- Both importers passed, no border clipping or overlapping motion bodies. AnimationCoverageTests passed: three active tests plus the intentionally skipped strict-completion gate. Exact Shiny Dog motion is required; coverage is now 68 authored / 76 procedural variants. No full-suite, CI or local installation claimed for this checkpoint.
- Next: remaining eight baby Shiny sets, then all later-stage V2 normal/Shiny silhouettes and states. Goal remains active for the full scope; installed app is still e119605. Preserve untracked earlier concepts and Drive mirror.

## Personality V2 Shiny Cat — 2026-09-21

- Added silver-blue normal-design-matched Cat stage-one Shiny motion (four authored phases) and four state portraits. Built-in image edits preserve the approved fat silhouette and expressions; extraction preserves alpha. Sources and reports: `Artwork/Sources/PersonalityV2/ShinyMotion/Cat.*` and `ShinyStates/Cat.*`.
- Coverage now requires `cat.1.shiny` motion explicitly: 67 authored / 77 procedural variants. Local AnimationCoverageTests passed (three active tests, one intentionally skipped strict completion test; runner reports four). No full-suite, remote CI or installation is claimed for this slice.
- Remaining: other nine baby Shiny sets, all later-stage V2 normal/Shiny sets, final full validation and local deployment. Installed version remains e119605. Goal is active; do not mistake existing legacy assets for completed V2 redesigns.

## Personality V2 normal baby states — 2026-09-21

- Goal remains active for all 72 forms and 144 colour variants, motion and all four states. This checkpoint completes only the 40 normal stage-one state portraits, matching the already installed motion identities.
- Sources/extraction reports are in `Artwork/Sources/PersonalityV2/States/`. The state importer supports a four-state horizontal single-stage sheet, rejects opaque/clipped sources and overlapping bodies, and conserves source alpha. Review script now produces ten-by-four baby-state contact sheets.
- Local manifest/animation targeted run passed (10 reported tests); the subsequent coverage run passed (4 reported, including the intentionally skipped full-144-motion gate). The new active test checks all 40 normal baby portraits for distinctness and transparent gutters. Full completion gate is still unmet and must remain so until all variants genuinely exist.
- Current installed app is still the earlier motion checkpoint e119605; this state-art slice has not yet been locally deployed or run through remote CI. Next: dedicated baby Shiny motion/states, then all later-stage lines with gradual silhouette changes. Preserve untracked older concepts and Drive mirror.

## Personality V2 runtime checkpoint — 2026-09-21

- User approved the B-grade baby direction and requested actual application. Nine normal stage-one motion strips were generated and imported; the previously approved Cat walk is retained. Ten normal babies now have dedicated four-phase animation, with no changes to saved companions or progression.
- Source strips and extraction evidence: `Artwork/Sources/PersonalityV2/Motion/`. The coverage test now requires every normal stage-one form to have dedicated motion: 66 authored / 78 procedural variants across 144 variants.
- Superseded untracked Dog/Capybara/Mammoth motion experiments were moved outside bundled resources to `Artwork/Sources/ExpressiveV1/SupersededRuntime/`. Earlier uncommitted Pterosaur experiments were preserved there before restoring their tracked baseline; only its new stage-one strip is changed now. Drive mirror and unrelated working files were preserved.
- Source alpha conservation, distinct frames and gutters passed; the renderer reviewed 66 strips in 14 groups (42 light/dark/GIF outputs). The targeted 12-test run and full `Scripts/check.sh` run passed (169 tests, 345.889 seconds for tests). Local packaging/installation status follows below when completed. No remote CI has been run for this slice.
- This is NOT completion of all artwork. Later stages, Shiny, sleeping/static/collection portraits still need the approved redesign. Next bounded slice: consistent stage-one static and sleeping poses, then gradual stage-two-to-final silhouettes and dedicated Shiny motion. Do not reimport superseded always-cute full-line experiments or replace missing poses with duplicate walk frames.
- The recurring automation remains paused. No public release, signing-account changes, paid services or user-log/save fixtures were used.
- Local deployment completed: Universal 2 build and isolated smoke passed; `/Applications/EvoBar.app` launched. Previous app preserved as `EvoBar-20260921-002214.app` under the system temporary `EvoBar-replaced` directory; the existing deploy procedure backed up the live store without reading its contents. This is an ad-hoc local build, not a notarized public release.

This note preserves the current implementation boundary and restart position as of 2026-09-20, with older checkpoints retained as history. Read the newest checkpoint first. Product decisions and visual evidence remain in [[SPEC]] and [[UX_REVIEW]].

## Stabilization checkpoint and feedback pause — 2026-09-20, 09:03 KST

- Clean source `6162e2a` remains pushed and installed. The latest full169-test/EN-KO/native/package/smoke verification and backup are recorded below. No new build or release was performed in this checkpoint; Drive mirror and live records remain untouched. Allowance79% weekly remaining, secondary unavailable: this is not a quota pause, and no reset credit was used.
- The last proposed tracking audit is already covered: `TrackingConnectionView` prioritizes disabled tracking over report state, displays distinct paused/history-kept and no-logs messages, and offers the existing Tracking settings action. The latest Korean paused and connected/missing-provider native artifacts were inspected in the preceding heartbeat; no new defect or code change was found. Do not repeat those tests merely to create another slice.
- The identified naming, switch/hatch/placement recovery, ready/error visibility, scroll reachability and duplicate first-session card fixes are complete within their recorded scopes. No further concrete, non-duplicative change was identified in this stabilization audit. This is not a claim that the whole app is bug-free, accessible or release-ready.
- Paused heartbeat `evobar` through the app automation tool under its explicit stop condition; existing prompt/schedule/target were preserved. Avoid manufacturing extra features or endlessly extending the same fixtures. Resume with a concrete observed defect or a small acceptance target supported by user feedback.
- Next useful input: whether the installed Home still feels crowded, whether the next growth/hatch action is understandable, and whether the pace is enjoyable in ordinary work. Genuine keyboard traversal/VoiceOver and physical-display checks remain unaccepted; the earlier Tab attempt did not establish focus behavior. Public distribution/signing and live payments require separate authorization and remain excluded. Preserve current growth thresholds and development unlock until a specific change is approved.

## Single first-session egg card — 2026-09-20

- Continued from clean `943a21b`,82% weekly allowance remaining, secondary unavailable. Rendered the existing isolated persisted pre-usage candy/held-egg state with expanded Details. The initial English image showed two Incubator/Place an egg cards, confirming the source suspicion. Baseline image: `build/first-session-duplicate-before-20260920.png`; baseline render log `build/first-session-duplicate-before-20260920.log`.
- Gated the inner Details prompt to recorded-usage mode; first-session guidance retains its existing outer card. The production change is one condition, not a new feature or a change to growth, inventory, art or saves. Added the first-session image to required native artifacts, using the actual temporary store/model and asserting rendering does not mutate its animals or held eggs.
- Final `Scripts/verify-local.sh en ko` passed:169 tests in339.028s, EN/KO native model checks/renders, Universal2 packaging, resource/signature/ZIP checks and isolated packaged launch. Log `build/first-session-card-final-20260920.log`. Final EN/KO first-session images were visually inspected: exactly one incubator card remains outside expanded Details, with first-session guidance intact. This is local evidence, not remote CI or physical keyboard/VoiceOver acceptance.
- Installed and running from Applications via `deploy-local.sh`; store backup `EvoBar-v1.json.before-install-20260920-080053`, previous app retained under temporary `EvoBar-replaced/EvoBar-20260920-080053.app`. Log `build/first-session-card-install-20260920.log`. No live records used as tests, raw logs, Drive mirror edits, credits or paid services. This remains an ad-hoc local app, not a notarized public release.
- After this slice, stop revisiting the completed incubator card cases. A useful remaining check is whether the existing first-session tracking guidance distinguishes paused tracking from missing logs without requiring a new settings surface; inspect prior coverage first.

## First-session state reachability — 2026-09-20, 07:13 KST

- Continued from clean `f2953f5`, weekly allowance82% remaining, secondary unavailable. Source audit found `hasRecordedUsage` examines all individuals' cumulative tokens, not only today's usage/current animal. Ordinary switching or days away therefore does not by itself enter the first-session branch; do not simulate it by clearing real history.
- A valid exception exists in the owner's current development storefront: a free growth item before any logs. Extended the disposable placement fixture with a fixed-roll candy purchase and explicit `!hasRecordedUsage && pendingXP > 0` assertion. Both fail/retry record-equality checks now also preserve pending item growth. No artificial usage or user record is involved; this does not justify changing the free-item configuration.
- `Scripts/review-ui.sh en ko` passed with the final DEBUG change, log `build/first-session-state-audit-20260920.log`. No production code, balance, artwork or installation changed. Installed source remains `596723d`. No new full unit/package/remote CI result claimed; no credits, paid services or Drive mirror edits.
- Remaining narrow UI check: render that verified no-usage/pending-growth state with a held egg and expanded Details. Source currently places the routine prompt inside the companion card and again in the first-session branch; visual duplication is not yet directly verified. If reproduced, gate the inner prompt to recorded-usage mode while keeping first-session guidance outside. Do not repeat the completed reachability/store checks or invent a migrated state.

## Placement retry lifecycle — 2026-09-20, 06:39 KST

- Continued from clean `596723d`, with83% weekly allowance remaining and no secondary window reported. Extended the existing DEBUG recovery review with its own temporary placement save. It starts with two ordinary eggs so a duplicate call cannot be masked by depleted stock. A forced write failure releases the busy state, preserves both eggs/animals, exposes the localized error and marks the incubator as needing attention.
- After restoring that temporary save destination, retry plus an immediate duplicate call places exactly one warming egg, leaves one held egg, preserves the companions, clears the error and returns `incubatorNeedsAttention` to false. A separate store reopen verifies persistence. No actual user data, log, setting or production behavior was changed.
- `Scripts/review-ui.sh en ko` passed with the new model check and existing native checks/renders for both locales; log `build/placement-recovery-native-20260920.log`. This is not client-driven interaction, VoiceOver or remote CI evidence. No new full unit/package run or reinstall was needed for the DEBUG-only change; installed production source remains `596723d`. No credits, paid services, artwork or Drive mirror edits.
- Next bounded audit: inspect the no-recorded-usage Home branch with an already-grown/resting companion and expanded Details for duplicate incubator cards. Existing held/warming/error and transaction tests above should not be repeated. Only change the UI if a valid synthetic scenario demonstrates duplication; do not add another system.

## Placement error visibility — 2026-09-20

- Continued from clean `42ffb37`. Korean isolated reproduction showed that a placement error with a held egg/no ready egg appeared only after opening Details & care. `incubatorNeedsAttention` now keeps either an error or a ready egg outside that disclosure, with its inverse used inside so the card is not duplicated. No error means routine held/warming eggs remain tucked away. No new UI destination, game rule, artwork or schema.
- Added a compact interactive placement-error scenario and native held/warming error images, plus model guards for ordinary/error/cleared/ready states. Final Korean interaction confirmed the message and action outside collapsed Details, scroll reachability, and no duplicate after expanding. Fixtures were closed and cleaned up; no actual placement or live record was used.
- Final `Scripts/verify-local.sh en ko` passed:169 tests in341.806s, EN/KO native state checks/renders, Universal2 packaging, signature/resources/ZIP and isolated packaged launch. Log `build/placement-feedback-final-20260920.log`. English held-error and Korean warming-error images were visually inspected; the Korean compact interaction was also checked. This is local evidence, not remote CI. Weekly allowance85% remaining at start and84% at verification boundary, secondary unavailable; no credits or paid CI. Drive mirror untouched.
- Installed and running from Applications through `deploy-local.sh`; store backup `EvoBar-v1.json.before-install-20260920-060829`, previous app retained under temporary `EvoBar-replaced/EvoBar-20260920-060829.app`. Log `build/placement-feedback-install-20260920.log`. No live game action used for tests. This remains an ad-hoc local app, not a notarized public release.
- Next small audit after verification: review error clearing on a successful placement through an isolated AppModel save/retry fixture, without adding new mechanics or duplicating the existing store rollback tests. Keyboard/VoiceOver acceptance remains separate.

## Compact failed-egg scroll acceptance — 2026-09-20, 05:22 KST

- Continued from clean `1b905ac`, weekly allowance86% remaining, secondary unavailable. Added a DEBUG-only `compact-hatch-error` interactive screen at328x374 with the existing synthetic ready-egg presentation and injected localized error. The ordinary interactive scenarios, live visibility guards, production layout and monitor settings are unchanged.
- Final DEBUG build passed; Korean client scrolling and screenshots confirmed full error/button reachability above the footer with Details & care both collapsed and expanded. `bash -n` and `git diff --check` passed. Fixture cleanup completed. A Tab attempt did not move focus; no physical keyboard or VoiceOver pass is claimed, and no OS setting was changed. See [[INTERACTIVE_UI_REVIEW]].
- No production change or reinstall. Installed source remains `92380e0`; no new full suite, native export, packaging or remote CI run is claimed for this isolated harness addition. No live data, artwork, Drive mirror, credits or paid-service changes.
- Next independent audit: check whether an ordinary egg *placement* failure, with no ready egg, remains discoverable when Details & care is collapsed. Opening-failure visibility and transaction checks above are complete; do not repeat them or add a new mechanic. Physical keyboard/VoiceOver acceptance needs a genuine supported interaction setup, not inference from screenshots.

## Hatch failure layout fixtures — 2026-09-20, 04:45 KST

- Continued from clean `08aca74`, with87% weekly allowance remaining and secondary unavailable. Added a render callback to the existing DEBUG hatch recovery regression, capturing its actual forced-save failure before retry. Panel visibility is temporarily false only during rendering so Home cannot absorb synthetic pending growth; the original animals/egg are asserted unchanged afterwards and visibility is restored for retry. Production guards and UI are unchanged.
- Added required, decoded images for compact328x374 Home,328x600 Home and a328x160 standalone IncubatorPrompt. Final `Scripts/review-ui.sh en ko fr` passed, including model recovery checks and all required native images; log `build/hatch-error-layout-final-20260920.log`. The earlier run before the full-home/card additions is not the final acceptance run. Visually inspected the full English Home and EN/KO/FR cards: localized error and retry button are complete and do not overlap.
- Important limitation: in the374-point-high Home, the egg card begins below the initial viewport and needs scrolling. The card/full-height render does not prove scroll or keyboard reachability in that viewport. No production defect or complete compact interaction acceptance is claimed. Next bounded check is isolated scroll/keyboard reachability of this existing failed-egg card, without using real records or broadening the product.
- DEBUG verification and script changes only; installed production source remains `92380e0`, no reinstall required. No full unit/package rerun or remote CI run claimed. No new art, live records, Drive mirror edits, credits or paid services.

## AppModel hatch recovery regression — 2026-09-20, 04:10 KST

- Continued from clean `48998b8`; weekly allowance87% remaining, secondary unavailable. Added DEBUG-only `HatchRecoveryReview`, invoked by the existing native review exporter. It creates its own temporary persisted ready egg with synthetic usage and explicitly sets panel visibility; it does not reuse presentation-only IDs or weaken runtime guards.
- The regression forces a save failure and checks busy-state release, localized feedback, preserved animals/egg/current companion, and no ceremony/discovery. Retry plus an immediate duplicate call creates one waiting individual, preserves the original, and proves the result is on disk while the ceremony is still active. Early acknowledgement is ignored; after the ceremony the discovery remains until acknowledged. A consumed egg cannot start another ceremony or create another individual.
- `Scripts/review-ui.sh en ko` passed after the final source edit, including this regression and existing native model checks/renders for both locales. Log: `build/hatch-recovery-native-20260920.log`. This is AppModel/native local evidence, not an interactive keyboard/VoiceOver test or new remote CI run. No full169-test/package rerun is claimed; only DEBUG review code changed, so installed release source remains `92380e0` and no reinstall was needed.
- No production feature, schema, artwork, live data, Drive mirror or payment change. Temporary test stores are cleaned up. Next bounded gap: inspect/render the existing compact Home error message for failed egg opening; this regression validates state and localized text but not the error's visual placement. Avoid duplicating the now-covered transaction/ceremony assertions or adding new mechanics.

## Hatch rollback assertions — 2026-09-20, 03:36 KST

- Continued from clean `ad706c4`, with88% weekly allowance remaining and no secondary window reported. Existing disk tests already force hatch-save failure/retry; strengthened `readyEggWaitsAcrossRelaunchAndHatchIsPermanent` to compare complete preexisting animal records, active selection, inventory, coins and pending XP after failure, verify exactly one added individual on retry, and check rejected replay plus a further disk reopen. Only tests/documentation changed; no production or art edit.
- Focused test passed (1 test,0.046s), followed by all35 persistence tests (0.322s). Logs: `build/hatch-preservation-20260920.log` and `build/hatch-persistence-suite-20260920.log`. No new full169-test/native/package run or remote CI is claimed. Installed source remains `92380e0`; no reinstall was needed. No credits, paid services, real game data or Drive mirror edits.
- Interactive Open egg did nothing in both fixture destinations: the review window does not set `isPanelVisible`, a required AppModel guard. Do not claim this as a failed production flow or a passing error/retry test. Fixture cleanup passed. [[INTERACTIVE_UI_REVIEW]] records this limitation.
- Next scoped option: add a DEBUG AppModel regression with its own persisted ready egg, explicit panel visibility and controlled save failure, following the existing CompanionSwitchReview approach. Check busy-state release, absent ceremony/discovery on failure, then successful retry and acknowledgement. Do not simply enable presentation-only hatch IDs or weaken live guards; no new mechanic is needed.

## Ready egg visibility acceptance — 2026-09-20, 03:03 KST

- Continued from clean `00c7f90`; weekly allowance88% remaining, secondary unavailable. Korean isolated interaction verified that Home's ready-egg action survives expanding/collapsing Details & care, Collection navigation, opening the waiting Fox detail and Escape dismissal. The same ready egg identifier remained at100% in Collection; returning Home kept the action visible outside the collapsed disclosure. No egg was consumed and the current companion stayed Mochi. See [[INTERACTIVE_UI_REVIEW]].
- No bug found: documentation-only, no reinstallation or repeat full pipeline. Installed source remains `92380e0` with its prior169-test/native/package verification; no new remote CI run is claimed. Fixture cleanup passed. Drive mirror, real records and artwork remain untouched; no credits or paid services used.
- Next bounded check: inspect existing synthetic hatch/save-failure coverage before considering an isolated interactive Open egg failure/retry check. The presentation-only incubator IDs are not stored eggs, so do not mistake a fixture failure for a production defect or claim a successful hatch from this visibility walkthrough. Keep the same small product scope.

## Onboarding navigation acceptance — 2026-09-20, 02:31 KST

- Continued from clean `92380e0`; weekly allowance89% remaining, secondary unavailable. Confirmed the previously unfinished Korean onboarding Back/Continue check with isolated fixtures: the Korean name, Dog selection,5/24 counter and enabled Start survived both a provider-step round trip and a full return through Welcome. See [[INTERACTIVE_UI_REVIEW]]. The fixture closed with successful cleanup; no live state or log was used.
- Documentation-only checkpoint. No bug found, no production edit, no reinstallation or repeated full test pipeline. Installed source remains `92380e0`, with its earlier169-test/EN-KO/package/smoke pass. No new remote CI run, credits or paid service used; Drive mirror preserved.
- Next bounded acceptance check: in the existing isolated Collection/Home fixture, verify that collapsing Details & care does not hide an already-ready egg action and that opening/dismissing the relevant detail preserves the visible ready state. Inspect existing evidence first; do not add a new mechanic or claim physical assistive-technology acceptance from the accessibility tree.

## Onboarding/graduation native naming — 2026-09-20

- Continued from clean `a97970b`. Reproduced the native32-character display versus24-character binding mismatch in both remaining naming screens using isolated Korean fixtures. Replaced the truncating custom binding with post-edit length correction; stored records, schema, game rules, artwork and entitlements are unchanged.
- Added an opt-in screen selector to the DEBUG interactive tool so these inputs can be reproduced directly. Final-source Korean checks passed long-paste display, spaces-only disabled submission and valid Korean paste in both screens. Onboarding counters matched the displayed values. No actual onboarding/graduation transaction, physical IME or VoiceOver acceptance is claimed; see [[INTERACTIVE_UI_REVIEW]].
- Final-source `Scripts/verify-local.sh en ko` passed: all169 tests in342.852 seconds, EN/KO native checks/renders, Universal2 packaging, resources/signature/ZIP verification and isolated packaged launch. Log: `build/onboarding-naming-final-20260920.log`. This is local evidence, not a remote CI run. Weekly allowance was91% remaining at start and89% before verification; secondary unavailable. No reset credits, paid CI, live-data tests or Drive mirror edits.
- Installed and running from Applications through `deploy-local.sh`; store backup `EvoBar-v1.json.before-install-20260920-020021`, previous app retained in temporary `EvoBar-replaced/EvoBar-20260920-020021.app`. Log: `build/onboarding-naming-install-20260920.log`. This remains an ad-hoc local install, not a notarized public release. Onboarding fixture expired normally; graduation fixture was closed and its cleanup completed.
- Next small check: isolated onboarding Back/Continue navigation should retain the draft; the current walkthrough timed out before confirming that return. Do not add another feature or repeat completed length/blank-name fixes.

## Saved-game pacing walkthrough — 2026-09-20

- Continued from clean `4404d73`, with93% weekly allowance remaining and no reported secondary window. Added a parameterized persistence regression for250k/500k/1M/5M/20M raw tokens per active day. It reloads a temporary save each day, absorbs growth with fixed no-bonus/minimum-coin rolls, purchases only the ordinary egg with `chargeCoins: true`, places it after usage, and checks duplicate replay and three-day incubation. The chosen hatch is another owned starter, not a claim about random species odds.
- `Scripts/check.sh` passed all169 tests in344.996 seconds; log: `build/pacing-check-20260920.log`. The five walkthroughs observed first evolution on active day2/1/1/1/1, purchased egg on10/6/4/2/1 and deliberate hatch on13/9/7/5/4. [[GAMEPLAY_PACING]] records the assumptions and next choice without claiming expected user retention, calendar-day guarantees or random species coverage.
- Only tests/documentation changed. No production source, art, manifest, unlock, stored user data or installation changed, so no UI/package rerun or reinstallation was needed; installed source remains `4404d73`. This is local test evidence, not remote CI. No paid CI or reset credit used; Drive mirror preserved.
- Next bounded check: inspect the existing onboarding/graduation name fields for the native text-display mismatch found in Collection, using isolated fixtures before making any change. Do not rebalance the live game from these deterministic scenarios alone; feedback is needed to judge enjoyment.

## Native naming retry — 2026-09-20

- Continued from clean `36aaa2e`. The existing isolated interactive scenario now includes a waiting individual. Actual Korean client interaction reproduced an empty-looking repeated name alert with a nonempty draft, plus a long paste whose native display differed from the24-character binding. Fresh per-presentation field identity and post-edit length correction fix both without changing stored records, growth, ownership, art or UI destinations.
- The final input implementation passed the isolated Korean walkthrough for whitespace rejection,24-character paste display, valid Korean paste, failed switch retaining the detail, and name preservation on retry and cancel/reopen. [[INTERACTIVE_UI_REVIEW]] records the exact scope and the rejected key-synthesis attempt. This is not physical IME or VoiceOver acceptance. The temporary apps cleaned up; no live game actions or raw logs were used.
- Final-source `Scripts/verify-local.sh en ko` passed: all168 tests in343.722 seconds, EN/KO native model checks/renders, Universal2 packaging, resources/signature/ZIP checks and isolated packaged launch. Output: `build/naming-final-20260920.log`. This is local verification, not a GitHub CI run. Allowance was96% weekly remaining at start and94% at verification; secondary unavailable, no credits used. The Drive mirror remained untouched.
- Installed and running from Applications through `deploy-local.sh`. Store backup: `EvoBar-v1.json.before-install-20260920-003217`; previous app retained in temporary `EvoBar-replaced/EvoBar-20260920-003217.app`. Installation log: `build/naming-install-20260920.log`. No real game action was used for testing. The app remains an ad-hoc development install, not a notarized public release.
- Next bounded follow-up after this slice: synthetic first-session pacing at the five rates already listed in [[GAMEPLAY_PACING]], without changing the manifests or development unlock. Do not repeat the completed naming/collection checks or add another game system.

## Interactive acceptance follow-up — 2026-09-19, 23:43 KST

- Clean `a65af19` was already pushed and installed; no production code change or reinstall in this follow-up. Live allowance was97% weekly remaining, with the secondary window unavailable. No credits or paid CI used.
- The Korean isolated UI fixture now passed out-of-process interaction for a missing-individual switch failure: detail stays open, dismissing the message preserves the sheet, retry then Escape returns to Collection with the failure visible, dismissing it preserves the individuals, and Command-F/search/detail/Escape preserves the filter and resting record. [[INTERACTIVE_UI_REVIEW]] distinguishes this from physical keyboard, VoiceOver and successful persistence tests. The temporary fixture app and state were confirmed cleaned up; the live app/store and Drive mirror stayed untouched.
- Corrected the obsolete incomplete-Shiny statement in [[GAMEPLAY_PLAN]] to match the completed hybrid art delivery, avoiding duplicate generation. This checkpoint changes documentation only; prior full168-test/package acceptance still applies to the unchanged app. Next bounded check is the waiting-companion name alert with a dedicated isolated fixture; do not claim it was covered by the resting-companion test or introduce another game feature.

## Companion-switch recovery — 2026-09-19

- The owner asked to wrap up the current work and deploy, not expand scope. This slice keeps the Collection detail open until a companion switch saves successfully. Failed switches show dismissible feedback in both the detail and Collection; retrying the same waiting individual preserves the entered name. Whitespace-only name submission is disabled. The default Home, artwork, progression, entitlements and persisted schema are unchanged.
- A DEBUG-only native regression uses its own temporary save and synthetic usage. It checks invalid names, a forced save failure, no premature success/dismissal, duplicate-click coalescing, successful retry, disk reopen, pending growth preservation and returning to the original companion. The first fixture had not actually absorbed growth, so it was corrected to represent a raised/resting individual; no production invariant or assertion was weakened.
- Preliminary EN/KO/FR native checks passed. Inspection found Collection content showing through its new footer; the footer now has an opaque background. Final-source `Scripts/verify-local.sh en ko` passed: all168 tests in341.947 seconds, EN/KO native checks/renders, Universal2 packaging, signature/resources/ZIP verification and isolated launch. Final English Collection and Korean detail/Collection failure screens were visually inspected. Output is in `build/switch-final-20260919.log`; earlier compile/fixture failures and pre-footer renders are not final acceptance. No paid GitHub CI run was requested or claimed.
- Installed and running from Applications through `deploy-local.sh`; the live save is backed up as `EvoBar-v1.json.before-install-20260919-230941`, and the previous app is retained in the temporary `EvoBar-replaced/EvoBar-20260919-230941.app`. The installation log is `build/switch-install-20260919.log`. No real game actions were used as tests. This remains an ad-hoc local development install, not a signed/notarized public release.
- Next small check, after this delivery: genuine isolated keyboard interaction with the name/retry dialog. Model callbacks and static rendering are not physical keyboard or VoiceOver acceptance. Do not start another feature or regenerate art. The dirty Drive mirror remains untouched; GitHub main was still `200c7f3` before final verification. No paid CI or reset credits were used.

## Full alternate inventory and hybrid motion — 2026-09-19

- Current owner request: finish all variants and animations while keeping the quiet Home. All10 lines now have72 normal and72 dedicated Shiny forms with four states each (576 PNGs). This adds176 alternate-state PNGs for Fox, Kirin, Raptor, Pterosaur, Dragon and Phoenix; prior normal and four shipped Shiny sources are unchanged. Stable IDs, XP, hatching odds, entitlements and save schema are unchanged.
- Motion coverage is deliberately hybrid:84 quadruped form/colour combinations use the tested walk/trot rig;60 Raptor/Pterosaur/Dragon/Phoenix combinations add four distinct authored phases each (240 new frames). Menu bar, Home and desktop now share playback; colour never falls back to a different-colour motion strip. Ready-state stars remain visible; sleeping/Power Saver/Reduce Motion are static. No new game/UI system was added.
- A bounded12-strip cache avoids decoding every tick. All four phases use one padded alpha>2 presentation crop, preserving visible RGBA pixels and relative positions while excluding negligible export haze from layout. Normal Pterosaur1 menu height improved from4.31–6.75px to8.24–12.90px at24px. Native menu-only0.5pt contrast shadow preserves sprite colours.
- Untouched source PNGs, exact built-in prompts, selected/rejected generation identifiers and alpha-conserving import records are under Artwork/Sources/ShinyV1 and MotionV1. See [[ARTWORK]] for scope and limitations. The Fox alternate preserves the existing normal silhouette; a proof of nine separately visible tails in every pose and144 hand-drawn strips are NOT claims of this delivery. The strict future all-authored gate remains opt-in and unmet.
- All168 unit/fixture tests passed in338.825s after updating the old Shiny count assertions to42 walking forms/84 poses per colour. No anatomy/alpha/gait tolerance was weakened.5 focused decoding/presentation tests also passed. Native review adds six animated Shiny Homes and a Phoenix ready state. The artwork fixture now has zero pending XP, so it cannot attempt an unrelated save in the isolated store. The first packaging attempt was invalidated by this DEBUG fixture edit during compilation and is not counted as a passing build.
- Final DEBUG-source EN/KO native review passed after fixing the fixture's pending-XP setup inside AppModel (its setter intentionally remains private). New EN Pterosaur/Raptor/Fox/ready Phoenix and KO Pterosaur/Dragon/Kirin/ready Phoenix screens were inspected; the final clean fixtures have no spurious save warning. Final Universal2 packaging, all576 poses/60 strips, six locales, ad-hoc signature, ZIP/checksum and isolated launch passed. The earlier compile attempts invalidated by source edits/private-setter access are not accepted results. Logs are in build/art-review/final-verification-20260919.log (168 core tests) and final-delivery-20260919.log (final UI/package/launch).
- Installed and running from Applications. Live store backup: EvoBar-v1.json.before-install-20260919-221258; prior app retained in the temporary EvoBar-replaced/EvoBar-20260919-221258.app. No live game action or reroll was used as a test. Existing Launch at Login may need one off/on toggle to re-register the replaced bundle. This is an ad-hoc local development build, not a notarized public release. Paid GitHub CI remains disabled, and the dirty Drive mirror was not overwritten.

## Quieter default Home — 2026-09-19 owner clarification

- The owner explicitly clarified that the screen is too complicated; retain functionality and simplify its initial presentation. This supersedes always-visible secondary statistics and care controls in earlier checkpoints.
- Home now defaults to the companion image, name and evolution progress. One initially closed Details & care disclosure retains traits, current stage, affection, activity status, pet/treat buttons, the daily summary and unfinished/held eggs. Direct petting of the companion remains available. Evolution/graduation buttons, ready eggs, discovery acknowledgement and actionable failures remain visible outside the disclosure. No growth, purchase, save or animal record is changed.
- Removed the duplicate pending-XP label and routine growth hint from the default surface. Added a localized disclosure title in all six catalogs and an expanded-details native fixture so hidden capabilities are not silently lost. All 155 tests passed in 296.087 seconds. EN/KO/FR native rendering, Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch passed; the final Korean collapsed Home and English expanded details were visually inspected. No new direct-click or VoiceOver acceptance is claimed, and no paid GitHub CI run was requested.
- Installed and running from Applications. Store backup: `EvoBar-v1.json.before-install-20260919-205850`; previous app retained in the temporary `EvoBar-replaced/EvoBar-20260919-205850.app`. No live game action was used as a test. This remains an ad-hoc development build, not a public notarized release.
- Keep the clarification in [[GAMEPLAY_PLAN]] as the default for further work. Do not remove features or add new ones merely to make this screen quieter.

## Compact layout polish — 2026-09-19 follow-up

- Continuation from `ccc15a2`. No new feature, copy, balance, artwork or persistence change. Home now keeps short identity/stage/status rows inline and moves supporting information beneath them only when their natural widths do not fit. A long companion name can use two lines instead of competing with the activity badge; stage names are no longer squeezed by affection hearts.
- The egg prompt likewise preserves its single-line action and moves it below the description when necessary. French preview confirmed the full species name and egg-placement label remain readable; Korean short-label Home retains its compact layout. The same action and busy-state guards are reused in both arrangements.
- First-session names also allow two lines. Added 328-point-wide long-name first-session and evolution-ready renders to every locale and required-image validation. All 155 domain/fixture tests passed in 285.416 seconds; final UI source was then rebuilt and all six native render passes completed. Final EN/KO long-name and FR egg-prompt screens were visually inspected. The preliminary FR/KO preview is not the final acceptance run. Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch passed through the local pipeline. No new GitHub CI run was requested under the existing cost policy.
- Installed and running from Applications. Store backup: `EvoBar-v1.json.before-install-20260919-204547`; prior app retained in the temporary `EvoBar-replaced/EvoBar-20260919-204547.app`. No live game records were used as test fixtures. This remains an ad-hoc development build, not a public notarized release.
- Keep the product small. Existing native rendering is not a substitute for physical keyboard or VoiceOver acceptance; the earlier unresponsive UI-control tool has not been counted as a passing check.

## Durable companion transitions — 2026-09-19 follow-up

- Continuation from `cc5269d`, with no new game systems or balance changes. Onboarding, evolution, switching, graduating into a new individual and adopting a waiting individual now restore their prior in-memory state if saving fails. An unsuccessful graduation cannot silently consume its required egg or retire the current companion.
- A five-case synthetic regression forces a write failure, checks the original animals/current selection/starter grant/tracking date/inventory/pending XP/coins, restores the save destination, retries, and reopens the store. Every successful path has exactly one growing companion. The first run exposed unstable ordering for equal birth timestamps; snapshots and exports now reuse the existing birth-date/UUID ordering. No test assertion was weakened to hide that failure.
- Evolution starts its ceremony only after the store save succeeds. A failure keeps the original stage, removes the busy state and gives a localized retry explanation. Existing six-language UI and prior companion data are preserved; no live game action is used as a test.
- Final source passed all 155 tests in 302.453 seconds, EN/KO native rendering, Universal 2 packaging, signature/resources, ZIP/checksum and isolated launch through `Scripts/verify-local.sh en ko`. The earlier failed/interrupted runs are not counted. No new interactive/VoiceOver acceptance is claimed, and push-triggered CI remains disabled under the existing cost policy.
- Installed and running in Applications with the store backed up as `EvoBar-v1.json.before-install-20260919-201353`; the previous app remains in the temporary `EvoBar-replaced/EvoBar-20260919-201353.app`. No user game actions were performed as tests. This is still an ad-hoc development build, not a notarized public release.
- The simplicity guardrails and active continuation schedule below remain current. Next possible polish is compact long-label layout; do not add another feature to fill the roadmap.

## Small, reliable play loop — 2026-09-19

This is the current direction and supersedes the older feature-expansion, art-first and quota-pause instructions below. The owner wants continued improvements without a maximal product. Follow [[GAMEPLAY_PLAN]] and [[GAMEPLAY_PACING]]: improve the existing work/growth/discovery loop, not new systems or token consumption for its own sake.

- Home puts the current companion first, offers one compact next-egg action, and links a short daily growth/token summary to Usage. Detailed provider/cost information and the seven-day chart stay in Usage. Collection now counts actual encountered lines and revealed forms, not unlocked licenses; its Met filter and next-form hint use the same projection and preserve discoveries across duplicates, switching and retirement.
- Incubation counts distinct positive-usage days after placement, including out-of-order provider arrivals. An additive optional day ledger restores older saves from already-local usage without taking away earned progress. Ready eggs remain deliberate openings; placement is single-flight.
- Growth, petting and all existing coin-item transactions restore their previous in-memory state on failed saves. Visual care rewards happen only after saving. Failed growth absorption keeps pending XP and does not retry forever. A synthetic failure/retry test covers eight reward paths. It also exposed and fixed an omitted `sceneThemeID` decode; all four backdrop selections now round-trip.
- Reduced-motion hatch/evolution ceremonies immediately show a static final reveal without white flashes, sparks or bounce. The hidden Home scene stops its timeline, and menu-bar elapsed-time transitions can stop an obsolete working animation. No CPU-saving percentage has been measured.
- No new game mechanic, rebalance, animal art, live payment, credential change or real-user test data. Development all-unlocked/free-item behavior stays intact. Public release still needs the existing signing/notarization and payment gates.
- Final-source unit/fixture suite: all 154 tests passed in 295.489 seconds. `Scripts/verify-local.sh en ko ja es fr pt` passed all six native render passes, Universal 2 packaging, signature/resources, ZIP/checksum and isolated packaged launch. English, Korean, Japanese and French changed screens were visually inspected. The separate Korean interactive fixture launched correctly, but the UI-control tool stalled until its five-minute lifetime had expired; no new click/keyboard/VoiceOver acceptance is claimed. Its temporary app/data cleaned up automatically.
- Installed and running from `/Applications/EvoBar.app`. Store backup: `EvoBar-v1.json.before-install-20260919-195540`; previous app retained as `EvoBar-replaced/EvoBar-20260919-195540.app` in the temporary directory. No live egg or care action was used for verification. This remains an ad-hoc development build, not a public release. Push-triggered CI is disabled by the existing cost policy; this checkpoint relies on the completed local pipeline, not an unrun GitHub workflow.
- Next bounded work: exercise failed saves for existing switching/evolution/graduation actions and preserve their records if needed, then review the return to the growing companion. Do not add a new game subsystem. The French compact Home wraps the egg-placement label and abbreviates a long species name; a small layout follow-up can improve that without changing navigation. Keep interactive checks marked unverified until a responsive UI tool is available.
- The existing `evobar` heartbeat was found PAUSED with an obsolete art-first prompt. It is now ACTIVE at its existing 30-minute cadence, attached to this task and aligned with the simplicity guardrails. It checks real allowance, never redeems credits or enables paid overage, and preserves unfinished work for natural recovery when a safe verification unit cannot finish. It avoids duplicate active work and pauses when there is no safe meaningful improvement or new authority is needed. Old dated 10%/reset entries below are historical, not a current pause.

## Gameplay discovery checkpoint — 2026-09-19

- Latest owner direction: prioritize game enjoyment and the anticipation, surprise and collecting loop of PokeTokenBar. [[GAMEPLAY_PLAN]] records the source comparison, implemented slice, next priorities and remaining limitations. No third-party character assets, APIs, paid randomness, growth rebalance or user-store migration was introduced.
- Incubator eggs now require an explicit Open egg action. Home and Collection expose progress and the action; merely opening Home no longer consumes ready eggs. The ceremony saves the individual first, then leaves an acknowledgement card showing species, nature, rarity and alternate-colour status. First discoveries and repeat species have different headings. The current growing companion is not replaced.
- The acknowledgement is session-local, while the individual survives restart in Collection. A quit after the durable hatch cannot reroll the egg. Other graduation ceremonies retain their prior behavior. Inventory and incubator state roll back if placement/hatch saving fails; a second hatch of a consumed egg is rejected.
- Updated all six languages to describe the actual incubation flow, including the outdated Shop guidance. Added native Home-incubator and hatch-discovery fixtures plus an app-model acknowledgement/navigation check. The isolated fixture uses authored alternate-colour Capybara art, not a new art asset.
- All 144 tests passed in 296.292 seconds. English/Korean native rendering and app-model review assertions passed; both new English screens and the Korean discovery screen were visually inspected. All six localization files passed syntax validation. Public release still requires signing/notarization and purchase configuration; the development all-unlocked/free-item configuration remains unchanged.
- Universal 2 packaging, six locales/resources, ad-hoc signature, ZIP/checksum and isolated packaged launch all passed. Installed and launched in Applications; the existing store was backed up as `EvoBar-v1.json.before-install-20260919-180001`, and the previous app was retained in the temporary EvoBar-replaced directory. No live egg was consumed during verification.

## Tracking and first-session checkpoint — 2026-09-19

- The owner asked for autonomous product improvements and installation of the finished result. This slice strengthens the first-session and trustworthy-tracking loop. It does not restore the removed recap, bond ladder or mastery system.
- `UsageTrackingCoordinator` now lives in EvoBarPersistence so fixture tests exercise the actual app pipeline. Its result contains a snapshot plus provider-level transient health reports. Discovery errors and unreadable files no longer masquerade as successful tracking; healthy files/providers continue. No error descriptions, file paths, raw lines or sessions enter the diagnostics.
- `RefreshWorker` (EvoBarInfrastructure) serializes timer/manual/FSEvents triggers and coalesces requests made while busy. Cancellation drains old work before another scan starts; settings generation guards reject obsolete results. Reset drains scanning before deleting data. External quota/service checks run separately from the local scan.
- Ingestion restores the prior in-memory state when persistence fails, and unchanged checkpoint scans avoid rewriting the store. Synthetic regressions cover retries, recovery, malformed records, missing/removed files, denied folders, cancellation and competing refresh requests.
- Home has a compact first-companion introduction and an actionable first-session card instead of empty usage charts. Settings show connection diagnostics, last-check age and native folder selection; the footer opens Tracking. Six localized review scenarios cover connected, denied, partial, paused, manual and compact recovery states. Existing animal artwork and progression rules are unchanged.
- The first version passed 140 tests, English/Korean native rendering and Universal 2 packaging/launch, then was installed with the live store and prior app backed up. Live UI inspection exposed previously silent Codex failures caused by records above the scanner's 8 MiB limit. The scanner now discards oversized complete records with bounded memory, reports a skipped line and continues through later usage; an unfinished record keeps its start checkpoint until a newline arrives. Twenty-one focused scanner/coordinator/refresh tests passed, including chunk boundaries, exact limits, consecutive oversized records and append recovery. Final-source verification is recorded below after completion.
- Remaining release gates include publisher signing/notarization and real payment configuration. The local signing check on 2026-09-19 found no valid code-signing identities; installed tools are Command Line Tools. Development installs remain ad-hoc signed, not notarized public releases.
- Final source passed all 143 tests in 310.116 seconds, all expected English/Korean native renders, Universal 2 packaging, ZIP/checksum and signature/resource verification, and isolated app-launch smoke testing through `Scripts/verify-local.sh en ko`. The updated `/Applications/EvoBar.app` was installed with the prior app and local store backed up. Native interaction confirmed footer-to-Tracking navigation, recovery of previously blocked usage, and both provider connections returning healthy after a manual incremental refresh; the existing companion remained intact. No live usage totals, screenshots or raw logs are committed.

## Mammoth Shiny checkpoint — 2026-09-11 evening

- Mammoth now has seven original authored Shiny forms and 28 state PNGs, bringing dedicated Shiny coverage to Cat, Dog, Capybara and Mammoth: 28 forms / 112 resources. `Artwork/Sources/ShinyV1/MAMMOTH.md` holds the accepted built-in prompt and provenance; `Mammoth.png` is the untouched transparent source and `Mammoth.json` records exact alpha-conserving extraction.
- The Shiny manifest flag is enabled only after all 28 files were exported. Existing normal art, gameplay, odds, entitlements, prices, schema and user data remain unchanged. Coverage/gait tests now exercise all 28 authored Shiny quadrupeds with unchanged thresholds.
- DEBUG-only native review adds Mammoth stage-four Home, final Home and discovered detail journey, bringing the harness to 37 screens per locale. After rebasing onto the automatic-growth UI, all 74 EN/KO renders were regenerated and the Mammoth screens were visually inspected. The combined 113-test suite passed in 329.365 seconds. A pre-existing ambiguous `cos`/`sin` overload in the incoming star path was fixed by using `CGFloat`, restoring the macOS build without changing its geometry.
- Actual weekly allowance was 64% remaining at start and 60% after full local verification. The secondary window remained unavailable rather than zero; no reset credit was consumed.
- Next safe art slice: another unambiguous unfinished line. Fox remains quarantined until its legendary forms show nine separately countable tails. Remaining six Shiny lines and authored biped/wing frame cycles are unfinished. Keep the existing 30-minute quota guard active and continue outside the dirty Drive mirror.

## Capybara Shiny checkpoint — 2026-09-11 afternoon

Resumed from clean `1a8d5c0`; its CI `34568877799` passed. Actual weekly allowance was 73% remaining at start and 71% at the asset/test boundary. No secondary window was reported; no reset credits were used. This checkpoint supersedes older pause and remaining-art notes.

- Added seven original Capybara Shiny forms, 28 state PNGs. Total dedicated Shiny coverage is Cat/Dog/Capybara, 21 forms and 84 PNGs. Source/prompt/extraction records are in `Artwork/Sources/ShinyV1/Capybara.{png,json}` and `CAPYBARA.md`. The 28 files reproduce with identical SHA-256 values and exact source-alpha conservation.
- Normal art and the 56 completed starter Shiny images are unchanged. Only Capybara gets `hasShinyArtwork`; no hatch odds, ownership, prices, XP, schema version or user records are changed. Core coverage/gait tests now exercise all 21 authored Shiny quadrupeds with unchanged thresholds. DEBUG-only native fixtures add stage-four/final Home and discovered detail views; the harness now expects 34 screens per locale.
- The first Capybara atlas failed the pup's standing leg ratio (0.04698 versus the unchanged >0.06 requirement). It was replaced by a fresh transparent generation with clearer exposed legs, not by relaxing the test or altering the gait engine. The revised pup ratio is 0.08118 and all seven standing diagnostics pass. Only final-source full validation counts; earlier failed logs are quarantined in Drive.
- Native review exposed an existing variant mismatch: a Shiny collection tile opened a detail header/journey using normal art. `CompanionDisplaySelection.representativeInstance` now centralizes the existing highest-stage/newest/UUID ordering for pin, tile and detail. The detail header and journey carry that representative's Shiny flag; the educational field guide intentionally keeps normal species illustrations. Two regressions ensure lower-stage Shiny animals cannot reveal later Shiny forms reached only by normal individuals and preserve tie-breaking. No records are mutated.
- Fox Shiny was attempted but NOT shipped. Its first transparent 28-pose atlas failed the nine-visible-tail anatomical check; a targeted tail edit also lost alpha; a fresh larger two-column legendary sheet still failed the tail-count criterion. Drafts and exact prompts are quarantined in the separate Drive delivery, never runtime resources. Do not accept segmentation counts or a non-nil alpha channel as proof of artistic correctness.
- Revised-art validation passed all 108 tests (295.603 seconds), including 21 Shiny quadruped forms, before the collection-selector follow-up. After that follow-up, all seven selection tests (two new, 110 total in the full suite) and all 68 EN/KO native renders passed. The final detail header/journey was visually checked in both languages and shows the actual Shiny variant. Final-source Universal 2 packaging and full CI results belong in the separate Drive delivery's `VERIFICATION.md`; do not confuse the first failed atlas or pre-selector renders with the final version.
- Next safe art slice: Mammoth Shiny or another unambiguous unfinished line. Fox needs a separate anatomical redraw with nine clearly counted tails, not another identical whole-atlas edit. Remaining seven Shiny lines and authored biped/wing frame cycles are unfinished. Keep the existing 30-minute quota-guard heartbeat active; work outside the dirty Drive mirror and preserve its source/index.

## Starter Shiny checkpoint — 2026-09-11

See the newer Capybara checkpoint above when choosing remaining work.

Resumed from clean `2de55b7` after checking the actual reported weekly allowance (81% remaining at start, 78% at the implementation boundary; no secondary window or reset credits used). The normal-art slice passed GitHub CI `34564738266` and is not repeated.

- Added dedicated Cat/Dog Shiny artwork: 14 alternate forms, 56 state PNGs. Source `Artwork/Sources/ShinyV1` holds exact prompts, untouched PNGs and alpha-conserving extraction records. The two attempted Cat edits with baked-in checkerboards were rejected; accepted images are fresh original transparent generations, not pixel-identical recolours. Normal Atlas V2 art is unchanged.
- Optional `hasShinyArtwork` declares the two complete lines. All other lines/older catalogs retain normal-art fallback. No individual is rerolled, no hatch odds, XP, ownership, prices, persistence version or user data are changed.
- Importer accepts `--shiny`, refuses atlases without alpha, and writes dedicated `.shiny` resource IDs. Re-export SHA-256 values match for all 56 files. The package verifier also requires all declared Shiny stage/state files.
- Coverage and gait checks now exercise normal and authored Shiny art independently, with their original safety thresholds unchanged. All 108 tests passed on final source (280.880 seconds). DEBUG-only native fixtures add Shiny Home/Collection: all 62 EN/KO screens rendered, and both new screens were visually checked in both languages. Universal 2 packaging, resources/signature/ZIP checks and isolated app launch passed. This is an ad-hoc-signed development preview, not a public notarized release. Final CI and delivery checks are recorded in the separate Drive delivery's verification note.
- Next art work: the remaining eight Shiny lines, then authored biped/wing cycles. Do not regenerate normal art or these two completed Shiny sources; preserve the dirty Drive mirror and work from the clean checkout. This checkpoint is copied into a separate Drive delivery, never over the mirror's source files.

## Active checkpoint — original art, 2026-09-11

This section supersedes the historical no-art/paused/next-slice notes below. The owner explicitly asked to resume and finish the animal artwork. Work starts from `4c2e292` in the clean checkout outside Google Drive; do not reset or bulk-stage the Drive mirror.

- All 10 current lines now have 72 independently drawn normal forms and 288 transparent state poses. All six undrawn lines and eight recoloured placeholder stages are replaced. Exact generation prompts and untouched originals are in `Artwork/Sources/AtlasV2`; extraction is documented in [[ARTWORK]].
- `Scripts/prepare-art-atlas.swift` splits the actual connected silhouettes instead of assuming equal grid cells. Source alpha totals are conserved exactly; a second export produced identical SHA-256 values for all 288 runtime files. Legacy placeholder/five-column utilities refuse to overwrite existing assets.
- New coverage checks enforce 72 stages, 288 distinct pose resources, transparent borders and no pending-stage flags. Existing gait tests now cover all 42 quadruped forms. The rig measures the actual owned paw pixels and permits a bounded settle of one quarter of the visible leg, fixing floating feet on the new fox/capybara drawings without relaxing test thresholds.
- Raptor is explicitly biped and bypasses the four-leg rig. All normal images are complete; separate Shiny palettes and authored biped/wing frame cycles remain unfinished. Do not describe four state poses as frame-by-frame animation.
- Fixed a pre-existing Swift 6 build error in the care-anchor preference callback by handing the state update back to MainActor. No user data, entitlement IDs, prices, token thresholds, credentials or external services changed.
- Current account reports only a weekly allowance (duration 10,080 minutes), last checked 87% remaining. A missing secondary window is unavailable, not exhausted. No reset credits used. The owner's below-10% pause rule still applies to any actually reported limiting window.
- Original art, cropped sprites, tools and review sheets are also preserved in the Drive project's `Art Deliverables/AtlasV2-2026-09-11`, independently of the dirty mirror source. This confirms local presence only, not remote Drive sync.
- Verification: all 108 unit/fixture tests pass (including the expanded gait suite); EN/KO isolated native review produced 58 screens and passed its startup/window/keyboard checks. Home, compact Home, Collection and detail images were inspected. Universal 2 packaging, ZIP/checksum, ad-hoc signature/resource validation and isolated app launch all pass. These checks do not certify VoiceOver, physical Intel hardware or a multi-monitor session.
- Artwork commit `3526257` is pushed to the existing private repository. Release validation now requires every one of the 72 forms in all four states instead of checking just the old 28; the separate incomplete-bundle check removes only a test copy's raptor sprite and requires rejection. This app is a local development preview, not Developer ID signed/notarized or publicly released. Final CI run/status is linked in the Drive delivery's verification note.

## Current run

- State: paused at the quota safety boundary after completing two verified slices. Adaptive layout/recovery `f5c7595` passed GitHub CI `34317111912`; dismissible feedback `f7fe0ca` passed GitHub CI `34317554011`.
- Starting commit: `1b3de70`, with a clean worktree and passing CI.
- Focus: adaptive popover/dashboard sizing, screen-disconnection recovery for windows and the desktop pet, then keyboard/accessibility and recoverable states.
- Implemented: screen-aware layout and window recovery, compact detail/privacy/graduation sheets, persistent graduation actions, Command-F search, spoken stages/selection, direct Tracking navigation, and non-destructive startup Retry.
- 99 unit/fixture tests and 312 native renders across six languages passed, including startup retry and Tracking navigation checks. Release packaging and CI results are recorded at the checkpoint below.
- Local checkpoint: Universal 2 packaging, resource/signature/ZIP verification, and isolated app launch passed. GitHub CI must be checked against the commit containing this note before considering the slice fully handed off.
- No animal-image changes, live payments, public releases, user-data changes, or new service integrations.

## Field guide slice (Claude, 2026-09-09 evening)

- Landed after `8b39958` while the Codex run was paused: a 67-page field guide (`Sources/EvoBarCore/Resources/lore.v1.json`, `Lore.swift`, `FieldGuideView.swift`) shown in `CompanionDetailView` under the evolution journey, with a discovered-pages badge in the Collection header. Discovery is derived from `animalInstances`; nothing new is persisted and no schema changed.
- The isolated review now renders 58 screens per locale: `field-guide-{light,dark}` was added to `VisualReviewExporter` and `Scripts/review-ui.sh`. Korean renders were checked by eye; the `.git/index` file was found missing on 2026-09-09 18:47 KST and rebuilt with a plain `git reset` (no working-tree change).
- Tests: `LoreTests` (coverage, both languages, discovery from the highest stage reached). Full check passes. No animal-image changes, payments, releases, user-data changes or new services.
- Open: relatives could become playable stages once sprites exist; the manifest's five-stage rule and thresholds would then need the re-spaced ladders proposed in the field-guide artifact.

## Compact dark glass panel (Claude, 2026-09-09 night)

- Landed after `5db78c2`: the panel is 360 by 540 points and always dark glass (`popover.appearance = .darkAqua` with a clear SwiftUI root; the detached dashboard is an `NSPanel` with `.hudWindow`; `EvoStyle` surfaces are white tints). Header row removed, text tabs at the top, Settings in the footer, smaller section titles without subtitles, tighter cards. See the dated section in `UX_REVIEW.md`.
- `VisualReviewExporter` and `Scripts/review-ui.sh` render the dark appearance only: 29 screens per locale, same file names with the `-dark` suffix. `WindowPlacementTests` keep their explicit 420-by-700 inputs and still pass; `WindowLayoutReview` compares against `EvoStyle.height` and needs no change.
- No animal-image changes, payments, releases, user-data changes or new services. A "match system appearance" option was deliberately not added; add one only if users ask.
- Rebased onto `bc6d53a` (the keyboard slice and its checkpoint). Because that slice's CI failed on the localization scanner, the scanner fix described in `NATIVE_UI_CHECKPOINT.md` was applied here as well: an identifier boundary before the view name, the extraction shared as `staticUIStrings(in:)`, and a regression test (`staticStringScannerStopsAtIdentifierBoundaries`, suite now 103 tests). The Codex run resuming after 00:45 KST should not repeat it; the `KeyboardNavigationReview` passed against the new panel in the Korean/English isolated review.
- The `.git/index` on this Google Drive mirror has twice been seen out of step with HEAD (missing on 2026-09-09 18:47; staging a reversal of the field-guide files later that evening, per the checkpoint). Neither editor lost work. Treat a surprising index as a sync artifact: compare against HEAD before trusting `git status`.

## Claude work plan, 2026-09-09 night (product owner request)

Work proceeds in scoped slices, each committed and CI-checked, so a quota pause loses nothing. Resume from the first unchecked item.

- [x] A. Walking scene back on Home (the companion walks across the top of its card with the parallax backdrop; tap to pet); glass tokens with gradient fill and hairline, panel tint 66%.
- [x] B. Shop and collection show an egg for any line that has not hatched; `unlockEverything` in `app-config.json` makes every line owned and items free until the storefront goes live.
- [x] C. Longer evolution ladders: cat and dog 7 stages, the other lines 7 to 8 (see the dated section in UX_REVIEW.md). Sprites for the shifted forms were renamed (`cat.4` became `cat.5`, `cat.5` became `cat.7`, likewise dog; `fox.4` became `fox.6`, `fox.5` became `fox.7`; `capybara.5` became `capybara.7`); stages without their own sheet borrow a neighbour and carry `artworkPending: true`.
- [x] D. Artwork briefs: ARTWORK.md now carries one generation brief per line for the extended ladders (seven or eight columns by four states) and the hand-off steps (calibrate a grid entry in `Scripts/extract-sprite-sheet.swift`, extract, point every stage at its own asset id, drop `artworkPending`). The images themselves still have to be generated by a run with an image tool; this editor has none. Until then the eight pending stages of the illustrated lines show recoloured placeholders (`Scripts/derive-placeholder-sprites.swift`, provenance in ARTWORK.md). Motion is procedural and needs no extra art.
- [x] E. Quota rule from the product owner: stop below 10% remaining and resume after the reset; record any pause here. No pause was needed for slices A to D; the 23:13 KST resume check on 2026-09-09 found every item landed with CI green at `1a22ad2`. The rule stays in force for later slices.

## Next slice for the Codex run (image tool required)

Generate the ten sprite sheets described in the "Extended ladders, 2026-09-09" section of ARTWORK.md, one line at a time, in this order of value: cat and dog (the starters), fox and capybara (replace the recoloured placeholders), then raptor, mammoth, pterosaur, dragon, phoenix and kirin (the lines that still render as emoji). For each: calibrate a grid in `Scripts/extract-sprite-sheet.swift`, extract, point the stages at their own ids and drop `artworkPending`, run `Scripts/check.sh` and `Scripts/review-ui.sh en ko`, record provenance in ARTWORK.md, commit per line. The pending placeholders may simply be overwritten by the extraction.

## Drive mirror repair, 2026-09-10 morning (Claude)

- The mirror's `.git` had lost `refs/heads/main` (unborn HEAD, every file staged as new) and carried stale `index.lock` and `main.lock` files. The branch ref was recreated at `origin/main` (`46e8025`), the index rebuilt with a plain `git reset`, the locks moved out of the repository, and the files the interactive-review commit touched were restored from HEAD. Four identical Drive duplicates (`AppWindowLayout (1).swift` and friends) that broke the build were moved out as well. No history was rewritten; nothing was force-pushed.
- The pattern is Google Drive syncing `.git` internals. Working from a clean checkout outside Drive, as the Codex QA note already does, is the reliable fix; the mirror should become documentation only.

## Gait rig, care burst and glass, 2026-09-10 afternoon (Claude)

- `SpriteGaitRenderer` was rebuilt around a scanline model: legs swing by inverse kinematics from a joint above the hip line (`SpriteGaitAnalysis.thighHeight`, `strideLength`), the body between joint and hip line is a leaning band pinned at the belly's middle, shins shear and squeeze, paws translate, far legs get a shaded copy of the fuller partner leg. Ownership below the hip line is per pixel (`Rig.owner`), a hanging tail is rejected as a leg in standing poses, and a lone wide run splits at the paw gap, the contour, or the middle. The scenery scroll rate follows `strideLength`, so `SpriteGaitMetrics.legHeightFraction` grew with it. UX_REVIEW.md has the reasoning.
- Sprites scale with `.high` interpolation everywhere they are drawn smaller than their sheet (scene, tiles, menu bar). The sheets are pixel art at about 230 pixels; nearest-neighbour downsampling was the visible pixel breakage.
- `CompanionHomeView` gained `CareBurst` and `CareBurstLayer`: a Canvas over the companion card driven by a TimelineView that runs only while a burst is alive. Anchors for the scene and the two buttons come from a preference key in the card's named coordinate space. Reduce Motion skips it.
- `EvoStyle.glass` is 34% now. `StatusItemController.thinPopoverGlass()` walks up from the hosting view to the first `NSVisualEffectView` (on macOS 26.5 the frame class `NSPopoverFrame` is one) and sets the HUD material; if AppKit changes that hierarchy the call finds nothing and the popover keeps its default material. The detached HUD panel asks for `.fullSizeContentView` with a hidden title; on macOS 26.5 the HUD panel keeps a 24-point title bar anyway, drawn as the same glass, so `fitDetachedWindow` sets `CompanionPanelLayout.topInset` (applied by `RootPopoverView`) to 18 only when the title bar height is zero.
- Verified locally: `Scripts/check.sh`, `Scripts/review-ui.sh ko`, the app relaunched from `Scripts/build-app.sh` and its dashboard window captured. Not verified: VoiceOver speech; the popover material on macOS 14 and 15, where `NSPopoverFrame` may not be a visual effect view (the walk then finds none and nothing changes).
- Sheet generation for the ten lines remains the Codex run's slice; nothing here touches the manifests or the sprites.

## Hip-height thigh, 2026-09-10 evening (Claude)

- `SpriteGaitAnalysis.thighHeight` now reaches from the hip line up to 55% of the body height (the hip and shoulder joints); `strideLength` is a separate stored figure (visible leg plus about as much again, clamped) so the stride did not grow with the joint. The band shifts by the driver's knee displacement times depth, eased to zero between the knee column and the belly's middle (`Rig.weight`), and each row is inverted once with a monotonic walk (`Rig.sources`). `bodyRise` adds a twice-per-cycle bounce of 1.2% of body height. The driver of a pair is the leg with the larger owned area down the shin (`Rig.area`), outer leg on a tie; a leg with background between it and its partner gets no ghost.
- Superseded the same night: the joint is at 42% of the height, and the band's shift is full from the knee column outward and fades out over `Band.fade` columns (a little over twice the knee's swing) toward the belly, with `Band.factor` 0.85 for the haunch and 0.5 for the chest. The belly between the bands is rigid. A rigid cutout (haunch and chest as turned pieces with a torso cut) was tried and rejected: seams through the fur and holes behind turned pieces. If the sway still looks strong on a sheet, the levers are the 0.42 joint height, the two factors, and the 0.012 bounce; the stride is `strideLength`, not `thighHeight`.
- `SpriteGaitRenderer.groundShadow` marks wide translucent components in the bottom sixth of a sheet (painted paw shadows); they are excluded from the silhouette used for analysis and never drawn in gait frames.
- `Rig.owner` only covers pixels reachable from the bottom quarter of the sheet without crossing the hip line (`standing`), so belly fur is body. The near leg of a pair (`driver`) is chosen by shin brightness, then owned area, then position; only the other leg of the pair gets a shaded copy (`ghost`) of the near leg's shape.
- `ProviderStatusBanner` now renders inside `UsageDashboardView` under the window picker instead of above the tabs' content.

## Rubber-hose gait rig, 2026-09-11 (Claude)

- `SpriteGaitRenderer.Rig` was rewritten. No skeleton, no inverse kinematics, no bands, no ghost legs, no rotation: each leg's rows slide by `offset(of:)` times a quadratic ramp that is 0 at `legTop[index]` and 1 a quarter above the drawn foot. The torso is rigid and only dips (`bodyRise`). `dropLoosePieces` clears anything in the finished frame not reachable from the hip line, unless the artist drew it loose; `frames(...)` re-renders the whole cycle with `movingLegs: false` when that clearing costs more than 1/40 of the drawing.
- Levers, all in `SpriteGait.swift`: `bendShare` (how far down the bend finishes), the 0.014 dip in `bodyRise`, the settle cap in `offset(of:)`, and the 40 in the fallback test. `strideLength` still drives both the stride and the scenery scroll, so planted feet stay with the ground.
- `SpriteGaitTests.posingNeverBreaksTheDrawingUp` is the invariant that ends the whack-a-mole: a posed frame may be no more broken up than its source sheet. Add it to any future change here before touching the rig.
- Known: the kirin capybara (`capybara.7`) has no background between its legs, so its belly fur is taken as leg and slides. Real walk art for that line resolves it; no rule found so far tells that fur from a leg without also stopping the wolf and the lynx from walking.

## Growth arrives on its own, 2026-09-11 (Claude)

- `EvoBarStore.feedCurrentAnimal` is gone. `absorbPendingXP(now:bonusRoll:)` moves the waiting XP into the companion, rolls `GrowthBonusEngine` (EvoBarEvolution), drops golden coins into the wallet and counts the first arrival of a growth day as care (`AnimalInstance.absorbedOnCareDay`, reset with the care counters). `pendingFoodXP` is `pendingXP` in code and keeps its old JSON key.
- `AppModel.absorbGrowthIfNeeded()` runs only while `isPanelVisible` and Home is selected; `StatusItemController` sets visibility from the popover's show and close notifications and from the detached window. The Home view calls it on appear and whenever `pendingXP` rises, and shows `lastAbsorption` through `CareBurst` (kinds pet, treat, growth) plus a three-second gold note for a lucky or golden roll.
- Rare Candy: `purchaseGameItem(..., candyRoll:)` and `GrowthBonusEngine.candyGrant`; the manifest's `xpGrant` is now the mean, 60.
- `UsageBandGauge` (CompanionHomeView.swift) draws today's tokens against the usage band thresholds.
- Tests: `growthBonusTiersFollowTheRoll`, `candyGrantSpansItsListedValue`, `absorbingXPMovesItRollsABonusAndCountsCareOncePerDay`; the pipeline test absorbs instead of feeding. The six catalogs lost the feed keys and gained `care.treat.action`, `care.bonus.lucky`, `care.bonus.golden`, `ui.growthHint`.

## Usage story, 2026-09-11 (Claude)

- `UsageStoryEngine` (EvoBarUsage) reads a window's events into `UsageStory` (Core): active seconds with parallel sessions merged, peak hour in the growth time zone, longest session. `EvoBarStore.usageDashboard` fills it per window and adds `streakDays`, `bestDay` and `yesterdayTokens` to `UsageDashboardSnapshot` from the daily aggregates. Both snapshot inits default the new fields, so older call sites compile unchanged.
- `UsageDashboardView.storyCard` renders it; input, output, cache and the model list moved into a `DisclosureGroup` (`ui.tokenDetail`) that still honours `showTokenBreakdown`. Fifteen keys were added to the six catalogs (`story.*`, `ui.tokenDetail`).
- Tests: `UsageStoryEngineTests` (four) and `usageDashboardTellsTheStoryOfTheDay`.

## Rarity, nature, shiny and the hatch ceremony, 2026-09-11 (Claude)

- `L10n.nature`, `L10n.natureFlavor`, `L10n.rarity` read the catalog keys (`nature.<id>`, `nature.<id>.flavor`, `rarity.<raw>`); all six catalogs carry the twelve natures with flavours and the four rarities, and `natureAndRarityNamesAreLocalized` holds them to the bundled catalog. `EvoStyle.rarityColor` is the one palette for badges and the egg's glow.
- `AppModel.hatchCeremony` is set by `startNextCompanion` after the store write and cleared after `HatchCeremonyView.total`; the Home tab overlays it like the evolution ceremony, and `absorbGrowthIfNeeded` waits for it. The collection tile, header and detail edits are small and local so the Codex run's `representativeInstance` work is untouched.

## Companion voice, 2026-09-11 (Claude)

- `CompanionVoice.key(nature:mood:state:occasion:roll:)` (EvoBarEvolution) chooses a catalog key; `CompanionHomeView.say(_:)` localises and shows it in `SpeechBubbleView` over the scene. Keys: `voice.<nature>.0..2`, `voice.<nature>.pet`, `voice.state.sleeping.0..1`, `voice.state.working.0..1`, `voice.state.ready.0`, `voice.mood.sulking.0`, `voice.mood.sulking.pet`, `voice.mood.distant.0`, `voice.growth.0..2`. `everyVoiceLineExists` walks the chooser and holds every key to the English catalog; parity covers the rest. EvoBarCoreTests now depends on EvoBarEvolution for that test.
- To add a line: add the key to all six catalogs and raise the matching count constant in `CompanionVoice`; the test picks it up.

## Journal, 2026-09-11 (Claude)

- `AnimalInstance` gained `firstGrowthAt`, `evolutionDates` (stage index to date), `adoringAt`, `firstGoldenAt`, all optional or empty for older records; `PersistedDailyAggregate.tokensByAnimal` mirrors `awardedXPByAnimal` in raw tokens, and `PersistedAppSnapshot.busiestDays` reduces it per individual. The store writes the dates in `absorbPendingXP`, `acknowledgeEvolution`, `petCurrentAnimal` and the treat branch (`notingAdoration`).
- `CompanionJournal.entries(for:animal:busiestDay:)` derives the lines; `CompanionJournalView` draws them at the end of each individual's record in the collection detail, replacing the two loose "final evolution" and "graduated" lines. Ten `journal.*` keys in the six catalogs. Test: `journalDatesAreRecordedAsTheyHappen`.

## Claude checkpoint, 2026-09-11 evening

- Shipped today on top of the Codex art commits, one slice per commit: growth arrives on its own with a bonus roll and a today gauge (`294fb14`), the Usage story card (`5c6ef8b`), rarity, nature, shiny and the hatch ceremony (`b68a844`), the companion's voice (`937b5b0`), and the journal (this commit). Each slice passed the full suite, the Korean renders, packaging, an isolated launch and a live capture locally.
- GitHub CI has been refused since 08:07 UTC for every push, Codex's included: the job never starts and the annotation reads "recent account payments have failed or your spending limit needs to be increased". That is a Billing & plans setting on the GitHub account, not the code. Until it is fixed, the local verification above is the check; re-run the latest workflow once billing is back and confirm green before calling these slices handed off.
- The product owner's approved policy list is finished, one slice and one commit each: the daily gift, scene backdrops for coins, the weekly recap, bond levels, line mastery, the companion card, and the incubator. The two motion items remain: whole-body locomotion as the walk fallback, and a frame-strip playback path so authored frame cycles plug in. Nothing else from that list is outstanding.
- Proposed convention for authored frame cycles, to settle before either run draws one: `<assetID>.<state>.cycle.png`, one horizontal strip of equal frames, strip width an integer multiple of the state sheet's width, frames in gait order starting at touchdown. `AnimalSpriteImage.gaitCycle` will slice such a strip and play it in place of the procedural cycle when it exists; nothing else changes.

## CI on request, 2026-09-11 evening (Claude)

- `ci.yml` no longer runs on pushes to `main`; it runs on pull requests and `workflow_dispatch`. A private repository bills macOS runner minutes at ten times the clock, so the free 2,000 minutes are 200 macOS minutes, about 28 runs of this workflow. Sixty seven runs in eleven days spent it, and every push after that was refused before its first step with a billing annotation rather than a test failure. Neither run's code was at fault.
- `Scripts/verify-local.sh` runs the workflow's four steps in order with the same environment, and is now the check a change has to pass. Both runs should use it per slice. It leaves the same artifacts (`build/ui-review`, `build/release`).
- What it cannot cover is a clean machine. Before a release, or when a change touches packaging, the toolchain or resources, run `gh workflow run ci.yml --ref main` and confirm it green. `release.yml` is untouched and still runs on every `v*.*.*` tag.
- Reading a refused run: if the job has zero steps and no runner name, it never started, so the code is not the suspect. `gh api repos/kitesik/EvoBar/check-runs/<job id>/annotations` carries the reason.

## Daily gift, 2026-09-11 (Claude)

- `DailyGiftEngine.gift(coinRoll:itemRoll:candyXP:)` (EvoBarEvolution) returns `DailyGift`; `GrowthAbsorption.gift` carries it and `total` includes its XP. The store rolls it inside `absorbPendingXP` only when `absorbedOnCareDay` is still false, so it rides exactly the once-a-day branch that already counted care; coins and XP join the same sweep and an egg goes to `itemInventory["random-egg"]`. `AppModel` passes the manifest's Rare Candy XP so the gift follows the economy file.
- Levers: `leastCoins`, `mostCoins`, `candyChance`, `eggChance`. Tests: `theDailyGiftAlwaysGivesCoinsAndSometimesMore`, `theDailyGiftLandsOnceAGrowthDay`.

## Scene themes, 2026-09-11 (Claude)

- `GameItemKind.sceneTheme` plus four manifest items (`scene-dawn`, `scene-dusk`, `scene-night`, `scene-snow`, 60 coins). `SceneTheme` (Core) maps an item id to three colours; `AppSettings.sceneThemeID` holds the one worn, nil meaning the old artwork tint. The store's purchase branch refuses a second buy and wears the theme on purchase; `AppModel.setSceneTheme` toggles it off and on.
- `CompanionSceneView` gained a `sceneTheme` parameter and draws sky, hills and ground from a three-colour palette; with no theme the three are the artwork tint at the previous opacities, so the unthemed scene is unchanged. Test: `sceneThemesAreBoughtOnceAndWornByChoice`, which also holds the manifest and the enum to the same four ids.
- To add a backdrop: one manifest item, one `SceneTheme` case with its colours, and `item.scene-<id>` in the six catalogs. Nothing else.

## Companion card, 2026-09-11 (Claude)

- `CompanionCardView` is a fixed 420 by 560 surface, never scrolled and never tapped; `CompanionCardExporter.png(for:)` draws it through `NSHostingView` and `cacheDisplay`, the same way the review renderer does, and `AppModel.exportCompanionCard` runs an `NSSavePanel` and writes the file. `cardExportMessage` reports the result under the button in the collection detail.
- The harness renders `companion-card-*` each run (40 per locale now), so a broken card fails the local check rather than being found by a user. `CompanionCardNameTests` pins the file-name rules.

## Incubator, 2026-09-11 (Claude)

- `IncubatingEgg` (Core) carries `activeDays` and `lastCountedDayKey`; `EvoBarStore.ingest` counts each egg once per growth day that saw usage, so warmth follows work rather than the clock. `placeEggInIncubator` consumes a `random-egg` (capacity 3), `hatchEgg` records a draw made above it, and `graduateCurrentAndAdopt` raises one that was waiting. `AnimalInstance.isWaitingToBeRaised` is `!isCurrent && graduatedAt == nil`.
- `AppModel.hatchReadyEggIfNeeded` makes the draw with `HatchEngine` (it has the catalog and the charm), records it, and plays `HatchCeremony`; it runs only while Home is visible and after any arrival, so the two ceremonies never overlap. `IncubatorCard` sits at the top of Collection; the graduation sheet gained a Waiting mode that opens selected when one waits.
- Tests: `eggsWarmOnWorkingDaysAndHatchIntoACompanionThatWaits`, `adoptingAWaitingCompanionGraduatesTheOldOne`.

## Policy slices finished, 2026-09-11 night (Claude)

- Seven slices landed after the CI change, each verified by `Scripts/verify-local.sh` and committed on its own: `5d44d6f` daily gift, `38dd9a4` scene backdrops, `f2f089c` weekly recap, `b5a2645` bond levels, `21380d4` line mastery, `f28964c` companion card, `2010658` incubator. The suite is 133 tests and the harness renders 41 screens per locale.
- Two of them changed shapes other work has to know about. `AnimalInstance` gained `careCount` and four journal dates, all defaulting for older records, and an individual can now exist in a third state: hatched, never raised, waiting (`isWaitingToBeRaised`). `PersistedSettings` gained `incubator`. Anything that enumerates instances should decide which of the three states it means.
- Every one of these is paced so it cannot be farmed: the gift and the bond's daily act ride the once-a-day branch, an egg counts a day of usage once, and the recap keys off the calendar week. Adding another reward should ride an existing per-day flag rather than a new timer.
- Still open, both about motion and both needing the Codex run's art or a decision: whole-body locomotion as the walk fallback, and the frame-strip convention proposed in the checkpoint above.

## Raising another companion, 2026-09-11 night (Claude)

- `EvoBarStore.switchCurrentCompanion(to:name:at:)` moves which individual is current without graduating; the one stepping aside keeps everything including `pendingXP`. `AnimalInstance` gained `isResting` and `canBeRaisedNext` beside `isWaitingToBeRaised`, so the four states are named: current, waiting, resting, graduated. Only graduation sets `graduatedAt` and only it is irreversible.
- `PersistedSettings.lastGiftDayKey` moved the daily gift from the companion to the growth day, because switching would otherwise draw it twice. `absorbedOnCareDay` stays per companion, which is correct: that is care for that companion.
- `AppModel.raiseCompanion(instanceID:name:)`, `restingCompanions`, `companionsToRaiseNext`; the button lives on each individual's record in the collection detail, with a naming alert for one that has never been raised. Tests: `raisingAnotherCompanionSetsTheFirstAsideWithoutLosingAnything`, `switchingCompanionsDoesNotCollectTheGiftTwice`.

## The owner's app is installed, 2026-09-11 night (Claude)

- The app the product owner uses now lives at `/Applications/EvoBar.app`, installed by `Scripts/deploy-local.sh`. It had been running out of `build/EvoBar.app` inside the Drive-synced project, which every `build-app.sh` overwrites under it. Do not relaunch the owner's app from `build/`; that directory is a build artifact again. Use the deploy script when a change is meant to reach them, and leave it alone otherwise.
- The live store is `~/Library/Application Support/com.evobar.app/EvoBar-v1.json`, schema 10, and it already carries today's added fields (`careCount`, the journal dates, `incubator`, `lastGiftDayKey`, `sceneThemeID`, `lastSeenRecapWeek`) with the three existing companions intact, so every default-on-decode addition was exercised against real data rather than fixtures. The deploy script writes a timestamped copy before each install.
- Two things about that install to keep in mind. It is ad-hoc signed and unnotarized, which is fine on the machine that built it and nowhere else. And `unlockEverything` is still on, which is what grants every line: the owner's `activeProductIDs` is empty, so turning it off would lock them to the starter. Turn it off only together with real entitlements, as the release checklist says.
- Launch at Login is registered by whichever bundle called `SMAppService.register()`, and that was the old copy. Only the app can re-register, so a path change needs one off and on in Settings, Companion.

## Resume rules

- Check both the five-hour and weekly Codex remaining allowance before work and at task boundaries. Do not use reset credits.
- Below 10%, stop starting edits/heavy checks, preserve the current files, and record pending tests and the limiting window's reset time here.
- After a quota pause, wait until that reset time has passed and a live check confirms at least 10% remaining. The existing thread automation checks every 30 minutes.
- Keep this note up to date so a resumed run does not repeat completed work. Do not assume a clean worktree or overwrite another editor's changes.
- Commit and push only scoped, verified work to the existing `kitesik/EvoBar` repository. Check CI before marking a slice complete.

## Verification scope

- Eight pure geometry regressions and the full 99-test suite passed without changing actual monitor settings.
- Isolated native review passed across all six languages for the first slice (312 renders), then English/Korean/French for the feedback follow-up (168 renders). No user logs or desktop capture were used.
- Both slices passed Universal 2 packaging and isolated launch smoke checks. Check the latest GitHub CI before starting the next slice.
- Real VoiceOver/key interaction and physical monitor unplug/replug remain manual acceptance unless directly exercised.

## Quota pause

- Waiting for reset: yes. The final live check showed 10% five-hour allowance remaining; no new development block was started at that boundary.
- Resume not before: 2026-09-09T10:43:43Z (2026-09-09 19:43:43 Asia/Seoul), five-hour `resetsAt` 1788950623. Recheck actual five-hour and weekly allowance after this time; do not use reset credits.
- Unfinished local checks or failing tests: none. Both code commits passed remote CI. The remaining automation is ACTIVE with 30-minute checks; keep it active while waiting for quota recovery.

## Next scoped slice

- The feedback commit's GitHub CI passed. The renderer now expects 29 dark images per locale (field guide added, light pass removed with the dark glass panel). Do not repeat these completed changes.
- Next: consider an explicitly isolated, temporary interactive app harness for real keyboard/assistive-technology checks. Existing rendering tests are not click or VoiceOver acceptance. Do not test by mutating the user's running companion.
- Concrete remaining layout check: the standalone SwiftUI Settings scene still requests a fixed 420-by-700-point size. The status-item and detached dashboard paths now adapt; evaluate the standalone Settings path separately on short displays without changing system display settings.
- Preserve the current limits: no real dialog interactions with user data, no new services or artwork. Physical display and assistive-technology acceptance still require a genuine interactive check; do not mark them passed from static renders.

## Latest Codex verification, 2026-09-10

- See [[NATIVE_UI_QA_2026-09-10]] before resuming. The scanner fix and standalone Settings sizing are already complete; the older next-task text above is superseded for those items.
- Latest remote code passed CI, and a clean checkout passed 103 tests plus 58 English/Korean dark renders and existing native checks. The attempted in-process accessibility/sheet test could not find the hosting view's children; it was removed and is not a passing acceptance check.
- The Drive mirror has stale HEAD/mixed working files and pre-existing staged changes. It was preserved. Use a clean, verified remote checkout for further source work if that condition remains, and do not bulk-stage the mirror.
- Continue the existing 10% guard and natural-reset automation. No new quota pause was recorded at this checkpoint; no reset credits were used.

## Interactive follow-up, 2026-09-10

- [[INTERACTIVE_UI_REVIEW]] records the new opt-in fixture app and the successful English/Korean out-of-process Collection open/dismiss/search checks. Do not repeat the removed in-process accessibility-tree experiment.
- Fixed Collection accessibility copy: unhatched lines no longer announce stage zero, and unavailable-art lines announce Coming soon. The renderer now checks four summary states. All source edits preceded the passing full suite and English/Korean renderer.
- The clean checkout holds the implementation; the mixed Drive mirror and its staged changes are preserved. Source patch and this note are saved separately in the Drive project. Confirm the code commit's CI and packaging before treating the slice as fully handed off.
- Keep the current quota guard/automation. No reset credits, public release, live payments, user-data tests, or new artwork were used.

## Current weekly quota pause, 2026-09-10 11:30 Asia/Seoul

- Live allowance: five-hour 99% remaining; weekly 4% remaining. No development or heavy verification started. Weekly `resetsAt` 1789454767 is 2026-09-15 15:46:07 Asia/Seoul (2026-09-15T06:46:07Z). Resume only after that deadline and after both live windows show at least 10% remaining. Keep heartbeat `evobar` ACTIVE; do not redeem reset credits.
- The previous local quota checkpoint is absent from the currently observed file. This append restores only the waiting condition, preserving all other content and the Git index. Read [[INTERACTIVE_UI_REVIEW]] for latest source and verification notes before selecting work.
- Code `eecb81f` and checkpoint `46e8025` were pushed. Tests, EN/KO renders, Universal 2 packaging and isolated launch smoke passed. GitHub CI 34381962168 remains to be confirmed after recovery. Actual VoiceOver speech remains untested. Verify the current Git state before resuming and preserve existing changes.
