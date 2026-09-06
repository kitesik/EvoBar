# EvoBar implementation rules

- Target macOS 14 or later with Swift 6 and SwiftUI/AppKit.
- Keep token parsing, growth, purchases, and UI in separate modules.
- Never log, persist, export, or transmit prompt, response, code, or raw JSONL lines.
- Aggregate token totals leave the device only through the opt-in community comparison described in SPEC.md.
- Use `Int64` for token and XP values and integer arithmetic for growth.
- Every provider parser requires sanitized fixtures and malformed-input tests.
- New usage events must be idempotent across rescans and app restarts.
- Pokémon names, images, APIs, terminology, and other third-party character assets are prohibited.
- Release builds must not grant entitlements through the mock storefront.
- Do not commit credentials, signing identities, session keys, or notarization profiles.
