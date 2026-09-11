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
| Navigation | Four equal Home / Usage / Collection / Shop text tabs at the very top; Settings in the footer beside refresh, window and quit | Keep the four everyday destinations visible without squeezing a fifth tab, and open on content rather than on an app title |
| Home | Horizontal companion card, named stage, bond, exact XP remaining, one primary action | Make the companion's next step understandable immediately |
| Usage | Large total, aligned cost and provider figures; day / five hours / week / month filters | Separate the quick glance from deeper inspection |
| Quota | Collapsible detail section, preserving demo/unavailable indicators and forecasts | Unsupported account quota should not dominate a working local usage monitor |
| Collection | Search, owned filter, two-column tiles, dedicated history sheet | Browse visually without losing an individual's recorded history |
| Shop | Animals / Items segmentation; consistent cards and explicit owned/locked/coming-soon states | Keep real-money line entitlements distinct from earned coins |
| Settings | General / Companion / Tracking / Data, consistent cards and right-aligned switches | Replace a single long form with focused groups |
| Onboarding | Back navigation, visible step position, scrollable content at short heights | Let users correct a choice without restarting setup |
| Footer | Persistent refresh/status, Settings, open-window action, quit | Keep utility controls reachable while content scrolls |

The popover prefers 360 by 540 points, bounded by the screen where it is opened. It no longer forces a 480-point minimum on shorter displays. Detached dashboards refit on display changes, preserving their SwiftUI root and navigation state. Disconnected or partly offscreen windows and desktop pets are moved fully into a remaining display's visible area. Pure placement arithmetic supports negative monitor coordinates and is tested separately from AppKit. Common surfaces, accent colors, buttons, badges, and growth bars live in `DesignSystem.swift`. The panel is dark glass in every system appearance: the popover uses AppKit's dark appearance so its own material shows the desktop through, the detached dashboard is a HUD panel, a dark tint at 78% keeps the panel readable over bright wallpapers, and cards are white tints over that material rather than opaque system colors. Primary buttons use the accent fill with dark text. Large usage numbers are monospaced to avoid horizontal jitter.

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
- Shop and Settings share a fixed, dismissible feedback banner. Dismissing a message clears only its presentation state, not an operation, entitlement, balance, or companion record. Compressed navigation labels expose full help text.
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

Each language yields 29 PNGs: five main destinations, three additional Settings groups, the item shop, a collection detail, a field guide, three onboarding steps, an empty Home, an evolution-ready long-name Home, purchase/item/settings feedback states at 520 points, and compact 328-by-374-point versions of the five destinations, detail, graduation, privacy, startup-failure, and Settings-feedback views. Each is rendered once, in the dark appearance the panel always uses, over an opaque stand-in for the glass. Image decoding and isolated startup are checked automatically. The harness also checks the actual AppModel startup retry, Tracking route, feedback dismissal, and menu-bar binding for unpinned, owned pinned, unhatched, and invalid pinned selections without changing growth. CI uploads the English/Korean images as a seven-day artifact.

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

## Persistent feedback follow-up, 2026-09-09

- The 99-test suite passed again. The expanded English/Korean/French review covers 56 views per language, including both regular-height and compact Settings feedback.
- Isolated dismissal checks preserve individual records, ownership, XP, coin balance, and today's tokens. Dismissing a purchase result does not clear unrelated item or Settings feedback.
- The compact Korean Settings error and English Shop cancellation banner were visually inspected, with the close control and fixed dashboard footer visible. These are fixture outcomes, not failures in the user's data export or purchases.
- All 168 requested follow-up renders completed. Universal 2 release-configuration packaging, resource/signature/ZIP checks, and isolated app launch passed again; notarization and live payments remain out of scope.

## Native Settings window, 2026-09-09

