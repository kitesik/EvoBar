# EvoBar artwork provenance

EvoBar must use original artwork and must not copy third-party game characters, names, silhouettes, sprites, or APIs.

## Current scope — 2026-09-23

Seven active lines: Cat, Dog, Fox, Capybara, Raptor, Mammoth and Pterosaur. The packaged inventory is51 forms,102 normal/Shiny variants,408 state PNGs and102 four-frame motion strips. Dragon/Phoenix/Kirin runtime PNGs are preserved outside the app in [RetiredRuntime](Artwork/RetiredRuntime/README.md); original sources are untouched.

Personality V2 redesign is92/102 variants complete. Pterosaur4–8 still use legacy artwork, so motion-coverage success must not be described as finished V2 art. See [STATUS.md](Artwork/Sources/PersonalityV2/STATUS.md). All dated sections below are historical provenance; their former ten-line counts and hybrid-motion limitations are superseded.

## Current coverage and hybrid motion — 2026-09-19

All ten lines now have dedicated normal and Shiny artwork: **72 forms × two colours × four states = 576 PNGs**. This wave adds Fox, Kirin, Raptor, Pterosaur, Dragon and Phoenix variants (176 state PNGs). Earlier normal art and the four shipped Shiny lines are untouched. Idle, working, evolution-ready and sleeping each retain a dedicated state image. Sources, exact built-in prompts and extraction hashes are in [ShinyV1](Artwork/Sources/ShinyV1), particularly [the first three prompts](Artwork/Sources/ShinyV1/REMAINING-20260919.md) and [the final wave/rejected attempts](Artwork/Sources/ShinyV1/FINAL-WAVE-20260919.md).

Motion is **hybrid, not 144 hand-drawn cycles**. The 42 quadruped forms in both colours retain the existing procedural walk/trot rig. Raptor, Pterosaur, Dragon and Phoenix add 60 dedicated four-frame strips (240 distinct authored frames), including both colours of every stage. Their source atlases and exact prompts are in [MotionV1](Artwork/Sources/MotionV1/PROMPTS.md). Menu bar, Home and desktop companion share the same exact-variant playback. Sleeping, Power Saver and Reduce Motion show a still pose. Evolution-ready reuses the motion loop with the existing celebration treatment; it is not a second authored cycle. No UI feature or growth/save rule was added.

The Fox alternate sheet is an identity-preserving colour edit of the existing normal atlas. The earlier attempts to show nine separately countable tips in every pose were rejected. The selected sheet preserves the existing silhouette instead; **an anatomical redraw proving nine visible tips in each pose remains a separate art refinement**, not a claim of this delivery. No unapproved manual raster editing was used.

The importer conserves source alpha, uses a common scale across four phases, and never manufactures in-between images. Hand-authored phases are not fed through the leg rig. Coverage tests require all 576 state resources, all 60 non-quadruped strips and motion policies for all 144 form/colour combinations. The opt-in `EVOBAR_REQUIRE_COMPLETE_ARTWORK=1` / `allSeventyTwoFormsHaveBothAuthoredMotionVariants` test remains a deliberately stricter **future all-authored** target and will fail with this hybrid implementation; it must not be reported as passed.

```bash
swift Scripts/prepare-art-atlas.swift --export --shiny Artwork/Sources/ShinyV1/*.png
swift Scripts/prepare-motion-atlas.swift --export Artwork/Sources/MotionV1/normal/*.png
swift Scripts/prepare-motion-atlas.swift --export --shiny Artwork/Sources/MotionV1/shiny/*.png
swift Scripts/review-artwork.swift --shiny
swift Scripts/review-motion.swift --expected-count 60
```

The following dated checkpoints are historical inventories, not the current coverage.

## Earlier companion art: Atlas V2, 2026-09-11

### Mammoth Shiny extension, 2026-09-11 evening

