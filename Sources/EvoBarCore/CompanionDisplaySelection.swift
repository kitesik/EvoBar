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
        let instance = instances.filter { $0.definitionID == pinnedDefinitionID }.max {
            if $0.acknowledgedStageIndex != $1.acknowledgedStageIndex {
                return $0.acknowledgedStageIndex < $1.acknowledgedStageIndex
            }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        // An owned line that has never hatched is shown as a stage-one preview.
        return CompanionDisplaySelection(definitionID: pinnedDefinitionID, instance: instance)
    }
}
