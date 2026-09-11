import Foundation

/// Presentation only: choosing a pinned animal never creates an individual or
/// changes which individual receives usage, food, or XP.
public struct CompanionDisplaySelection: Equatable, Sendable {
    public let definitionID: AnimalDefinitionID
    public let instance: AnimalInstance?

    public var stageIndex: Int { instance?.acknowledgedStageIndex ?? 1 }
    public var isShiny: Bool { instance?.isShiny ?? false }

    public static func resolve(
        currentDefinitionID: AnimalDefinitionID,
        pinnedDefinitionID: AnimalDefinitionID?,
        ownedDefinitionIDs: Set<AnimalDefinitionID>,
        availableDefinitionIDs: Set<AnimalDefinitionID>,
        instances: [AnimalInstance]
    ) -> CompanionDisplaySelection {
        guard let pinnedDefinitionID,
              ownedDefinitionIDs.contains(pinnedDefinitionID),
              availableDefinitionIDs.contains(pinnedDefinitionID) else {
            return CompanionDisplaySelection(
                definitionID: currentDefinitionID,
                instance: instances.first { $0.isCurrent && $0.definitionID == currentDefinitionID }
            )
        }
        let instance = representativeInstance(for: pinnedDefinitionID, in: instances)
        // An owned line that has never hatched is shown as a stage-one preview.
        return CompanionDisplaySelection(definitionID: pinnedDefinitionID, instance: instance)
    }

    /// Collection tiles, their detail header and pinned surfaces share one
    /// representative, including its normal/Shiny appearance. A lower-stage
    /// Shiny never reveals a higher Shiny form reached only by a normal animal.
    public static func representativeInstance(
        for definitionID: AnimalDefinitionID, in instances: [AnimalInstance]
    ) -> AnimalInstance? {
        instances.filter { $0.definitionID == definitionID }.max {
            if $0.acknowledgedStageIndex != $1.acknowledgedStageIndex {
                return $0.acknowledgedStageIndex < $1.acknowledgedStageIndex
            }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