Mammoth adds seven authored Shiny forms and 28 state PNGs. Dedicated Shiny coverage is now four lines, 28 forms and 112 state PNGs; the other six lines keep their normal-art fallback. The accepted atlas uses a pearl-platinum to blue-slate progression with aurora color restricted to the final form's tusks. [MAMMOTH.md](Artwork/Sources/ShinyV1/MAMMOTH.md) records the exact built-in generation prompt, untouched source and alpha-preserving extraction provenance.

Coverage and gait tests include all 28 Shiny quadruped forms with their existing thresholds unchanged. Native review adds stage-four Home, final-form Home and discovered detail journey for Mammoth (37 screens per locale). Remaining: six dedicated Shiny lines and authored biped/wing frame cycles. Fox still requires a separate anatomical redraw with nine clearly counted tails.

### Capybara Shiny extension, 2026-09-11 afternoon

Capybara adds seven authored Shiny forms and 28 state PNGs. Dedicated Shiny coverage is now three lines, 21 forms and 84 state PNGs; the other seven lines keep their normal-art fallback. Normal Atlas V2 and the earlier 56 Cat/Dog Shiny resources are unchanged. [CAPYBARA.md](Artwork/Sources/ShinyV1/CAPYBARA.md) holds the exact built-in generation prompt, untouched source and extraction provenance. The peach/apricot and mint palette is a fresh alternate illustration, not a pixel-identical recolour.

Coverage and gait tests include all 21 Shiny quadruped forms. Native review adds the stage-four Home, final-form Home and discovered detail journey (34 screens per locale). Fox drafts were deliberately not shipped: the legendary stages still fail the nine-visible-tail requirement, and a targeted edit introduced an opaque checkerboard. Those drafts and prompts are quarantined in the separate Drive delivery. Next: another unfinished Shiny line; Fox needs a dedicated anatomical redraw, not another repetition of the rejected whole-sheet edit. Biped/wing frame cycles remain separate unfinished work.

The following starter checkpoint describes the earlier two-line state.

The Capybara detail review also caught a pre-existing normal/Shiny mismatch. Collection tiles, detail headers/journeys and pins now share the same representative individual and variant. The species field guide remains normal artwork by design. A lower-stage Shiny is never used to reveal a later Shiny form reached only by another normal individual.

### Starter Shiny extension, 2026-09-11

Cat and Dog now ship with 14 dedicated alternate forms and 56 state poses, declared with optional `hasShinyArtwork` in the animal manifest. Older catalogs and the other eight lines retain their normal-art fallback. These are newly generated alternate illustrations, not pixel-identical recolours; no normal sprite was modified. Cat uses moonstone/silver and slate, Dog pearl/ivory and champagne. [ShinyV1/PROMPTS.md](Artwork/Sources/ShinyV1/PROMPTS.md) records the exact accepted prompts, built-in generation mode and two rejected opaque Cat edit attempts. The importer now rejects images without a real alpha channel before slicing.

```bash
swift Scripts/prepare-art-atlas.swift --export --shiny Artwork/Sources/ShinyV1/*.png
swift Scripts/review-artwork.swift --shiny
```

The normal and Shiny coverage/gait checks are parameterized; the native renderer adds Shiny Home and Collection, bringing it to 31 screens per locale. The package verifier checks every declared Shiny stage and state too. Pending: dedicated Shiny art for the remaining eight lines and authored biped/wing cycles.

All 10 current manifest lines now have their own original illustrations: 72 forms × four states = 288 transparent PNGs. The six previously undrawn lines and eight recoloured placeholder stages are replaced. Stable IDs, thresholds, ownership and user records are unchanged. The earlier sheet/pending sections below are historical provenance, not the current generation procedure.

