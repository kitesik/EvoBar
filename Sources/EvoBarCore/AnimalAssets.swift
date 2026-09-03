import Foundation

public enum CompanionVisualState: String, Codable, Sendable {
    case idle
    case working
    case evolutionReady
    case sleeping
}

public struct AnimalAssetReference: Equatable, Sendable {
    public let assetID: String
    public let fallbackEmoji: String
    public let visualState: CompanionVisualState

    public init(assetID: String, fallbackEmoji: String, visualState: CompanionVisualState) {
        self.assetID = assetID
        self.fallbackEmoji = fallbackEmoji
        self.visualState = visualState
    }
}

public protocol AnimalAssetProviding: Sendable {
    func asset(
        for animal: AnimalDefinition,
        stageIndex: Int,
        isShiny: Bool,
        visualState: CompanionVisualState
    ) -> AnimalAssetReference
}

public struct ManifestAnimalAssetProvider: AnimalAssetProviding {
    public init() {}

    public func asset(
        for animal: AnimalDefinition,
        stageIndex: Int,
        isShiny: Bool,
        visualState: CompanionVisualState
    ) -> AnimalAssetReference {
        let stage = animal.stages.first { $0.index == stageIndex } ?? animal.stages.first
        let assetID: String
        if let stage {
            assetID = isShiny ? stage.shinyAssetID : stage.normalAssetID
        } else {
            assetID = animal.lockedSilhouetteAssetID
        }
        return AnimalAssetReference(
            assetID: assetID,
            fallbackEmoji: animal.menuBarEmoji,
            visualState: visualState
        )
    }
}
