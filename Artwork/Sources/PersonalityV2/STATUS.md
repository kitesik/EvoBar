# Personality V2 completion ledger

Scope: the approved redesign of all 72 forms in 10 lines, normal and Shiny, four state portraits and four-phase authored locomotion per variant. As of 2026-09-21, existing legacy assets do not count as completed V2 artwork.

| Line | Forms | V2 normal motion + states | V2 Shiny motion + states | Remaining stages |
|---|---:|---|---|---|
| Cat | 7 | 1–7 | 1–7 | None |
| Dog | 7 | 1 | 1 | 2–7, both colours |
| Fox | 7 | 1 | 1 | 2–7, both colours |
| Capybara | 7 | 1 | 1 | 2–7, both colours |
| Raptor | 8 | 1 | 1 | 2–8, both colours |
| Mammoth | 7 | 1 | 1 | 2–7, both colours |
| Pterosaur | 8 | 1 | 1 | 2–8, both colours |
| Dragon | 7 | 1 | 1 | 2–7, both colours |
| Phoenix | 7 | 1 | 1 | 2–7, both colours |
| Kirin | 7 | 1 | 1 | 2–7, both colours |

V2 source coverage: 32 of 144 variants, 128 state portraits and 128 motion phases. Cat stage-one normal motion comes from the approved `../ExpressiveV1/Walk/` source; all other completed sources are under this directory, with later Cat sources under `Stage02/` through `Stage07/`. This is source/application coverage, not a claim that the latest build is installed.

Required completion evidence:

- Every variant has reviewed, species-recognizable artwork, gradual maturity and distinct silhouettes; no legacy placeholders or duplicate/recoloured-by-script stand-ins.
- Every source has transparent margins, preserved alpha, distinct frames and correct variant/stage routing. Flight anchors and foot baselines require visual review, not just hash checks.
- Normal/Shiny motion and static states remain visually consistent at menu-bar and desktop sizes; sleeping and reduced-motion modes remain meaningful.
- Strict 144-motion coverage, state coverage, full tests, EN/KO synthetic UI rendering, Universal 2 packaging and isolated launch pass on the final tree.
- Final verified commit is pushed and installed through deploy-local with prior app/save backups preserved. Local checks are not remote CI or notarization.

Installed checkpoint: 2560ca4, complete Cat line and all other babies, via safe deploy-local on 2026-09-21. Next: other lines' stages 2–7 or 2–8 using stable stage IDs, starting with Dog. Source concept sheets in this directory are not production assets until independently reviewed and imported. See DEVELOPMENT_HANDOFF.md at the repository root for deployment and test checkpoints.