- Untouched generated originals: `Artwork/Sources/AtlasV2/*.png` (10 sheets).
- Exact prompts, tool/mode and input policy: [PROMPTS.md](Artwork/Sources/AtlasV2/PROMPTS.md). Built-in image generation; no third-party references.
- Extraction records: adjacent JSON files contain the source hash, each crop's bounds, dimensions and exact alpha conservation totals.
- Runtime assets: `Sources/EvoBarCore/Resources/Sprites/*.png`, 288 normal-state PNGs plus 56 dedicated Cat/Dog Shiny poses. The other eight lines still fall back to normal artwork for Shiny.
- Each form has idle, working, evolution-ready and sleeping poses. These are state illustrations, not a hand-drawn multi-frame walk/wing cycle. Existing procedural quadruped motion is retained; raptors explicitly use biped body motion and are never sent through the four-leg rig.
- The runtime crops retain every nontransparent source pixel, original colour/alpha and 12 pixels of transparent padding. Body-connected segmentation with simultaneous alpha-edge growth prevents faint bridges from merging neighbours. A missing/merged form fails before that atlas is exported. It is not safe to use a fixed equal grid on these sheets.
- Tests require all 288 resources, unique pose bytes, a transparent border and complete manifest coverage; gait tests also cover all 42 quadruped forms. Pixel tests do not certify anatomy or artistic quality; runtime contact sheets and native app views must also be reviewed.

From the repository root, regenerate and review with:

```bash
swift Scripts/prepare-art-atlas.swift --export Artwork/Sources/AtlasV2/*.png
swift Scripts/review-artwork.swift
./Scripts/check.sh
./Scripts/review-ui.sh en ko
```

The review command writes dark/light overview and four-state sheets to `build/art-review/`. The original five-column extractor below is archive-only; do not run it into the live sprite directory. The legacy placeholder utility now refuses to overwrite any existing target.

## Application icon

- Source: `Packaging/AppIconSource.png`
- Distribution asset: `Packaging/AppIcon.icns`
- Created: 2026-09-04 and revised 2026-09-05 with OpenAI’s built-in image generation tool for this repository
- Edit input: the project’s own first EvoBar icon only
- Third-party reference images supplied to image generation: none
- Text, logos, and third-party character assets in the generated image: none

Generation prompt:

> Create an original premium macOS app icon for a menu-bar companion that grows as the user works with AI. Use a midnight-indigo to violet rounded-square tile, a completely original tiny animal-companion emblem combining a paw-like silhouette, an upward evolution spark, and a subtle menu-bar line. Keep it friendly, simple at 16 px, and free of text, brand marks, Pokémon, or recognizable copyrighted characters.

Revision prompt summary:

> Preserve the original EvoBar rounded-square, cosmic palette, glass edge, and menu-bar line. Replace the central mascot with a large, original amber pixel-art kitten peeking over the line, with a four-point evolution spark and curled tail. Keep it legible at small sizes and do not copy any RunCat frame, pose, silhouette, markings, palette, logo, or third-party game motif.

Regenerate the `.icns` file after changing the source PNG:

```bash
./Scripts/generate-app-icon.sh
```

## Cat evolution sprites

- Generated source: `Artwork/Sources/CatEvolutionSpriteSheet.png`
- Runtime assets: `Sources/EvoBarCore/Resources/Sprites/cat.*.png`
- Created: 2026-09-05 with OpenAI’s built-in image generation tool for this repository
- Layout: five evolution-stage columns by four state rows (`idle`, `working`, `evolutionReady`, `sleeping`)
- Extraction: deterministic alpha-bounds crop through `Scripts/extract-sprite-sheet.swift`
- Third-party reference images supplied to image generation: none

Public RunCat product screenshots and documentation were reviewed only to identify general menu-bar constraints: a compact side-profile subject, immediate silhouette readability, and short keyframe-like state changes. No RunCat bitmap, source asset, frame geometry, character outline, marking, or color palette was used as an input or incorporated into EvoBar.

Generation prompt summary:

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Kitten → House Cat → Wildcat → Tiger → Astral Tiger lineage. Columns show evolution; rows show idle, focused working/trotting, evolution-ready with a four-point spark, and curled sleeping poses. Use charcoal-indigo outlines, warm amber and cream, with restrained violet/cyan starlight only for the final stage. Keep silhouettes readable at 18–24 px. Do not copy RunCat or any existing game character, pose, frame, markings, or palette; include no text, logos, watermark, or franchise motif.