- The standalone SwiftUI Settings scene now shares the detached dashboard's screen-fitting implementation. It accounts for the native title bar, constrains the entire window to the visible screen, and adjusts its scrollable content on display changes without replacing the SwiftUI root.
- A zero-size AppKit attachment observes only its own window and display-configuration notifications. It defers fitting until the next main-loop pass, cancels pending work when detached, and ignores temporarily empty screen inventories.
- `WindowLayoutReview` exercises the actual hidden Settings hosting root with isolated model data, synthetic screen rectangles, and a private notification center. It verifies short-screen fitting, restoration on a larger negative-origin screen, preservation of the Tracking selection, no movement during an empty inventory, and no further fitting after detachment. No user's windows or monitor settings are changed.
- All 102 unit/fixture tests passed, including the field-guide tests added separately. English/Korean review rendered 116 images and passed the new native-window checks. This verifies the AppKit/SwiftUI connection, not physical monitor unplug/replug, VoiceOver, or real keyboard interaction.
- Universal 2 release-configuration packaging, six-locale/resource/signature checks, ZIP integrity/checksum, and isolated packaged-app launch passed. This remains an ad-hoc-signed candidate, not a notarized or publicly published release.
- Existing field-guide implementation and the pre-existing staged changes are preserved; this slice does not modify animal artwork, parsing, growth, persistence, or purchases.

## Native shortcut routing, 2026-09-09

- `KeyboardNavigationReview` creates a hidden dashboard in the isolated fixture process. AppKit key-equivalent events exercise Command-1/2/3/4 and Command-comma through the actual SwiftUI buttons, not by assigning the expected destination directly.
- Command-F must place the Collection's native field editor in focus. The harness inserts a fixed, non-user search string and sends an Escape key event to the test window; the editor must become empty. Unmodified `2` must not navigate. Individual records, entitlements, XP, and coins must remain unchanged.
- All 102 unit/fixture tests passed. All six languages passed the native-window and shortcut checks and generated 348 light/dark review images. Representative compact Korean Settings and English Tracking views were inspected; not every rendered image was reviewed by eye.
- Universal 2 release-configuration packaging and isolated packaged-app launch passed again. The native review code is DEBUG-only and is invoked only in the existing isolated visual-review path.
- This is programmatic AppKit event delivery, not physical keyboard, VoiceOver, or screen-reader acceptance. Real assistive-technology behavior and physical monitor reconfiguration remain release checks. See [[NATIVE_UI_CHECKPOINT]] for the next safe scope.

### Final-source verification correction

The final keyboard commit `1f2ddd9` failed remote localization coverage: the scanner mistakenly recognizes `Text("...")` inside the test-only `insertText("...")` call. The local 102-test suite had started before this final fixture edit, so its success is not final-source unit validation. Six-language native checks and packaging passed afterward, but the complete slice remains unverified until the scanner regression is fixed and the final suite/CI passes. Development paused at 7% allowance before applying that fix; [[NATIVE_UI_CHECKPOINT]] records the exact failure and reset deadline.

## Compact dark glass panel, 2026-09-09

- Reference re-read: PokeTokenBar opens on a 360-point dark, slightly translucent panel with text tabs at the top and no app header; the interface reads as a quick companion, not a dashboard. EvoBar's 420-by-700 panel with a title row, a badge and an icon tab bar read as a full application.
- The panel is now 360 by 540 points and dark glass regardless of system appearance. The header row is gone; the four text tabs sit at the top and Settings moved to the footer. Section titles shrank to 15 points and lost their subtitles; cards use 12-point radii and padding, white-alpha fills and borders; sprites and headline numbers are a step smaller. No strings were added; unused header strings stay in the catalogs.
- Sheets (detail, graduation, privacy) follow the panel width and cap at 480 to 500 points. The standalone Settings scene requests the dark appearance. The isolated review renders the dark appearance only, 29 screens per language.
- Not changed: animal artwork, the menu bar item, the desktop pet, growth, persistence, purchases.

## Walking scene and eggs, 2026-09-09 night

- The companion walks across the top of its Home card again: the scrolling scene from the earlier Home (parallax hills, ground ticks in step with the synthesized gait, a shadow, a glow when evolution is ready) fills the card width at 116 points, and a tap on it pets. Name, state badge, stage and bond sit under it in two rows.
- Cards read as a lit pane of glass: a white gradient fill, a gradient hairline and a soft shadow. The panel tint dropped to 66% so more of the desktop shows through.
- A line that has not hatched shows an egg in its theme colour in the shop card, the collection tile and the detail header, and the shop no longer previews stages one to four. The evolution journey appears only up to the highest stage a companion of that line has reached.
- Development switch `unlockEverything` in `app-config.json` makes every line owned and every item free. It is on now and must be turned off before the storefront goes live.

## Longer ladders, 2026-09-09 night

