# Owner-direction concept checkpoint (2026-09-24)

The five `*-evolution-concept-v1.png` files are **design candidates**, not runtime sprite sheets. They are not imported by the app, animated, or approved as final art. The existing asset pipeline and saved user data are unchanged. The active catalog also includes Mammoth and Pterosaur; separate uncommitted drafts for those lines belong to another editor and were not copied or altered here.

The owner-approved direction is: the early forms have awkward, expressive B-movie charm; later forms become recognizably mature and striking while retaining a small mischievous imperfection. Adjacent stages need distinct silhouettes, not just scale or color changes. The animal must still read as its real species.

This first seven-stage Fox test uses the project's own `ExpressiveV1/approved-direction.png` only as a style reference. The generated characters are original. The selected follow-up attempted to preserve stages 1–6 and strengthen the final-stage fan. It still **does not reliably show nine individually countable tails**, so it must not be cut into production sprites. Its Qiu's Fox and Snow Fox anatomy, stage-to-stage pixel scale, and expression range also need manual review. The transparent PNG is a concept contact sheet, not animation frames.

`Fox-final-front-study-v2.png` is a separate front-facing final-form study made with the built-in image-generation tool, using the approved expressive sheet and Fox lineup as style/identity references. Prompt: one original adult fox with a confident, slightly goofy face, grounded quadruped anatomy, crisp pixel-art outlines, gold accents, transparent background and exactly nine separated tails; a follow-up edit targeted only the tail fan. The expression and mature silhouette improved, but the result still does **not** expose nine unambiguous, countable tails. Keep it as a review candidate only: it is not a runtime portrait, a menu-bar-scale sprite, a walking/idle cycle, or an approved replacement. Do not rename it to a packaged asset without correcting the anatomy and checking transparent margins and thumbnail readability.

Other line reviews:

| Candidate | Useful direction | Blocking corrections before production |
|---|---|---|
| Cat | Baby → wildcat → lynx → tiger → sabertooth progression reads distinctly; early face keeps comic warmth. | Dark backdrop is visibly baked in; verify lynx bobtail/tuft, keep mature final from reverting to baby facial proportions, redraw as aligned transparent sprites. |
| Dog | Puppy, wolf and heavy prehistoric bear-dog silhouettes separate better than prior size-only stages. | Wolfdog/Gray Wolf/Dire Wolf need more distinct intermediate anatomy; Epicyon should remain clearly canid; redraw for common baseline/scale. |
| Capybara | The blunt rodent nose remains legible and prehistoric incisors make a memorable late step. | Stages 2–3 and 5–7 still read too similarly; diversify posture and fur/shoulder shape without turning into a bear or hippo. |
| Raptor | Downy hatchling → small feathered hunter → imposing final has a stronger dramatic arc. | Late forms look too bird-like; retain horizontal dromaeosaur torso, grasping arms, balancing tail and raised sickle claw. Check Microraptor four-wing anatomy. |

Cat, Dog, Capybara and Raptor sheets visibly contain dark backdrops despite a transparency request; alpha-channel presence alone does **not** make them usable cutouts. No generated sheet has consistent stage dimensions, anchor points, lighting or walk-cycle frames. They are unsuitable for direct sprite extraction or UI packaging.

Built-in image-generation prompt set (abridged):

1. Generate a separated seven-form Fox lineup: Fox Kit, Red Fox, Silver Fox, Qiu's Fox, Snow Fox, Nine-Tailed Fox, Celestial Fox. Preserve fox muzzle, triangular ears, brush tails and quadruped anatomy. Begin tiny and goofy; end athletic, confident, spectacular and faintly self-aware. Use crisp original pixel art, bold outlines, flat color planes and a transparent background. Avoid franchise copies, armor, human bodies, deadpan faces and repetitive recolors.
2. Edit only the seventh form to show nine separately readable tails and a mature but lightly theatrical expression; keep the first six forms and all margins intact.
3. Generate one seven-form Cat lineup (Kitten, House Cat, Wildcat, Lynx, Tiger, Smilodon, Astral Tiger), one seven-form Dog lineup (Puppy, Dog, Wolfdog, Gray Wolf, Dire Wolf, Epicyon, Fenrir), one seven-form Capybara lineup (Capybara Pup, Capybara, Giant Capybara, Mossback Capybara, Phoberomys, Josephoartigasia, Hot-Spring Spirit), and one eight-form Raptor lineup (Downy Hatchling, Microraptor, Velociraptor, Deinonychus, Achillobator, Dakotaraptor, Utahraptor, Thunderclaw Tyrant). Each prompt required species-specific anatomy, distinct adjacent silhouettes, early comic awkwardness, increasingly mature final forms, original pixel art and no borrowed franchise design.

Next art gate: inspect each stage at menu-bar thumbnail size, correct the anatomy/background defects above (including the Fox final tail count), then make **separate** consistent-scale transparent stage sprites and side locomotion/idle/reaction frames. Do not wire these drafts into the app before that review.