## Dog evolution sprites

- Generated source: `Artwork/Sources/DogEvolutionSpriteSheet.png`
- Runtime assets: `Sources/EvoBarCore/Resources/Sprites/dog.*.png`
- Created: 2026-09-05 with OpenAI’s built-in image generation tool for this repository
- Layout and provenance constraints: identical to the Cat sheet above
- Third-party reference images supplied to image generation: none

Generation prompt summary:

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Puppy → Dog → Wolfdog → Dire Wolf → Fenrir lineage. Columns show evolution; rows show idle, focused working/trotting, evolution-ready with a four-point spark, and curled sleeping poses. Use charcoal-indigo outlines, copper-brown and cream for early stages, slate shadow fur for Dire Wolf, and restrained violet/cyan aurora accents for Fenrir. Keep silhouettes readable at 18–24 px and visually distinct from the Cat family. Do not copy RunCat or any existing game character, pose, frame, silhouette, markings, or palette; include no text, logos, watermark, chains, or franchise motif.

## Fox evolution sprites

- Generated source: `Artwork/Sources/FoxEvolutionSpriteSheet.png`
- Runtime assets: `Sources/EvoBarCore/Resources/Sprites/fox.*.png`
- Created: 2026-09-05 with OpenAI’s built-in image generation tool for this repository
- Layout and provenance constraints: identical to the Cat sheet above
- Third-party reference images supplied to image generation: none

Generation prompt summary:

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Fox Kit → Red Fox → Silver Fox → Nine-Tailed Fox → Celestial Fox lineage. Columns show evolution; rows show idle, working/running, evolution-ready/glowing, and sleeping poses. Use warm red-orange for early stages, silver-gray in the middle, and restrained teal/gold celestial accents for later stages. Keep the grid regular and silhouettes readable at menu-bar size. Do not copy any existing app, game, franchise, character, sprite, pose, palette, or identifiable design; include no text, logos, watermark, scenery, or grid lines.

## Capybara evolution sprites

- Generated source: `Artwork/Sources/CapybaraEvolutionSpriteSheet.png`
- Runtime assets: `Sources/EvoBarCore/Resources/Sprites/capybara.*.png`
- Created: 2026-09-05 with OpenAI’s built-in image generation tool for this repository
- Layout and provenance constraints: identical to the Cat sheet above
- Third-party reference images supplied to image generation: none

Generation prompt summary:

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Capybara Pup → Capybara → Giant Capybara → Mossback Capybara → Hot-Spring Spirit lineage. Columns show evolution; rows show idle, working/trotting, evolution-ready with a contained glow, and sleeping poses. Use chestnut and tan early stages, earthy olive moss at stage four, and restrained steam-white, mineral teal, and coral light for the final spirit. Keep exact regular cells and readable menu-bar silhouettes. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, containers, logos, or watermark.

Regenerate the runtime crops after intentionally replacing the checked-in source sheet:

```bash
./Scripts/extract-sprite-sheet.swift \
  Artwork/Sources/CatEvolutionSpriteSheet.png \
  Sources/EvoBarCore/Resources/Sprites \
  cat

./Scripts/extract-sprite-sheet.swift \
  Artwork/Sources/DogEvolutionSpriteSheet.png \
  Sources/EvoBarCore/Resources/Sprites \
  dog

./Scripts/extract-sprite-sheet.swift \
  Artwork/Sources/FoxEvolutionSpriteSheet.png \
  Sources/EvoBarCore/Resources/Sprites \
  fox

./Scripts/extract-sprite-sheet.swift \
  Artwork/Sources/CapybaraEvolutionSpriteSheet.png \
  Sources/EvoBarCore/Resources/Sprites \
  capybara
```

