import Foundation

public enum AnimalRarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case legendary
}

public struct HatchProfile: Codable, Equatable, Sendable {
    public let rarity: AnimalRarity
    public let hatchWeight: Int
    public let shinyBaseRateBasisPoints: Int
}

public struct EvolutionStageDefinition: Codable, Equatable, Sendable {
    public let index: Int
    public let nameKey: String
    public let fallbackName: String
    public let xpThreshold: Int64
    public let normalAssetID: String
    public let shinyAssetID: String
}

public struct AnimalDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: AnimalDefinitionID
    public let nameKey: String
    public let fallbackDisplayName: String
    public let descriptionKey: String
    public let fallbackDescription: String
    public let priceTierID: String
    public let isStarter: Bool
    public let stages: [EvolutionStageDefinition]
    public let lockedSilhouetteAssetID: String
    public let themeColorHex: String
    public let purchaseProductID: ProductID
    public let sortOrder: Int
    public let hatchProfile: HatchProfile
    public let menuBarEmoji: String
}

public struct NatureDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let fallbackName: String
    public let flavorKey: String
}

public struct AnimalCatalogManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let animals: [AnimalDefinition]
    public let natures: [NatureDefinition]
}

public struct AnimalInstance: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let definitionID: AnimalDefinitionID
    public var name: String
    public let createdAt: Date
    public var currentXP: Int64
    public var acknowledgedStageIndex: Int
    public var isCurrent: Bool
    public var isShiny: Bool
    public var natureID: String
    public var rarity: AnimalRarity
    public var cumulativeTokens: Int64
    public var providerTokens: [ProviderID: Int64]
    public var finalEvolutionAt: Date?
    public var graduatedAt: Date?
    public var lastActivityAt: Date?

    public init(
        id: UUID = UUID(),
        definitionID: AnimalDefinitionID,
        name: String,
        createdAt: Date = Date(),
        currentXP: Int64 = 0,
        acknowledgedStageIndex: Int = 1,
        isCurrent: Bool = false,
        isShiny: Bool = false,
        natureID: String,
        rarity: AnimalRarity,
        cumulativeTokens: Int64 = 0,
        providerTokens: [ProviderID: Int64] = [:],
        finalEvolutionAt: Date? = nil,
        graduatedAt: Date? = nil,
        lastActivityAt: Date? = nil
    ) {
        self.id = id
        self.definitionID = definitionID
        self.name = name
        self.createdAt = createdAt
        self.currentXP = currentXP
        self.acknowledgedStageIndex = acknowledgedStageIndex
        self.isCurrent = isCurrent
        self.isShiny = isShiny
        self.natureID = natureID
        self.rarity = rarity
        self.cumulativeTokens = cumulativeTokens
        self.providerTokens = providerTokens
        self.finalEvolutionAt = finalEvolutionAt
        self.graduatedAt = graduatedAt
        self.lastActivityAt = lastActivityAt
    }
}