- Cat and dog now run seven stages; the other eight lines run seven or eight, each extended only as far as its family plausibly goes. Real prehistoric relatives that used to be guide pages became stages where they fit the size order: Smilodon, Epicyon, Qiu's fox, Josephoartigasia, Microraptor, Dakotaraptor, the steppe mammoth, Dimorphodon, Hatzegopteryx and the Irish elk. New real stages fill the gaps (lynx, gray wolf, snow fox, Phoberomys, Achillobator, Columbian mammoth, Pterodactylus, red stag) and the legends gained a lindworm, a primordial dragon, a firebird and a great phoenix. Every line keeps at least one relative in the guide; four new relatives were added so that holds (Leptocyon, Neoepiblema, Zhenyuanlong, Nyctosaurus). The guide has 83 pages.
- Thresholds keep the first five steps (0, 50, 300, 900, 2000) so no existing companion changes stage, then continue 4000, 7000 for seven stages or 3600, 6000, 9500 for eight.
- The four illustrated lines keep their five drawn forms; a stage without its own sheet borrows the neighbouring form below it and is marked `artworkPending` in the manifest. The evolution journey draws such a stage at 60% with a dashed edge and says "New look coming" on hover; the collection's stage capsules and every "Stage n / m" label read the real count.
- Validation accepts five to ten stages with strictly increasing thresholds; ManifestTests pins the two ladders and checks that only illustrated lines borrow.

## Placeholders for the new stages, 2026-09-10

