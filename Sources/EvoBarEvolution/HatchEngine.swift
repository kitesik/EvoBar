import EvoBarCore
import Foundation

public enum HatchError: Error, Equatable {
    case noOwnedAnimals
    case noNatures
    case invalidWeight
}

public struct HatchResult: Equatable, Sendable {
    public let animal: AnimalDefinition
    public let nature: NatureDefinition
    public let isShiny: Bool
}

public enum HatchEngine {
    public static func hatch<R: RandomNumberGenerator>(
        ownedAnimalIDs: Set<AnimalDefinitionID>,
        catalog: AnimalCatalogManifest,
        economy: GameEconomyManifest,
        hasShinyCharm: Bool,
        using generator: inout R
    ) throws -> HatchResult {
        // A line whose artwork has not shipped would hatch as a bare emoji.
        let candidates = catalog.animals
            .filter { ownedAnimalIDs.contains($0.id) && BundledAnimalSpriteStore.hasArtwork(for: $0) }
            .sorted { $0.sortOrder < $1.sortOrder }
        guard !candidates.isEmpty else { throw HatchError.noOwnedAnimals }
        guard !catalog.natures.isEmpty else { throw HatchError.noNatures }

        let totalWeight = candidates.reduce(0) { $0 + $1.hatchProfile.hatchWeight }
        guard totalWeight > 0 else { throw HatchError.invalidWeight }
        var roll = Int.random(in: 0..<totalWeight, using: &generator)
        let animal = candidates.first { candidate in
            if roll < candidate.hatchProfile.hatchWeight { return true }
            roll -= candidate.hatchProfile.hatchWeight
            return false
        } ?? candidates[candidates.count - 1]

        let natureIndex = Int.random(in: 0..<catalog.natures.count, using: &generator)
        let shinyRate = hasShinyCharm
            ? economy.charmedShinyRateBasisPoints
            : animal.hatchProfile.shinyBaseRateBasisPoints
        let shinyRoll = Int.random(in: 0..<10_000, using: &generator)

        return HatchResult(
            animal: animal,
            nature: catalog.natures[natureIndex],
            isShiny: shinyRoll < shinyRate
        )
    }
}
