# EvoBar artwork provenance

EvoBar must use original artwork and must not copy third-party game characters, names, silhouettes, sprites, or APIs.

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
