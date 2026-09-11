# Mammoth Shiny source

Generated on 2026-09-11 with the built-in image generation tool. This is an original EvoBar asset; no third-party character, sprite, API, name, silhouette, markings, or palette was used as a reference.

## Accepted prompt

```text
Use case: stylized-concept
Asset type: production sprite atlas for EvoBar, an original macOS animal companion
Primary request: Create ONE high-quality genuinely transparent PNG sprite sheet, EXACTLY 7 equal columns and FOUR equal rows, 7 by 4, exactly 28 separate mammoth drawings and no other cells. This is the dedicated Shiny alternate-art lineage; it must be a newly authored illustration, not a mechanical recolor.
Scene/backdrop: fully transparent alpha only
Subject: seven evolutionary mammoth forms, each repeated in four clear states. Columns left to right:
1 Mammoth Calf — round small calf, small ears, short trunk, no tusks.
2 Tusk-Bud Yearling — taller fluffy calf, longer trunk, two tiny ivory tusk buds.
3 Woolly Mammoth — umber-sized shaggy adult anatomy, domed head, high shoulder hump, curved tusks.
4 Great Tusker — broad old woolly bull, massive long inward-curving tusks.
5 Columbian Mammoth — visibly taller and longer-legged, sparser coat, long crossing tusks.
6 Steppe Mammoth — the largest, towering deep chest, high domed head, enormous spiralling tusks.
7 Aurora Mammoth — keeps the giant Steppe anatomy, especially large spiral tusks.
Rows top to bottom:
1 idle, alert standing;
2 working, brisk walking with trunk swinging and a clearly different leg pose;
3 evolution ready, proud with trunk raised and exactly ONE small contained four-point spark above the head;
4 peacefully sleeping, kneeling or curled, eyes closed and trunk curled.
Style/medium: premium hand-authored pixel-art illustration, crisp deliberate pixel clusters, coherent dark charcoal-indigo outlines, controlled cel shading, warm expressive eyes, readable at 24 px and detailed at 96 px, attractive progressively adult anatomy rather than seven babies.
Composition/framing: landscape canvas as large as practical; equal logical grid; each cell contains exactly one complete mammoth centered with at least 12% transparent padding on every side; all face RIGHT in clean side profile; generous transparent gutters and outer margin.
Color palette: a distinctive Shiny lineage independent from the normal brown art: stages 1–2 pearl cream and pale platinum with cool lavender-grey shadows; stages 3–4 moonlit silver-grey with muted periwinkle shadows; stages 5–6 deepen to blue-slate and pale glacier highlights; stage 7 is frost-white and luminous pale blue-grey with restrained aurora teal-to-violet color ONLY along the tusks and a few fur-tip highlights. Keep ivory tusks visible at stages 2–6. Maintain the same palette and markings within each column across all four rows.
Materials/textures: readable shaggy wool, solid connected feet, smooth ivory or aurora tusks, no translucent bodies.
Constraints: genuine transparent RGBA alpha; exactly 28 mammoths; every mammoth body must be one connected silhouette apart from the single row-three spark; each standing or walking pose must show FOUR short, clear, separate legs with open negative space under the belly and solid connected paws; no coat joining or hiding the legs; trunk, tusks, ears, tail and spark fully contained inside their own cell; no cropping or overlap across cells; preserve identical species anatomy, markings, palette and relative scale within each column across the four states; original design only.
Avoid: opaque, colored, white, black, or checkerboard background; shadow; floor; scenery; borders; grid lines; labels; text; logos; watermark; snow; broad glow; mist; loose pixel debris; orbital rings; ground particles; halos around feet; accessories; extra animals; detached body fragments; hidden legs; merged legs; tusks or trunks crossing cell boundaries; copying any existing game, app, franchise, character, sprite, silhouette, markings, or palette.
```

## Packaging

- Accepted untouched source: `Mammoth.png`
- Source dimensions: 1659 × 948, transparent RGBA
- Import command: `swift Scripts/prepare-art-atlas.swift --export --shiny Artwork/Sources/ShinyV1/Mammoth.png`
- Output contract: seven forms × four states under `Sources/EvoBarCore/Resources/Sprites/mammoth.*.shiny.*.png`
- The importer performs only alpha-preserving slicing, padding, and scaling. It does not recolor or invent artwork.
