import Foundation

public enum AnimalRarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case legendary
}

public enum AnimalLocomotion: String, Codable, Sendable {
    case walk
    case fly
    /// Two-legged silhouettes must not enter the quadruped cutout rig.
    case biped
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
    /// True while the stage borrows a neighbouring stage's sprite because its
    /// own sheet has not been drawn yet.
    public let artworkPending: Bool?
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
    /// Missing in older manifests; walking is the default.
    public let locomotion: AnimalLocomotion?
    /// True only once every stage and state has dedicated bundled Shiny art.
    /// Missing in older catalogs; normal-art fallback remains supported.
    public let hasShinyArtwork: Bool?
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
    /// XP earned from tokens but not yet fed to the companion.
    public var pendingFoodXP: Int64
    /// Affection in hundredths as of `affectionUpdatedAt`; decay is applied on read.
    public var affectionPoints: Int64
    public var affectionUpdatedAt: Date?
    /// Growth-day key the two counters below belong to.
    public var careDayKey: String
    public var petsOnCareDay: Int
    public var treatsOnCareDay: Int

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
        lastActivityAt: Date? = nil,
        pendingFoodXP: Int64 = 0,
        affectionPoints: Int64 = 5_000,
        affectionUpdatedAt: Date? = nil,
        careDayKey: String = "",
        petsOnCareDay: Int = 0,
        treatsOnCareDay: Int = 0
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
        self.pendingFoodXP = pendingFoodXP
        self.affectionPoints = affectionPoints
        self.affectionUpdatedAt = affectionUpdatedAt
        self.careDayKey = careDayKey
        self.petsOnCareDay = petsOnCareDay
        self.treatsOnCareDay = treatsOnCareDay
    }

    private enum CodingKeys: String, CodingKey {
        case id, definitionID, name, createdAt, currentXP, acknowledgedStageIndex
        case isCurrent, isShiny, natureID, rarity, cumulativeTokens, providerTokens
        case finalEvolutionAt, graduatedAt, lastActivityAt, pendingFoodXP
        case affectionPoints, affectionUpdatedAt, careDayKey, petsOnCareDay, treatsOnCareDay
    }

    /// Records written before affection existed decode at the neutral starting value.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            definitionID: try container.decode(AnimalDefinitionID.self, forKey: .definitionID),
            name: try container.decode(String.self, forKey: .name),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            currentXP: try container.decode(Int64.self, forKey: .currentXP),
            acknowledgedStageIndex: try container.decode(Int.self, forKey: .acknowledgedStageIndex),
            isCurrent: try container.decode(Bool.self, forKey: .isCurrent),
            isShiny: try container.decode(Bool.self, forKey: .isShiny),
            natureID: try container.decode(String.self, forKey: .natureID),
            rarity: try container.decode(AnimalRarity.self, forKey: .rarity),
            cumulativeTokens: try container.decodeIfPresent(Int64.self, forKey: .cumulativeTokens) ?? 0,
            providerTokens: try container.decodeIfPresent([ProviderID: Int64].self, forKey: .providerTokens) ?? [:],
            finalEvolutionAt: try container.decodeIfPresent(Date.self, forKey: .finalEvolutionAt),
            graduatedAt: try container.decodeIfPresent(Date.self, forKey: .graduatedAt),
            lastActivityAt: try container.decodeIfPresent(Date.self, forKey: .lastActivityAt),
            pendingFoodXP: try container.decodeIfPresent(Int64.self, forKey: .pendingFoodXP) ?? 0,
            affectionPoints: try container.decodeIfPresent(Int64.self, forKey: .affectionPoints) ?? 5_000,
            affectionUpdatedAt: try container.decodeIfPresent(Date.self, forKey: .affectionUpdatedAt),
            careDayKey: try container.decodeIfPresent(String.self, forKey: .careDayKey) ?? "",
            petsOnCareDay: try container.decodeIfPresent(Int.self, forKey: .petsOnCareDay) ?? 0,
            treatsOnCareDay: try container.decodeIfPresent(Int.self, forKey: .treatsOnCareDay) ?? 0
        )
    }
}