Future animal sprites require the same provenance record before inclusion in a public release.

## Pending sprite sheets (manifest lines without artwork)

The six lines below exist in `animals.v1.json` and the storefront but have no runtime sprites yet; they render as their menu-bar emoji until a sheet is generated, cropped through `Scripts/extract-sprite-sheet.swift` (which needs a grid entry per animal ID), and recorded above with the same provenance fields. Stage designs follow real anatomy where the animal is real and classical descriptions where it is mythical, so that the evolution reads correctly to people who know the animals.

### Raptor (dromaeosaur)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Downy Hatchling → Velociraptor → Deinonychus → Utahraptor → Thunderclaw Tyrant lineage, drawn as feathered dromaeosaurs in current paleontological reconstruction: pennaceous arm feathers, a fan of tail feathers on a stiffened tail, the enlarged second-toe sickle claw held off the ground, horizontal body posture, no pronated “bunny” hands. Stage one is a fluffy chick with oversized feet; stage two is turkey-sized with a long low snout; stage three grows taller with a deeper skull; stage four is a heavy bear-sized predator; stage five keeps the same anatomy with storm-blue iridescent plumage and faint lightning along the claw. Columns show evolution; rows show idle, working/running with tail level, evolution-ready with a raised sickle claw and glow, and sleeping curled bird-like with head tucked. Use rust, ochre and cream, darkening to slate at stage four. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, logos, or watermark.

### Mammoth (Mammuthus primigenius, growth stages of one species)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Mammoth Calf → Tusk-Bud Yearling → Woolly Mammoth → Great Tusker → Aurora Mammoth lineage, drawn as a woolly mammoth growing up rather than as different species: small ears, a high domed head, a sloping back to a short tail, a shaggy two-layer coat with long guard hairs, and a fat hump over the shoulders that grows with age. Stage one is a round calf with a short trunk and no tusks; stage two shows tusk buds and a fuller coat; stage three is a full adult with curved tusks; stage four is an old bull with very long tusks that spiral inward and nearly cross, and a worn, darker coat; stage five keeps the same body with frost-white fur tips and an aurora shimmer along the tusks. Columns show evolution; rows show idle, working/walking, evolution-ready with a raised trunk and glow, and sleeping standing or kneeling. Use warm umber, chestnut and ivory, cooling to glacier blue only at the final stage. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, logos, or watermark.

### Pterosaur (Rhamphorhynchus → Pteranodon → Quetzalcoatlus)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Flapling → Rhamphorhynchus → Pteranodon → Quetzalcoatlus → Solar Quetzal lineage, drawn as pterosaurs, not birds or bats: a membrane wing stretched from an elongated fourth finger, three small free fingers on the leading edge, a pycnofiber fuzz coat, and a quadrupedal stance on the ground with folded wings used as forelimbs. Stage one is a newly hatched flapling already able to glide; stage two has a long stiff tail ending in a diamond vane and a toothed jaw; stage three is toothless with a long backward head crest and a very short tail; stage four is a giraffe-tall azhdarchid with an enormous beak, long neck and legs, and the widest wings on the sheet; stage five keeps the azhdarchid form with sunrise gold membranes and a soft solar halo at the crest. Columns show evolution; rows show idle standing on all fours, working/soaring, evolution-ready with wings half-open and glow, and sleeping folded like a tent. Use sky teal, slate and bone white, warming to amber and gold at the last stage. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, logos, or watermark.

### Dragon (Western dragon, limb count changes by stage)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Wyrmling → Drake → Wyvern → Dragon → Elder Dragon lineage, using the classical distinction between dragon kinds: stage one is a wet-winged hatchling with an egg tooth and oversized eyes; stage two is a wingless four-legged drake with a low lizard-like gait and a crocodile-textured back; stage three is a wyvern with two legs and bat-like membrane wings that serve as forelimbs, a barbed tail, and a narrow snout; stage four is a true six-limbed dragon with four legs plus wings, backward-curving horns, a throat that glows before breathing fire, and layered scales; stage five is the same dragon grown ancient, with lichen and moss on its back plates, chipped horns, crystal growths along the spine, and slow embers instead of open flame. Columns show evolution; rows show idle, working/prowling, evolution-ready with a glowing throat, and sleeping coiled with the tail over the nose. Use deep crimson and charcoal with brass horns, greying toward verdigris at the elder stage. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, treasure, logos, or watermark.

