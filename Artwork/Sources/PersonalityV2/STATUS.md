# Personality V2 completion ledger

Scope: the approved redesign of all 72 forms in 10 lines, normal and Shiny, four state portraits and four-phase authored locomotion per variant. As of 2026-09-21, existing legacy assets do not count as completed V2 artwork.

| Line | Forms | V2 normal motion + states | V2 Shiny motion + states | Remaining stages |
|---|---:|---|---|---|
| Cat | 7 | 1 | 1 | 2–7, both colours |
| Dog | 7 | 1 | 1 | 2–7, both colours |
| Fox | 7 | 1 | 1 | 2–7, both colours |
| Capybara | 7 | 1 | none | Shiny 1; 2–7 both |
| Raptor | 8 | 1 | none | Shiny 1; 2–8 both |
| Mammoth | 7 | 1 | none | Shiny 1; 2–7 both |
| Pterosaur | 8 | 1 | none | Shiny 1; 2–8 both |
| Dragon | 7 | 1 | none | Shiny 1; 2–7 both |
| Phoenix | 7 | 1 | none | Shiny 1; 2–7 both |
| Kirin | 7 | 1 | none | Shiny 1; 2–7 both |

V2 source coverage: 13 of 144 variants, 52 state portraits and 52 motion phases. Cat normal motion comes from the approved `../ExpressiveV1/Walk/` source; all other completed sources are under this directory. This is source/application coverage, not a claim that the latest build is installed.

Required completion evidence:

- Every variant has reviewed, species-recognizable artwork, gradual maturity and distinct silhouettes; no legacy placeholders or duplicate/recoloured-by-script stand-ins.
- Every source has transparent margins, preserved alpha, distinct frames and correct variant/stage routing. Flight anchors and foot baselines require visual review, not just hash checks.
- Normal/Shiny motion and static states remain visually consistent at menu-bar and desktop sizes; sleeping and reduced-motion modes remain meaningful.
- Strict 144-motion coverage, state coverage, full tests, EN/KO synthetic UI rendering, Universal 2 packaging and isolated launch pass on the final tree.
- Final verified commit is pushed and installed through deploy-local with prior app/save backups preserved. Local checks are not remote CI or notarization.

Next: the seven remaining baby Shiny pairs, then later forms using stable stage IDs. Source concept sheets in this directory are not production assets until independently reviewed and imported. See DEVELOPMENT_HANDOFF.md at the repository root for deployment and test checkpoints.
