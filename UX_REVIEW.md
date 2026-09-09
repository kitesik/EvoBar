# EvoBar UI/UX refinement

This note records the implemented UI direction and verification scope as of 2026-09-09. It focuses on the interface, not new animal artwork; see [[SPEC]] and [[ARTWORK]] for the broader product.

## Primary references

- [RunCat official site](https://kyome.io/runcat/index.html?lang=en), including its official system-information screenshot. Inspected 2026-09-08.
- [PokeTokenBar repository](https://github.com/chattymin/PokeTokenBar), including the Home animation and Collection/Shop screenshots linked by its README. Inspected 2026-09-08.

RunCat's useful pattern is a quiet menu-bar presence with compact, aligned information and secondary actions. PokeTokenBar's useful pattern is a short path from the companion and its next milestone to today's activity, with separate collection and shopping destinations. These are observations of the published interfaces, not usability-study findings.

EvoBar applies those interaction patterns with original assets and its own muted-green interface. No third-party sprites, character names, website code, or reference screenshots are bundled.

## Implemented decisions

| Surface | Change | Reason |
|---|---|---|
| Navigation | Four equal Home / Usage / Collection / Shop tabs; Settings in the header | Keep the four everyday destinations visible without squeezing a fifth tab |
| Home | Horizontal companion card, named stage, bond, exact XP remaining, one primary action | Make the companion's next step understandable immediately |
| Usage | Large total, aligned cost and provider figures; day / five hours / week / month filters | Separate the quick glance from deeper inspection |
| Quota | Collapsible detail section, preserving demo/unavailable indicators and forecasts | Unsupported account quota should not dominate a working local usage monitor |
| Collection | Search, owned filter, two-column tiles, dedicated history sheet | Browse visually without losing an individual's recorded history |
| Shop | Animals / Items segmentation; consistent cards and explicit owned/locked/coming-soon states | Keep real-money line entitlements distinct from earned coins |
| Settings | General / Companion / Tracking / Data, consistent cards and right-aligned switches | Replace a single long form with focused groups |
| Onboarding | Back navigation, visible step position, scrollable content at short heights | Let users correct a choice without restarting setup |
| Footer | Persistent refresh/status, open-window action, quit | Keep utility controls reachable while content scrolls |

The popover prefers 420 by 700 points, bounded by the screen where it is opened. It no longer forces a 480-point minimum on shorter displays. Detached dashboards refit on display changes, preserving their SwiftUI root and navigation state. Disconnected or partly offscreen windows and desktop pets are moved fully into a remaining display's visible area. Pure placement arithmetic supports negative monitor coordinates and is tested separately from AppKit. Common surfaces, accent colors, buttons, badges, and growth bars live in `DesignSystem.swift`; light/dark colors are semantic and primary buttons retain a dark fill for white-label contrast. Large usage numbers are monospaced to avoid horizontal jitter.

Motion is limited to short selection/press transitions, a smooth XP fill, and gentle petting feedback. System Reduce Motion suppresses these movements. The existing evolution ceremony and sprite system remain in place; the old scrolling landscape is no longer the Home layout.

## Preserved behavior and boundaries

- The growing companion, not a separately pinned animal, receives the Home care controls.
- A pin now selects the same owned animal for the menu bar and desktop pet, including its name, discovered stage, and locomotion. The highest discovered individual is shown; ties prefer the newer individual. An owned line without a hatched individual previews stage one without creating a record or receiving XP. Invalid or unavailable pins fall back to the growing companion.
- System Reduce Motion stops the menu-bar gait timer and desktop bobbing without requiring a restart. Desktop hover transitions also respect the setting. The desktop pet's Open usage action opens the dashboard at Usage, rather than only changing a hidden selection.
- Feeding, stepwise evolution, graduation, pinning, purchases, item effects, export, and reset still call the existing AppModel services.
- Collection shows the highest discovered stage per line and individual records in its detail sheet. Unknown final-stage artwork remains hidden.
- Partial pricing coverage remains explicit. Cost is an API-equivalent estimate, never a charge or invoice.
- Debug storefront outcomes remain development-only. Release cannot grant mock entitlements.
- Purchase/item result messages are pinned below the scrolling shop so a failure or cancellation cannot disappear below a long product list.
- Parsers, logs, XP arithmetic, persisted schema, credentials, and animal image files are unchanged by this refinement.
- Six localization catalogs have matching keys and format placeholders. New UI copy follows the existing comma/space separator convention.
- Collection detail, graduation, and privacy sheets inherit panel dimensions. Graduation scrolls independently above its fixed action row and lists only owned lines with bundled artwork.
- Collection supports Command-F and clearing search with Escape. Selection traits and spoken stage numbers accompany visual selection and progress indicators; truncated badges expose their full text on hover.
- The empty Home's Tracking settings action opens Tracking directly. Startup failures offer Retry and Quit without resetting data or exposing raw error details; retry is allowed only from a failed state.

## Repeatable visual review

```bash
./Scripts/check.sh
./Scripts/review-ui.sh
# Broader language review:
./Scripts/review-ui.sh en ko ja es fr pt
./Scripts/build-app.sh
./Scripts/smoke-test-app.sh build/EvoBar.app
```

The review command builds a temporary, ad-hoc-signed DEBUG app and renders actual SwiftUI views using NSHostingView. Its sample names/totals are in-memory fixtures. It uses the existing isolated smoke runtime, skips user-log discovery and network checks, never captures the user's desktop, and deletes only its own temporary app/state when complete. Output remains in `build/ui-review/<language>/`, which is ignored by Git. The review code is excluded from release binaries.

Each language yields 52 PNGs: five main destinations, three additional Settings groups, the item shop, a collection detail, three onboarding steps, an empty Home, an evolution-ready long-name Home, purchase/item feedback states at 520 points, and compact 328-by-374-point versions of the five destinations, detail, graduation, privacy, and startup-failure views. Each is rendered in light and dark. Image decoding and isolated startup are checked automatically. The harness also checks the actual AppModel startup retry, Tracking route, and menu-bar binding for unpinned, owned pinned, unhatched, and invalid pinned selections without changing growth. CI uploads the English/Korean images as a seven-day artifact.

The images are review evidence, not pixel-difference assertions or a substitute for real click/keyboard testing. A macOS host needs an available graphical session for native view rendering. Review figures are illustrative and must not be mistaken for the user's tracked usage.

## Acceptance checks

- Inspect Home in both appearances: next form, XP, action, tokens, estimate, provider split.
- Inspect long names and the 520-point layout: names truncate with help text; content scrolls; footer stays visible.
- Inspect empty usage: explain how activity appears and provide a tracking-settings shortcut.
- Inspect all Settings groups: switches aligned; reset still has a destructive confirmation.
- Inspect Collection and Shop: unknown final stages hidden; owned/current states clear; currency types separated.
- At a short panel height, check that purchase cancellation and insufficient-coin feedback remain visible below the Shop's scroll area.
- Pin a different owned animal: the menu bar, desktop pet, tooltip, and accessible name must agree, while Home continues to care for the growing animal. Toggle Reduce Motion while running and check that ambient motion stops immediately. Open Usage from the desktop pet's context menu.
- Verify keyboard shortcuts manually: Command-1 through 4, Command-comma, Command-R, and dismissing detail sheets.
- Verify real popover placement, detached-window action, VoiceOver, reduced motion, and multi-display behavior in the packaged app before release.
- Move the detached dashboard between differently sized displays and disconnect a display holding the dashboard/pet; ensure the whole surface remains reachable. Check native sheets at reduced panel heights and actual Command-F/Escape/Return behavior.
- In an isolated failure scenario, Retry must transition through Loading back to Ready without a reset. The test harness injects the failure state; it does not revoke real filesystem permissions.

Native click/VoiceOver end-to-end acceptance and notarization remain release checks; the automated renderer does not claim to verify them.

## Verification record, 2026-09-08

- 86 unit/fixture tests passed, including the new UI localization/copy-style regression check.
- 180 PNG renders completed across all six languages and both appearances. Representative Korean, English, and French views were visually inspected; this is not a claim of manual review of every image.
- Universal 2 release-configuration build, six-locale/resource/signature validation, ZIP integrity, and packaged-app launch smoke check passed.
- The generated candidate is ad-hoc signed, not Developer ID signed or notarized. No public release or live purchase activation was performed.

## Verification record, 2026-09-09

- 91 unit/fixture tests passed, including five regressions for pinned selection, unhatched previews, safe fallback, and Reduce Motion.
- 68 native SwiftUI renders completed in English/Korean and light/dark appearances. The Korean purchase-cancellation panel and English insufficient-coin panel were visually inspected at 520 points; their result messages remained visible below the product list.
- The isolated AppModel presentation checks passed for the growing Cat, a pinned stage-four Dog, an owned unhatched Fox, and an invalid pin. Growth identity, XP, pending food, and individual count remained unchanged.
- Universal 2 release-configuration packaging, resource/localization/signature checks, ZIP checksum/integrity, and isolated packaged-app launch all passed again. This is still an ad-hoc-signed candidate, not a notarized public release.
- Animal graphics, local data, payment adapters, and credentials were not modified. Real click/VoiceOver, live system-setting toggles, and multi-display acceptance remain manual release checks.

## Adaptive layout and recovery, 2026-09-09

- 99 unit/fixture tests passed, including eight new geometry cases for short/narrow screens, negative coordinates, disconnected monitors, one-pixel visibility, oversized windows, and stable placement.
- 312 native renders completed across all six supported languages. Representative compact English Home/detail, Korean startup/graduation, and French Settings/graduation views were visually inspected, not every image.
- Isolated startup Retry transitioned from Failed through Loading to Ready; retry in Ready was ignored. The direct Tracking route and all previous pin/growth checks passed in the same harness.
- Universal 2 release-configuration packaging, six-locale/resource/signature validation, ZIP checksum/integrity, and isolated packaged-app launch passed. The candidate remains ad-hoc signed, without notarization or public publication.
- These tests use synthetic rectangles and injected failure state. They do not claim physical monitor disconnect testing, revoked filesystem permissions, or VoiceOver/keyboard end-to-end acceptance.
