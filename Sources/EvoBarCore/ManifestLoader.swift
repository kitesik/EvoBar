import Foundation

public enum ManifestValidationError: Error, Equatable, CustomStringConvertible {
    case unsupportedVersion(Int)
    case wrongAnimalCount(Int)
    case duplicateAnimalID(String)
    case duplicateSortOrder(Int)
    case wrongStarterCount(Int)
    case wrongStageCount(animalID: String, count: Int)
    case invalidStageSequence(animalID: String)
    case invalidHexColor(animalID: String)
    case invalidHatchWeight(animalID: String)
    case missingProduct(String)
    case duplicateProductID(String)
    case invalidEconomy
    case invalidPricing

    public var description: String {
        switch self {
        case .unsupportedVersion(let value): "Unsupported manifest schema version: \(value)"
        case .wrongAnimalCount(let count): "Expected 10 animals, found \(count)"
        case .duplicateAnimalID(let id): "Duplicate animal ID: \(id)"
        case .duplicateSortOrder(let order): "Duplicate animal sort order: \(order)"
        case .wrongStarterCount(let count): "Expected 2 starters, found \(count)"
        case .wrongStageCount(let id, let count): "Expected 5 stages for \(id), found \(count)"
        case .invalidStageSequence(let id): "Invalid stage sequence for \(id)"
        case .invalidHexColor(let id): "Invalid theme color for \(id)"
        case .invalidHatchWeight(let id): "Invalid hatch profile for \(id)"
        case .missingProduct(let id): "Missing storefront product for \(id)"
        case .duplicateProductID(let id): "Duplicate product ID: \(id)"
        case .invalidEconomy: "Invalid game economy manifest"
        case .invalidPricing: "Invalid model pricing manifest"
        }
    }
}

public enum ManifestLoader {
    public static func bundledCatalog() throws -> AnimalCatalogManifest {
        try decode(AnimalCatalogManifest.self, resource: "animals.v1")
    }

    public static func bundledStorefront() throws -> StorefrontManifest {
        try decode(StorefrontManifest.self, resource: "storefront.v1")
    }

    public static func bundledEconomy() throws -> GameEconomyManifest {
        try decode(GameEconomyManifest.self, resource: "game-economy.v1")
    }

    public static func bundledPricing() throws -> ModelPricingManifest {
        try decode(ModelPricingManifest.self, resource: "model-pricing.v1")
    }

    public static func validate(pricing: ModelPricingManifest) throws {
        var modelIDs = Set<String>()
        guard pricing.schemaVersion == 1,
              pricing.currencyCode == "USD",
              !pricing.sources.isEmpty,
              !pricing.models.isEmpty else {
            throw ManifestValidationError.invalidPricing
        }
        for model in pricing.models {
            guard modelIDs.insert(model.id).inserted,
                  !model.matchPatterns.isEmpty,
                  model.inputUSDPerMillion >= 0,
                  model.cachedInputUSDPerMillion >= 0,
                  model.cacheWriteUSDPerMillion.map({ $0 >= 0 }) ?? true,
                  model.outputUSDPerMillion >= 0 else {
                throw ManifestValidationError.invalidPricing
            }
        }
    }

    public static func validate(
        catalog: AnimalCatalogManifest,
        storefront: StorefrontManifest,
        economy: GameEconomyManifest
    ) throws {
        guard catalog.schemaVersion == 1, storefront.schemaVersion == 1, economy.schemaVersion == 1 else {
            throw ManifestValidationError.unsupportedVersion(
                max(catalog.schemaVersion, storefront.schemaVersion, economy.schemaVersion)
            )
        }
        guard catalog.animals.count == 10 else {
            throw ManifestValidationError.wrongAnimalCount(catalog.animals.count)
        }
        guard catalog.animals.filter(\.isStarter).count == 2 else {
            throw ManifestValidationError.wrongStarterCount(catalog.animals.filter(\.isStarter).count)
        }

        var animalIDs = Set<String>()
        var sortOrders = Set<Int>()
        for animal in catalog.animals {
            guard animalIDs.insert(animal.id.rawValue).inserted else {
                throw ManifestValidationError.duplicateAnimalID(animal.id.rawValue)
            }
            guard sortOrders.insert(animal.sortOrder).inserted else {
                throw ManifestValidationError.duplicateSortOrder(animal.sortOrder)
            }
            guard animal.stages.count == 5 else {
                throw ManifestValidationError.wrongStageCount(
                    animalID: animal.id.rawValue,
                    count: animal.stages.count
                )
            }
            let indexes = animal.stages.map(\.index)
            let thresholds = animal.stages.map(\.xpThreshold)
            guard indexes == [1, 2, 3, 4, 5], thresholds == thresholds.sorted(), thresholds.first == 0 else {
                throw ManifestValidationError.invalidStageSequence(animalID: animal.id.rawValue)
            }
            guard animal.themeColorHex.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil else {
                throw ManifestValidationError.invalidHexColor(animalID: animal.id.rawValue)
            }
            guard animal.hatchProfile.hatchWeight > 0,
                  (0...10_000).contains(animal.hatchProfile.shinyBaseRateBasisPoints) else {
                throw ManifestValidationError.invalidHatchWeight(animalID: animal.id.rawValue)
            }
        }

        var productIDs = Set<String>()
        for product in storefront.products {
            guard productIDs.insert(product.id.rawValue).inserted else {
                throw ManifestValidationError.duplicateProductID(product.id.rawValue)
            }
        }
        for animal in catalog.animals where !productIDs.contains(animal.purchaseProductID.rawValue) {
            throw ManifestValidationError.missingProduct(animal.purchaseProductID.rawValue)
        }
        guard economy.effectiveTokensPerCoin > 0,
              (0...10_000).contains(economy.baseShinyRateBasisPoints),
              (economy.baseShinyRateBasisPoints...10_000).contains(economy.charmedShinyRateBasisPoints),
              economy.items.allSatisfy({ $0.tokenCoinPrice >= 0 }) else {
            throw ManifestValidationError.invalidEconomy
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, resource: String) throws -> T {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
