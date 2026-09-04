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
```

Future animal sprites require the same provenance record before inclusion in a public release.