### Phoenix (bird anatomy, moult as rebirth)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Ember Chick → Cinder Fledgling → Phoenix → Solar Phoenix → Eternal Phoenix lineage, drawn with real bird anatomy: a chick with sparse ash-grey down and a faintly glowing throat; a fledgling in patchy moult with cinder-black juvenile feathers giving way to red and gold; an adult with long tail streamers and a small crest in the manner of a quetzal or bird-of-paradise, heat shimmer at the wingtips; a solar adult with a radiating gold crest and primaries that fade to white heat; and a final stage shown mid-rebirth, an adult body rising through a ring of ash with a few newborn flames along the wings. Columns show evolution; rows show idle perched, working/flying, evolution-ready with wings raised and glow, and sleeping with the head under a wing. Use ash grey, ember red, marigold and white-gold. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, logos, or watermark.

### Kirin (East Asian qilin)

> Create an original transparent 5×4 pixel-art sprite sheet for EvoBar’s Spotted Fawn → Spirit Deer → Kirin → Cloud Kirin → Celestial Kirin lineage, following classical descriptions of the qilin: stage one is a real spotted fawn with a velvet nub where the horn will grow; stage two is a young deer with slender legs, cloven hooves, a few scale patches on the shins and a single antler-velvet horn; stage three is a full kirin with a deer body covered in fine dragon-like scales, an ox-like tufted tail, a flowing mane, a single backward-curving horn, and small flame wisps at the shoulders and hocks; stage four walks on small clouds because a kirin is said never to bend the grass, with a longer mane and pale gold scales; stage five keeps the same form with starlit scales and a soft halo around the horn. Columns show evolution; rows show idle standing, working/trotting, evolution-ready with head raised and glow, and sleeping lying with legs folded. Use fawn tan and cream with jade, gold and lavender accents, never the hard blue of a Western unicorn. Do not copy any existing app, game, franchise, character, sprite, pose, silhouette, markings, or palette; include no text, scenery, logos, or watermark.

## Extended ladders, 2026-09-09

The catalog now runs seven stages for cat, dog, fox, capybara, mammoth, dragon, phoenix and kirin, and eight for raptor and pterosaur. The four illustrated lines keep their five drawn forms under new stage numbers; a stage without its own sheet borrows the form below it and is marked `artworkPending: true` in `animals.v1.json`. Nothing here needs new motion work: the gait, the menu bar frames and the desktop pet are synthesized from a single sprite per state.

Hand-off for each new sheet:

1. Generate the sheet from the brief below (columns are stages in order, rows are `idle`, `working`, `evolutionReady`, `sleeping`).
2. Add a calibrated `SpriteGrid` entry for the animal id in `Scripts/extract-sprite-sheet.swift` (column edges for seven or eight columns, row edges, working/evolution split per column) and run the extraction into `Sources/EvoBarCore/Resources/Sprites`.
3. Point every stage at its own asset id (`<animal>.<index>` and `<animal>.<index>.shiny`) and remove `artworkPending`. ManifestTests checks that borrowing stages are flagged and that illustrated lines cover every stage.
4. Record provenance above in the same form as the existing sheets.

Shared constraints for every brief: an original transparent pixel-art sheet, regular cells, charcoal-indigo outlines, silhouettes readable at 18 to 24 px, side profile facing right, no text, scenery, logos or watermark, and no copy of any existing app, game, franchise, character, sprite, pose, silhouette, markings or palette.

### Cat, seven columns

