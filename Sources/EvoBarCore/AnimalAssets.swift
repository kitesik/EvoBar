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

public enum BundledAnimalSpriteStore {
    /// Whether a line ships with artwork. A line without it would appear as a
    /// bare emoji, so it is never sold, granted or hatched.
    public static func hasArtwork(for animal: AnimalDefinition) -> Bool {
        guard let first = animal.stages.first else { return false }
        return imageData(
            for: AnimalAssetReference(
                assetID: first.normalAssetID,
                fallbackEmoji: animal.menuBarEmoji,
                visualState: .idle
            )
        ) != nil
    }

    /// Whether this stage has its own sprites, rather than borrowing a neighbour's
    /// until its sheet is drawn.
    public static func hasArtwork(for animal: AnimalDefinition, stageIndex: Int) -> Bool {
        guard let stage = animal.stages.first(where: { $0.index == stageIndex }),
              stage.artworkPending != true else { return false }
        return imageData(
            for: AnimalAssetReference(
                assetID: stage.normalAssetID, fallbackEmoji: animal.menuBarEmoji, visualState: .idle)
        ) != nil
    }

    public static func imageData(for reference: AnimalAssetReference) -> Data? {
        for resourceName in resourceNameCandidates(for: reference) {
            let url = Bundle.module.url(
                forResource: resourceName,
                withExtension: "png",
                subdirectory: "Sprites"
            ) ?? Bundle.module.url(forResource: resourceName, withExtension: "png")
            if let url, let data = try? Data(contentsOf: url), !data.isEmpty {
                return data
            }
        }
        return nil
    }

    public static func resourceNameCandidates(for reference: AnimalAssetReference) -> [String] {
        let state = reference.visualState.rawValue
        let normalAssetID = reference.assetID.hasSuffix(".shiny")
            ? String(reference.assetID.dropLast(".shiny".count))
            : reference.assetID
        return [
            "\(reference.assetID).\(state)",
            "\(normalAssetID).\(state)",
            "\(reference.assetID).idle",
            "\(normalAssetID).idle",
        ].reduce(into: []) { result, candidate in
            if !result.contains(candidate) { result.append(candidate) }
        }
    }
}
