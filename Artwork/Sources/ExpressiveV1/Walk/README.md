# Cat walking pilot — 2026-09-20

Walking remains the core; idle reactions supplement it. This supersedes the earlier idle-only proposal.

Cat.png was produced with built-in image generation, with no third-party image input. It contains four separately drawn walking phases for normal Cat stage one. Exact generation text is not stored here under repository policy.

Mechanical import: `swift Scripts/prepare-motion-atlas.swift --single-stage --export Artwork/Sources/ExpressiveV1/Walk/Cat.png`. Cat.json records alpha conservation before uniform nearest-neighbor resizing. Existing exact-variant discovery connects cat.1.motion.png to menu bar, Home and desktop. Working plays faster than idle. Sleeping/Reduce Motion/animation off still use the old state art. Other stages and Shiny are unchanged. This is a partial visual migration, not a complete replacement.

Preview: `swift Scripts/preview-motion-strip.swift Sources/EvoBarCore/Resources/Sprites/cat.1.motion.png Artwork/Sources/ExpressiveV1/Walk/cat-walk.gif`. GIF timing is 120ms/frame; final app uses its existing presentation crop.

Local targeted tests: 12 passed (AnimationCoverageTests, CompanionMotionTests, AuthoredAnimationTests). Full suite and remote CI not run for this checkpoint. Hybrid coverage is now 61 authored and 83 procedural variants.

Next: match starter still/sleep poses to this design, then dog walking. Preserve all old sources and do not borrow normal art for Shiny motion.