> Kitten → House Cat → Wildcat → Lynx → Tiger → Smilodon → Astral Tiger. Keep the existing amber-and-cream cat family. The lynx (column four) has black ear tufts, a bobbed tail, long legs and broad furred paws in grey-buff with faint spots; the tiger (five) is the largest living cat, orange with black stripes; Smilodon (six) is a heavy, short-tailed, bear-shouldered cat with two 28 cm sabre canines that show below the closed jaw, in a tawny coat; the astral tiger (seven) keeps the tiger's body with restrained violet and cyan starlight. Rows: idle, trotting, evolution-ready with a four-point spark, curled sleeping.

### Dog, seven columns

> Puppy → Dog → Wolfdog → Gray Wolf → Dire Wolf → Epicyon → Fenrir. Keep the copper-brown and cream dog family. The gray wolf (four) is a lean grey-brown wolf with a straight tail and long legs; the dire wolf (five) is heavier with a broader head and slate shadow fur; Epicyon (six) is the largest dog that ever lived, lion-sized with a deep, short-snouted, bone-crushing skull and a thick neck, in tawny grey; Fenrir (seven) keeps the wolf body with restrained violet and cyan aurora accents. Rows: idle, trotting, evolution-ready with a spark, curled sleeping.

### Fox, seven columns

> Fox Kit → Red Fox → Silver Fox → Qiu's Fox → Snow Fox → Nine-Tailed Fox → Celestial Fox. Qiu's fox (four) is a large-jawed ancient fox from the Tibetan plateau in pale sand and grey with a bushy tail; the snow fox (five) is a compact arctic fox in winter white with a rounded face and short ears; the nine-tailed fox (six) is a slender fox with nine tails fanned behind it in silver and teal; the celestial fox (seven) adds restrained gold and teal light. Rows: idle, running, evolution-ready glowing, sleeping.

### Capybara, seven columns

> Capybara Pup → Capybara → Giant Capybara → Mossback Capybara → Phoberomys → Josephoartigasia → Hot-Spring Spirit. Phoberomys (five) is a cow-sized rodent with a long body, blunt head and short legs in olive brown; Josephoartigasia (six) is the one-tonne rodent, deeper-bodied with a huge head and long incisors, in dark umber; the hot-spring spirit (seven) keeps the giant body with steam-white fur tips and mineral-teal light. Rows: idle, trotting, evolution-ready with a contained glow, sleeping.

### Raptor, eight columns

> Downy Hatchling → Microraptor → Velociraptor → Deinonychus → Achillobator → Dakotaraptor → Utahraptor → Thunderclaw Tyrant. Feathered dromaeosaurs in current reconstruction: pennaceous arm feathers, a tail fan, the sickle claw held off the ground, horizontal posture. Microraptor (two) is crow-sized with four wings, long leg feathers included, in iridescent black; Velociraptor (three) is turkey-sized with a long low snout; Deinonychus (four) taller with a deeper skull; Achillobator (five) heavy-hipped and thick-heeled; Dakotaraptor (six) tall and long-armed with large wing feathers; Utahraptor (seven) bear-sized and slate-dark; the thunderclaw tyrant (eight) keeps that anatomy with storm-blue plumage and faint lightning along the claw. Rows: idle, running with tail level, evolution-ready with the sickle claw raised, sleeping bird-like with the head tucked.

### Mammoth, seven columns

> Mammoth Calf → Tusk-Bud Yearling → Woolly Mammoth → Great Tusker → Columbian Mammoth → Steppe Mammoth → Aurora Mammoth. One species growing, then its larger cousins: the Columbian mammoth (five) is taller than the woolly with a shorter, sparser coat and long crossing tusks; the steppe mammoth (six) is the largest, 4.5 m at the shoulder, with a high domed head and enormous spiralling tusks; the aurora mammoth (seven) keeps that body with frost-white fur tips and an aurora shimmer along the tusks. Warm umber and ivory, cooling to glacier blue only at the end. Rows: idle, walking, evolution-ready with the trunk raised, sleeping kneeling.

