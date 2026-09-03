import Foundation

public enum StoreProductKind: String, Codable, Sendable {
    case animal
    case bundle
    case allAnimals
}

public struct StorefrontProductDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: ProductID
    public let kind: StoreProductKind
    public let nameKey: String
    public let fallbackName: String
    public let fallbackPriceUSD: Decimal
    public let grantsAnimalIDs: [AnimalDefinitionID]
    public let sortOrder: Int
}

public struct StorefrontManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let products: [StorefrontProductDefinition]
}

public enum GameItemKind: String, Codable, Sendable {
    case rareCandy
    case mint
    case shinyCharm
    case randomEgg
}

public struct GameItemDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: GameItemKind
    public let nameKey: String
    public let fallbackName: String
    public let tokenCoinPrice: Int64
    public let xpGrant: Int64?
}

public struct GameEconomyManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let effectiveTokensPerCoin: Int64
    public let baseShinyRateBasisPoints: Int
    public let charmedShinyRateBasisPoints: Int
    public let items: [GameItemDefinition]
}
