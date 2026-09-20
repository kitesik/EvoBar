# Personality V2 state portraits

2026-09-21. Ten normal-colour stage-one sheets, generated with the built-in image tool using each installed motion source as character reference. Each sheet has four distinct left-to-right poses: idle, working, evolution-ready, sleeping. Adjacent JSON records source hashes, bounds and alpha conservation.

Import: `swift Scripts/prepare-art-atlas.swift --single-stage --export Artwork/Sources/PersonalityV2/States/Animal.png` (replace Animal with its source name). This mode targets stage one only; it must not be used to overwrite other stages. No recolouring, painting or invented frames occurs during extraction.

All 40 state portraits passed source transparency/edge checks and exact alpha conservation. The baby-state regression checks distinct images and transparent gutters. `review-artwork.swift` creates `baby-states-light.png` and `baby-states-dark.png` for visual comparison.

Remaining goal scope: normal stages 2–final, all dedicated Shiny motion/state variants, complete coverage and final build/smoke/install audit. These ten sheets do not establish completion of the full 72-form redesign.
