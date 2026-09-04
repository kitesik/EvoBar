# EvoBar artwork provenance

EvoBar must use original artwork and must not copy third-party game characters, names, silhouettes, sprites, or APIs.

## Application icon

- Source: `Packaging/AppIconSource.png`
- Distribution asset: `Packaging/AppIcon.icns`
- Created: 2026-09-04 with OpenAI’s built-in image generation tool for this repository
- Third-party reference images: none
- Text, logos, and third-party character assets in the generated image: none

Generation prompt:

> Create an original premium macOS app icon for a menu-bar companion that grows as the user works with AI. Use a midnight-indigo to violet rounded-square tile, a completely original tiny animal-companion emblem combining a paw-like silhouette, an upward evolution spark, and a subtle menu-bar line. Keep it friendly, simple at 16 px, and free of text, brand marks, Pokémon, or recognizable copyrighted characters.

Regenerate the `.icns` file after changing the source PNG:

```bash
./Scripts/generate-app-icon.sh
```

Future animal sprites require the same provenance record before inclusion in a public release.
