# Pterosaur stage 4 candidate sources — 2026-09-23

Built-in image generation, not API/CLI. Project-owned stage3 motion was the style reference; stage4 motion was the state-sheet identity reference. Original outputs retained in Codex generated_images. Normal and Shiny sources have now been exported into runtime resources; installation evidence belongs in DEVELOPMENT_HANDOFF.md.

## Prompt specifications

- Motion: original Pterodactylus-inspired stage4 normal pixel-art; exactly four separated right-facing flight phases (up, horizontal, down, returning up), equal cells, common body scale/center, genuine transparent alpha and generous margins. Short stub tail without diamond vane, long tapered toothed jaw, elongated neck, membrane wing supported by fourth finger, two trailing hind feet; no extra arms, bird feathers, horns or large Pteranodon crest. Petrol body, salmon/terracotta membranes, cream throat, charcoal outline. Smug dot-eye and gawky feet retain B-grade humor without juvenile proportions. No text, scenery, effects or shadows.
- States: preserve the generated motion character and palette; four separated equal cells: quadrupedal folded-wing idle, horizontal flying working, proudly raised-wing evolution-ready with goofy grin, sleeping with folded wings like a tent. No additional arms or long tail, no effects/text/background. Genuine transparency.

Generation outputs: motion exec-70288384-e9c5-4c3b-955f-5473391d7b07.png; states exec-224e5c3b-e326-4598-900e-d4022774e993.png.

## Checks and remaining acceptance

- Both 2172×724 PNGs visually reviewed at source size. Four authored wing phases and four distinct state poses; species-inspired stylization, not a scientific reconstruction or real ancestral sequence.
- Motion importer dry-run passed: four frames, zero visible border pixels, zero overlapping bounds/haze fragments, alpha sum 43603097 preserved; SHA256 c79267da042dd643b34dc1e6e00dbb2b46792687b288d55c829e645adb413bd4.
- Both state sheets and both motion sheets exported with existing --single-stage --stage=4 importers. Source alpha was exactly conserved before resizing. Shiny motion SHA256 c21eaa6ffa9414e4d1ab85a90c536d803be69313eec6ebb7df663e68f6fda90d, alpha sum46204836, zero visible border pixels/overlapping bounds/haze fragments.
- Shiny prompt: edit only normal palette to mulberry-plum body, golden-apricot membranes and ivory throat; preserve the exact four poses, short tail, toothed muzzle, dot-eye grin, pixel clusters, spacing and transparent margins. No added effects, limbs, text or background. Motion output exec-21c2d958-8e7b-4056-9797-3f517b3f039c.png; state output exec-676658c3-fd88-47a5-8d9e-cb0f061eba23.png. Both generated with built-in imagegen, not procedural recoloring.
- Production decoder review passed102 strips/14 groups. Inspected normal-dark and Shiny-light contact sheets at24/96px: stage4 full wings remain within frame and four phases are visibly distinct. Animated GIFs generated/decoded as four120ms frames; physical playback observation is not claimed. Stages5–8 remain legacy.
- Anatomy reference consulted: [Natural History Museum pterosaur overview](https://www.nhm.ac.uk/discover/the-truth-about-pterosaurs.html), [Australian Museum pterodactyloid tail distinction](https://australian.museum/learn/animals/reptiles/mythunga-camara/). Palette and facial expressions are invented.
