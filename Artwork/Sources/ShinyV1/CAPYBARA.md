# Capybara Shiny artwork provenance

This record covers the original Capybara Shiny extension made on 2026-09-11: seven alternate forms and 28 transparent state poses. Normal Atlas V2 and the completed Cat/Dog Shiny images are unchanged. See [artwork provenance](../../../ARTWORK.md).

Mode: built-in image generation, fresh original generation. No third-party reference image, CLI fallback or paid API workflow. Source `Capybara.png` is untouched; `Capybara.json` records the SHA-256, crop bounds and exact alpha conservation. The accepted palette is pale apricot/peach, rose gold and muted mint. These are separate illustrations, not pixel-identical recolours.

Re-export with `swift Scripts/prepare-art-atlas.swift --export --shiny Artwork/Sources/ShinyV1/Capybara.png`; review with `swift Scripts/review-artwork.swift --shiny`.

## Accepted prompt

```text
Use case: stylized-concept. Asset type: production sprite atlas for EvoBar, an original macOS animal companion. Create ONE high-quality transparent PNG sprite sheet, EXACTLY 7 columns and FOUR rows, 7 by 4, exactly 28 separate complete animals. Large LANDSCAPE canvas. Each cell contains exactly one complete animal, isolated with at least 12% empty padding. All facing RIGHT in clean side profile. Columns are evolutionary forms; preserve the same species anatomy and palette across all four poses in each column.
Rows top to bottom: 1 idle alert standing; 2 working brisk walk with visibly different leg pose and a lifted front paw; 3 evolution ready proud lifted head and ONE small four-point spark above head; 4 peacefully sleeping folded down with eyes closed.
Style: premium original illustrated pixel-cluster art, crisp deliberate fur clusters, clean dark charcoal-indigo outlines, controlled cel shading, warm readable faces, detailed but uncluttered adult forms. Readable at 24px, attractive at 96–192px. Not a photograph, not glossy 3D.
This is a distinct SHINY colorway. Across all stages use warm pale peach, apricot-cream and rose-gold fur with muted slate-lavender shadow accents. No chestnut-brown ordinary palette. The large stages remain recognisably different creatures, not just scaled copies.
Seven columns, left to right:
1 Capybara Pup: small pale-apricot baby, blunt rectangular rodent snout, tiny round ears, four clearly separated, visibly exposed legs; the belly must sit well above the paws, cream muzzle and belly.
2 Capybara: relaxed peach-and-cream adult with a long barrel torso, broad flat blunt muzzle, no visible tail, small ears.
3 Giant Capybara: heavier mature body with broad shoulders, rose-gold dorsal fur, cream side and muzzle, visibly more imposing than column 2.
4 Mossback Capybara: sturdy peach-cream capybara with a SMALL patch of soft muted mint/sage moss only on the upper back. No moss on belly or feet, no hanging foliage.
5 Phoberomys: huge prehistoric rodent, long body, longer legs and strong hindquarters, distinctive long head, warm pale apricot with subtle lavender shadows. Not the same short-headed round animal as column 3.
6 Josephoartigasia: exceptionally deep-bodied massive prehistoric rodent, huge broad blunt head, thick neck, prominent pale incisors, rose-gold shoulders and cream face. Clearly different proportions from Phoberomys.
7 Hot-Spring Spirit: serene giant capybara with pearly pale peach fur, subtle rose-gold and pale mint mineral markings, a tiny mint forehead mark. No steam or mist. A neat SHORT coat under belly and FOUR distinct clear feet, never a fur skirt. No bath or objects.
Genuine transparent RGBA alpha background, NO opaque or colored or checkerboard background. NO cast shadow, NO floor, NO scenery, NO text, labels, border, grid lines, logo or watermark. No broad glows, fog, pixel debris, orbital rings, particles or shadows around feet. All quadrupeds need four clear medium-length connected legs and generous open transparent space underneath the belly; never conceal the legs with fur. Every ear, foot, body and sparkle must remain inside its cell and away from canvas edges. Clear transparent gaps between all 28 animals. Original EvoBar animals only, no existing game/app/franchise character.
Important anatomy check for column 1, the PUP: show four substantial exposed legs. From belly underside to paw baseline should be about 15–18% of the visible animal height, with wide clean transparent space between the hind and front legs. Keep the baby capybara head and round body, but do not draw a low body resting on almost invisible toe stubs. The idle pup must stand fully upright with its belly CLEAR of its four paws. Apply the same visible leg length to the working and ready pup. Sleeping remains naturally folded. Keep the adult bodies stout and capybara-like, not deer or long-legged dogs.
```

## Rejected first Capybara atlas

The first Capybara atlas was also replaced before shipping: `capybara.1.shiny` had a standing leg ratio of 0.04698, below the unchanged 0.06 minimum. A fresh transparent generation raised the pup's belly and produced a ratio of 0.08118; all seven standing poses passed the same diagnostic. The original rejected atlas, exact prompt and failing test log are quarantined in the Drive delivery. Full gait/UI/package verification must use the revised PNG and its adjacent metadata.

## Deferred Fox work

Three earlier Fox attempts in this work session were not accepted or bundled: the full transparent sheet did not make nine tail tips clear enough in the legendary stages; its targeted edit also baked in an opaque checkerboard; a larger two-column legendary sheet still did not satisfy the tail-count check. The drafts and exact prompts are quarantined in the separate Drive delivery for review, not in runtime resources. Fox retains its existing normal-art fallback. Do not treat a non-nil alpha channel as proof that every empty pixel is actually transparent, and do not mark anatomical accuracy passed from segmentation counts.
