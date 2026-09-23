# Pterosaur5 sources — 2026-09-23

Normal/Shiny four-phase motion and four-state portraits are exported to runtime resources. Built-in imagegen with stage4 normal motion as style reference. Normal motion output exec-1081a1e5-ed88-46ee-b7bc-e6596e8e9907.png. Installation evidence is in DEVELOPMENT_HANDOFF.md.

Prompt: four right-facing full-body flight phases in equal horizontal cells on real alpha; adult Pteranodon-inspired long toothless ochre beak/backward crest, short tail, cobalt body, sand membranes, cream throat/rust crest tip; tiny unimpressed eye for B-grade personality. Up/horizontal/down/return wing phases, consistent center/scale, pixel clusters, no extra arms/teeth/feathers/effects/text.

Dry-run importer passed four frames, no overlapping bounds/haze fragments, exact alpha preservation. Source SHA256 f02be21d6d2d1eb15a83044b84eba9bf759fc16649a7fced01238bcc9354e99a. Three border pixels have alpha1; no visible clipped extremity at source review. Review before exporting.

Rejected state output exec-ef5af776-7661-4be7-a1c2-ca16bbb5b8d3.png remains only in generated_images: idle has extra raised membrane-wing silhouette above folded wings, and ready neck has spiky protrusions. It was not imported.

Correction prompt: change only these defects: remove entire extra raised wing behind idle head, keep two folded forelimb wings and hind feet; remove orange neck spikes in ready pose, preserving one backward head crest and smooth neck. Keep palette, scale, other poses and alpha unchanged. Accepted output exec-20d9a32b-89cf-4e12-b183-1254400afc2a.png, visually checked for both corrections.

Shiny prompt: change only cobalt body to aubergine, sand membranes to icy lavender, rust tips to coral, keep ivory throat and peach-gold toothless beak; preserve four exact motion/state poses, silhouette and alpha, no extra limbs/effects. Motion exec-69372903-c0ad-4881-82c9-1f285daa8407.png, states exec-097fab68-7252-4ca5-b74a-ad4bc2b6c2ce.png. State generation uses corrected normal sheet plus Shiny motion as palette reference. All built-in imagegen, no CLI or procedural recolor.

All four importers passed exact source-alpha conservation,2 strips/8 state portraits. Shiny motion SHA256 f03b6a9dd5bd5234da2b37024d02b094f8f3d7978839e6c693753fabbedbb0d3, alpha57298868, zero border pixels/overlapping bounds/haze fragments. Production-decoder review102 strips passed; normal-dark/Shiny-light24/96px contact sheets inspected. No clipped wings; long crest differentiates stage5 from stage4. GIF generation/frame count is verified, not physical playback observation. Species-inspired fictional palette/expression, not a reconstruction or ancestry claim.