- The eight stages of the illustrated lines that still lack a sheet no longer repeat the neighbouring drawing: a recoloured placeholder (lynx in grey-buff, Smilodon in dark tawny, gray wolf in grey, Epicyon in dark tawny, Qiu's fox in pale sand, snow fox near white, Phoberomys browner, Josephoartigasia in dark umber) makes each evolution visible. They stay marked pending and keep the dashed edge in the journey.
- The detached HUD dashboard draws its title bar transparent so the glass runs edge to edge.

## Motion pacing, 2026-09-10

- The product owner found the walk unnatural. The default quality was Power Saver, which drove the Home scene at six frames a second and left the menu bar still, so a sixteen-frame gait cycle showed as a flip-book. The scene now runs at 15, 24 or 30 frames a second by quality, the menu bar cycles eight (Balanced) or twelve (Smooth) frames per gait instead of four or eight, and the default quality is Balanced. Power Saver still keeps the menu bar still.

## Gait rig rebuilt, care bursts, thinner glass, 2026-09-10 afternoon

- The product owner reported that the lynx's hind feet did not move, that the walk broke into pixels, and that the panel still looked sealed. The hind feet were the rig: it posed only what hangs below the belly line, so a lynx swung a 27-pixel shin under a still haunch and its paws slid a few pixels either way. Each leg now swings from a joint above the hip line (the hip inside the haunch, the shoulder inside the chest). The body between the joint and the hip line is a band that leans with the near leg's knee, pinned at the middle of the belly, so the haunch and the chest sway with the stride, and the stride is measured from the joint, which roughly doubles it.
- Nothing rotates any more. Every piece is drawn scanline by scanline with a horizontal shift or stretch, so the ragged rotated edges, the tilted seams and the shards they threw off cannot occur. The shin blends from the band's mapping at its top to the ankle's shift at its bottom, and the paw only travels. A far leg the art shows as a sliver is drawn beneath a shaded copy of its partner's shape, so it no longer stretches into a whip when it swings clear of the near leg. Legs are told apart on each row at the background between them, a fox's hanging tail is body rather than a leg and moves with the band it hangs from, two legs drawn touching split where the paws part or along the artist's contour, and a paw drawn lifted comes down to the ground line in stance.
- The sheets are about 230 pixels tall and are drawn at 72 points or less. Nearest-neighbour scaling dropped every third row, which is what shimmered from frame to frame. Sprites are filtered when scaled now, in the scene, the tiles and the menu bar.
- Pet and Feed show the care landing: a heart or a leaf flies from the control, or from the click on the companion, to the companion's face; a ring marks the landing; the hearts row beats; three hearts rise from the face and fade, with "+N XP" beside them after a meal. With Reduce Motion on the previous single heart appears instead and nothing flies.
- The panel is real glass. The popover's frame, an AppKit visual effect view, takes the HUD material instead of the near-opaque popover material, and the tint laid over it dropped from 66% to 34%; card fills and hairlines rose a step so cards still read as panes. The detached window hides its title and asks to run its content under the title bar; the HUD panel keeps the bar but now draws it as the same glass, so the lighter band is gone, and an 18-point inset is added only if the content ever does run under it.
- Tests: the rearmost and foremost paw edges must each travel more than 60% of the stride over a cycle and the stride must exceed 1.2 leg heights, for the lynx, the wolf, the capybara and the fox. The kept-pixel floor moved from 90% to 85% because a lifted leg is now legitimately squeezed shorter.

## The thigh swings from the hip, 2026-09-10 evening

- The product owner saw the hind feet move but found the walk stiff: only the shin seemed to turn, as if the knee moved and the hip were locked. The joint the leg swung from sat a hand's breadth above the belly line, so the haunch barely leaned. The joint now sits a little over half way up the animal, where the hip and the shoulder are, and the whole haunch and chest below it swing with the near leg's knee: the shift is full from the knee column outward, eases to nothing toward the middle of the belly, and scales with depth below the joint, the way a thigh turning about the hip carries the haunch. The stride itself is still measured over a shorter leg (the visible leg and about as much again), because a paw swung a full hip-to-ground leg each way overshoots how far animals step.
- Since a long leg barely needs to drop to keep its feet down, the walk gained an explicit bounce: the body sits lowest at each touchdown and highest as a leg passes vertical, twice a cycle, by about a hundredth of the animal's height.
- The near leg of a pair is the one the art draws more fully; the outer leg only breaks a tie. A leg drawn apart from its partner, with background between them down the shin, is whole as drawn and gets no shaded copy. The shin's widening for a steep lean eases off toward the ankle so the paw joins it without a step.
- Rendering a cycle inverts each band row once, with one walk along the row, instead of a search per pixel; a sixteen-frame cycle for a 230-pixel sheet stays well under a second on first use and is cached after.

## Local swing, 2026-09-10 night

- The product owner called the hip-height version jelly. It swung everything below the joints, both halves of the belly and the base of the neck included, and the two halves swung out of phase. A rigid puppet was tried next, with the haunch and the chest cut out of the torso and turned as pieces on top of it; on a single flat drawing every cut shows as a seam through the fur, and the space behind a turned piece reads as a hole. What works is a local swing: only the haunch (behind the hind knee column) and the chest (ahead of the front one) shear with their near leg's knee, the shift fades to nothing within a little over twice its own amplitude toward the belly, and the joints sit at 42% of the height. The chest takes half the swing, since a shoulder moves far less than a hip. The belly, the back, the neck and the tail base stay rigid, so the haunch reads as a thigh turning about a hip and nothing else moves.
- Some sheets (the puppy, the beagle, the dire wolf) paint a soft grey shadow under the paws. It was taken as leg and slid about under the feet as a grey slab. A translucent patch at the bottom of the drawing that spans a quarter of the animal's width is now recognised as that shadow, left out of the leg analysis, and dropped from the gait frames; the scene draws its own shadow.
- Fur hanging under the belly between the legs, the wolves' chest ruff especially, was counted as leg because it lay below the hip line, and a copy of it slid ahead of the front paws as a striped slab. A leg is now what stands on the ground: only pixels joined, below the hip line, to the bottom quarter of the drawing are leg. And only a far leg borrows a shape, from the near leg of its pair, which is the brighter shin (far legs are drawn in shadow), then the fuller, then the outer.
- Provider outage notices moved from the top of every tab into the Usage tab, under the window picker. They are the provider's own status text and open the provider's status page.

## Rubber-hose legs, 2026-09-11

- The product owner called the local-swing version wobbly and asked for a fundamental fix rather than another round of patching. The honest diagnosis: a skeleton was being simulated on a drawing that has none. Each sheet is one flat side view in which the four legs overlap each other and merge into the belly, so every rule that told a thigh from a shin from a haunch was a guess about that particular sheet, and a rule tuned for one sheet broke another. Three rounds of that produced a rig of about five hundred lines that still tore.
- The legs are now rubber hoses, the way hand-drawn cartoons have always moved a limb with no drawn joints. Each row of a leg slides sideways and up by the foot's displacement times how far down the leg that row lies: nothing at the row where it joins the body, all of it at the paw. The leg bends smoothly instead of breaking at a knee, it cannot come away because its top row never moves, and it cannot tear, widen or throw off a shard, because every row is only moved. The torso never deforms at all; it only dips and rises, lowest at each touchdown. That is about a hundred lines in place of five hundred, and no part of it is tuned to a particular animal.
- Four details earn their place. The bend finishes a quarter of the way above the paw, so the paw travels as one block instead of combing into stripes. A stretched leg fills the rows it opens, so settling a paw onto the floor leaves no gaps. The floor is the lowest foot the artist drew, not the lowest pixel, which on some sheets is a mist wreathed around the paws. And a leg drawn reaching forward starts its bend at its own topmost row, not at the belly line, so it keeps hold of the body.
- Two safety nets replace the guesswork. Every finished frame is checked for pieces that have come away from the animal; anything the artist did not draw loose in the first place is dropped, so a stray paw can never fly beside the companion whatever a sheet does. And if posing a sheet's legs costs it more than about two percent of itself, the whole line keeps its legs still and walks on its body alone, which is how a single drawing has always been animated when it cannot be taken apart. A test holds every sheet to this: a posed frame may be no more broken up than the drawing it came from.
- Known and left: the kirin capybara's coat hangs to the ground with no gap between one leg and the next, so its belly fur reads as leg and slides with it. It is subtle at the size the panel draws, and the real walk art for that line will settle it.

## Growth arrives on its own, 2026-09-11

- The product owner found the Feed button unintuitive: the bowl's number had no size, food was a metaphor the tokens never earned, and what mattered was watching the XP fill when the panel opens. The button is gone. XP still gathers while the panel is closed, but it is drawn on the growth bar as a translucent run ahead of the fill, with the amount beside the count, so its size is the bar's own scale. Once the Home tab is on screen the bar sweeps on its own after a short pause, the count rolls, a spark flies from the bar to the companion's face and stars rise from it. Nothing to press.
- Chance sits on top of certainty. Everything the work earned arrives in full, and a roll can only add: 15% of arrivals bring half again (lucky), 3% bring double and three Token Coins (golden). The bonus is a share of what arrived, so opening the panel more often changes nothing. A gold note under the care row names the roll for three seconds. Rare Candy is worth two thirds to four thirds of its listed XP, and its listed XP rose from 25 to 60, because 10 coins had bought a quarter of the growth the tokens behind them had already given.
- The first arrival of a growth day counts as care, which is what a meal used to give. Pet keeps its place and a Treat button joins it, so the care row still offers two things to do and the coins have a use on Home.
- Today's tokens sit on a four-band gauge under the number, with the user's thresholds (1M, 5M, 20M by default) as ticks and the tile's own heat colour as the fill. No band is named; the number gets a scale.

## The Usage tab tells a story, 2026-09-11

- The product owner asked whether input, output and cache mean anything to most people, and asked for more interesting information instead. They do not, so they moved into a collapsed token detail (still behind the existing Settings switch), and a story card took their place under the total: time working together, the busiest hour, the longest session, the text as novels, the main model, and for today the streak, the ratio to yesterday, and the busiest day on record, which turns accent when today set it.
- The time figures come from the events the store already keeps: a session's events within ten minutes of each other are one stretch, a lone event stands for a minute, and two tools open at once count once. Nothing new is stored.

## Rarity, nature and shiny in view, and a hatch to watch, 2026-09-11

- The policy read found that rarity and nature were stored and never shown, so a legendary hatch looked like any other and Mint rerolled something invisible. The Home card now carries the nature beside the name (its one-line flavour on hover) and a rarity badge beside the stage when the line is above common; the collection tile carries the rarity badge and a gold spark for a shiny individual, the collection header counts shinies, and each individual's record shows nature, flavour, rarity and shiny.
- A new companion used to appear in the sheet with no build-up. Now every one, chosen or hatched, arrives through a hatch ceremony over the Home tab (`HatchCeremonyView`): the egg rocks wider and faster, cracks run across it while it shakes, light in the rarity colour pours out (gold for a shiny), a white blow-out, and the companion lands with its name, species and rarity. Five seconds; Reduce Motion keeps the beats and drops the rocking, shaking and overshoot.
- Rarity colours live in `EvoStyle.rarityColor`: uncommon green, rare blue-violet, legendary gold. Common shows no badge, so the badges mean something when they appear.

## The companion speaks, 2026-09-11

- Nature had a name since the previous slice but nothing to do. Now it has a voice: a bubble over the scene when the panel opens, when petted, when XP arrives, and every minute or so while the panel stays open. Twelve natures, each with three idle lines and a petting reply, so the curious one asks what is in the file and the serene one says the log can wait; sleeping, working and ready-to-evolve have lines of their own, an unhappy mood cuts in, and growth has three. Six languages, 59 lines each.
- The bubble is dark glass over the scene with a spring in and a fade out; a newer line replaces an older one. Reduce Motion drops the spring. The chatter loop lives in the view's task and ends with it.

## A journal for every individual, 2026-09-11

- A graduated companion used to be a row: name, dates, tokens. Its record now ends in a journal, dated lines in the order they happened: hatched (and shiny, when it was), first growth, each stage reached, the busiest day with its tokens, the day the bond reached its top, the first golden roll, the final form, graduation. It is what makes an individual read as a life lived rather than a record kept, and it costs the store four dates on the individual and one per-individual token figure per day.

## A gift on the first growth of the day, 2026-09-11

- Every other draw in the app is paced by how the work happened to split into arrivals. This one is paced by the calendar: the first growth of a growth day brings two to five coins always, a Rare Candy's worth of XP 18% of the time, and a Random Egg 4% of the time, named in a line under the care row beside the bonus roll if both landed. It is the reason to open the panel on a quiet day, and an egg every twenty five days or so keeps the hatch ceremony and the collection turning without grinding forty coins for it.
- The gift carries no Mint. A nature is now visible on the card, spoken in the companion's voice and attached to by the user, so rerolling one unasked would take something away, and every outcome of this draw has to add.

## Coins buy something to look at, 2026-09-11

- The wallet had four things to spend on and all four were consumable or invisible, so a heavy user's coins piled up unspent. Four scene backdrops join the shop at 60 coins: dawn, dusk, night, snow. A backdrop is bought once and worn at once, its button then reads Wearing, and pressing it again takes it off. Nothing about growth, odds or ownership moves.
- The colours live beside the rest of the palette rather than in the manifest, which carries the name and the price as it does for every other item. The scene now draws sky, hills and ground from three colours instead of tinting everything with one; with nothing worn the three are the artwork tint at the old opacities, so an unthemed scene is pixel for pixel what it was.

## A look back at the week, 2026-09-11

- Everything on Home is about now: today's tokens, the growth arriving, the seven-day bars. Nothing marked the passing of a week. On the first open of a new calendar week a card sits above the companion with the week that ended: its tokens, the XP it produced, the days worked, the busiest day, and the stages any companion reached in it, read off the journals added earlier today.
- It is a look back and not a score, so nothing in it is a target and no streak can be broken by reading it. It appears only when that week had usage, closes by hand, and does not come back; the only thing recorded is which week has been seen.

## A bond that keeps growing, 2026-09-11

- Affection fills in about three days of ordinary care and then has nowhere to go, which left the five hearts at their top for the rest of a companion's life and nothing to reach for. Every act of care a companion ever receives is now counted as well, and that count alone sets a bond level: Newly met, Familiar at 20, Trusted at 60, Close at 150, Inseparable at 300, which is months of ordinary days. It only ever rises, so a fortnight away lowers the mood and takes nothing off the bond.
- Two scales could crowd the card, so they share a row instead: the hearts carry the mood, as they always did, and the words beside them carry the bond. The mood's name was redundant with the hearts it sat next to; it moved into the tooltip and the accessibility label, where it now reads together with the bond level and the care still to give before the next one. At the top level the words turn gold.

## A line worth finishing, 2026-09-11

- The collection could be filled by owning ten lines, and after that a line had nothing left to ask. A line is mastered now when three different kinds of work are done on it: every stage reached, which is patience; a shiny raised, which is luck; and three individuals of different natures, which is the collection loop turning more than once. The tile takes a gold border and a crown, the header counts mastered lines beside owned ones and shinies, and the line's detail lists the three parts with the ones still open.
- Nothing is stored for it. Mastery is a fact about the individuals already kept, the way the field guide's discovery is, so a graduated companion keeps contributing what it reached.

## A card to keep, 2026-09-11

- A companion's life was readable only inside the panel, so there was nothing to keep when it graduated and nothing to show anyone. Each individual's record now ends in a Save card button: one PNG, 420 by 560, with the sprite, the name, the stage it reached, its line, nature, rarity and bond, the days together, the tokens it grew on, its XP, the split between the two providers, its busiest day, and its dates.
- It is drawn once off screen at a fixed size rather than screenshotted, so it does not depend on the panel's size or on what is scrolled into view. The review harness renders one every run, which is also the check that the exporter still works. Nothing leaves the machine: the file goes where the save panel is pointed.