### Pterosaur, eight columns

> Flapling → Dimorphodon → Rhamphorhynchus → Pterodactylus → Pteranodon → Quetzalcoatlus → Hatzegopteryx → Solar Quetzal. Membrane wings on an elongated fourth finger, three small free fingers, pycnofiber fuzz, quadrupedal on the ground. Dimorphodon (two) has a deep puffin-like head and a long tail; Rhamphorhynchus (three) a diamond tail vane and needle teeth; Pterodactylus (four) a short tail and long toothed jaws; Pteranodon (five) toothless with a long backward crest; Quetzalcoatlus (six) giraffe-tall with an enormous beak; Hatzegopteryx (seven) as tall but far more robust, with a massive skull; the solar quetzal (eight) keeps the azhdarchid form with sunrise-gold membranes and a soft halo at the crest. Rows: idle standing on all fours, soaring, evolution-ready with wings half open, sleeping folded like a tent.

### Dragon, seven columns

> Wyrmling → Drake → Lindworm → Wyvern → Dragon → Elder Dragon → Primordial Dragon. The classical kinds in order: a wet-winged hatchling; a wingless four-legged drake; a lindworm (three) with two legs, no wings and a long serpentine body sliding on its belly; a wyvern with two legs and membrane wings as forelimbs; a six-limbed dragon with horns and a glowing throat; the elder dragon with moss on its plates and crystal along the spine; the primordial dragon (seven) keeps the elder's body with starlight leaking between its scales and embers gone cold blue. Deep crimson and charcoal with brass horns, greying to verdigris and then to indigo. Rows: idle, prowling, evolution-ready with a glowing throat, sleeping coiled.

### Phoenix, seven columns

> Ember Chick → Cinder Fledgling → Firebird → Phoenix → Great Phoenix → Solar Phoenix → Eternal Phoenix. Real bird anatomy throughout: a grey down chick; a patchy fledgling in cinder black turning red; the firebird (three) a full-plumaged bird with feathers that glow like lamps; the phoenix with long tail streamers and a small crest; the great phoenix (five) the same bird at a six-metre span with broad condor-like primaries; the solar phoenix with a radiating crest fading to white heat; the eternal phoenix mid-rebirth rising through a ring of ash. Ash grey, ember red, marigold and white gold. Rows: idle perched, flying, evolution-ready with wings raised, sleeping with the head under a wing.

### Kirin, seven columns

> Spotted Fawn → Red Stag → Irish Elk → Spirit Deer → Kirin → Cloud Kirin → Celestial Kirin. A real deer first: the fawn; a red stag (two) with a full rack; the Irish elk (three), Megaloceros, a huge deer with palmate antlers spanning wider than its body; then the spirit deer with a single velvet horn and scale patches; the kirin with fine dragon-like scales, a tufted tail and flame wisps at the hocks; the cloud kirin walking on small clouds with pale gold scales; the celestial kirin with starlit scales and a halo at the horn. Fawn tan and cream with jade, gold and lavender accents. Rows: idle standing, trotting, evolution-ready with the head raised, sleeping with legs folded.

## Placeholder recolours for the pending stages, 2026-09-10

- Runtime assets: `cat.4`, `cat.6`, `dog.4`, `dog.6`, `fox.4`, `fox.5`, `capybara.5`, `capybara.6` in all four states.
- Source: the project's own sprites of a neighbouring form, recoloured with Core Image hue, saturation and brightness adjustments by `Scripts/derive-placeholder-sprites.swift`. No image generation and no third-party input.
- Purpose: an evolution into one of these stages shows a visible change instead of the same drawing twice. They remain `artworkPending` in the manifest, the journey draws them with a dashed edge, and they are replaced wholesale when the sheets described above are extracted.

Regenerate after changing the source sprites:

```bash
swift Scripts/derive-placeholder-sprites.swift Sources/EvoBarCore/Resources/Sprites
```
