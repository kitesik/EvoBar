# EvoBar: a small companion, not another dashboard

2026-09-23 product review. This defines the current simplification direction and records the first implemented slice; it is not a claim that every screen or interaction has been audited. See [[GAMEPLAY_PLAN]], [[GAMEPLAY_PACING]] and [[DEVELOPMENT_HANDOFF]].

## Promise

AI와 일하는 동안 곁에서 자라는 작은 동물. Work normally, notice growth, discover a new form or companion, keep the memory. The animal is the product; usage explains its growth, and optional tools support it.

2026-09-23 owner clarification: prioritize ordinary work → growth → evolution/hatch → attachment and discovery → a companion worth showing others. Business registration and payment integration are excluded from the current work. First improve early discovery using existing systems; then review species-specific personality, preserved individual memories and contextual field-guide facts. Special eggs and voluntary sharing are later candidates, not authorization for new currencies, extra tabs or social infrastructure. Tests establish correctness, not enjoyment.

## Keep / quiet down / do not add

- Keep: ambient walking companion, dependable local usage tracking, visible next evolution, deliberate evolution/hatching, preserved individual records and discovery collection. Actionable failures remain visible.
- Quiet down: coins, stat tuning, growth shortcuts, personality rerolls, scenery and custom tracking paths. These are optional, not daily chores or required steps. Preserve owned items and settings rather than deleting them or changing prices/progression.
- Do not add: quests, battle, more currencies, graded eggs, extra top-level tabs, streak pressure, mandatory care or a server merely for engagement. Do not encourage token waste.

## Findings and this slice

- Shop repeated the coin balance in a header badge and a large wallet card. Price sorting put growth shortcuts before discovering a new companion. Replaced the large wallet with a brief purpose line; ordinary egg and treat lead. Following the owner's scenery feedback, the four existing backgrounds now have an always-visible thumbnail gallery and a larger preview; other optional items remain behind one initially closed disclosure. No item, balance, entitlement or transaction semantics changed.
- Tracking settings placed wildcard paths and token-band tuning at the same level as connection health. Those advanced controls now start collapsed; connection status, provider toggles, manual refresh and actionable feedback stay visible. Existing configured paths/bands are untouched.
- Home's animal scene advertised a button accessibility trait but had only a pointer gesture. Added an accessibility activation action reusing the guarded pet action. No extra control or reward was introduced.
- Render review exposed four missing manifest-driven item-name keys: names silently fell back to English, outside the static-label scanner. Added names in all six languages and a regression that checks every manifest item in every catalog.
- Welcome already states the companion promise; Home already defaults to animal/progress with secondary details closed. Keep those decisions, rather than redesigning them again.

## Acceptance and remaining review

- Shop opens with discovery/care before optional extras, exposes the exact balance to accessibility, and retains the entire existing item inventory when expanded. Failure feedback stays pinned outside scrolling content.
- EN/KO compact and expanded synthetic screenshots must be checked; all six language catalogs must match. Native fixture assertions check the shop partition and ordering without user data.
- This is not a complete physical keyboard/VoiceOver audit. Inspect those interactions separately in an isolated fixture; never infer spoken output from a screenshot.
- Remaining art: Pterosaur4–8 normal/Shiny redesign. Existing legacy art is not completion. App Store remains on hold; Stripe is consideration only, not an activated payment system.
