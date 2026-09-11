import Foundation
import EvoBarCore

enum L10n {
    static func text(_ key: String, fallback: String? = nil) -> String {
        Bundle.module.localizedString(forKey: key, value: fallback ?? key, table: nil)
    }

    static func format(_ key: String, fallback: String? = nil, _ arguments: CVarArg...) -> String {
        let template = text(key, fallback: fallback)
        return String(format: template, locale: Locale.current, arguments: arguments)
    }

    static func animal(_ definition: AnimalDefinition) -> String {
        text(definition.nameKey, fallback: definition.fallbackDisplayName)
    }

    static func stage(_ definition: EvolutionStageDefinition) -> String {
        text(definition.nameKey, fallback: definition.fallbackName)
    }

    static func product(_ definition: StorefrontProductDefinition) -> String {
        text(definition.nameKey, fallback: definition.fallbackName)
    }

    static func item(_ definition: GameItemDefinition) -> String {
        text(definition.nameKey, fallback: definition.fallbackName)
    }

    /// Natures live in the catalog by id; their names and one-line flavours are
    /// catalog strings under `nature.<id>` and `nature.<id>.flavor`.
    static func nature(_ id: String) -> String {
        text("nature.\(id)", fallback: id.capitalized)
    }

    static func natureFlavor(_ id: String) -> String {
        text("nature.\(id).flavor", fallback: "")
    }

    static func rarity(_ rarity: AnimalRarity) -> String {
        text("rarity.\(rarity.rawValue)", fallback: rarity.rawValue.capitalized)
    }
}
