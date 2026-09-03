import EvoBarCore
import Foundation

public enum CompanionEventKind: String, Equatable, Sendable {
    case evolutionReady
}

public struct CompanionEvent: Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: CompanionEventKind
    public let animalInstanceID: UUID
    public let companionName: String
    public let targetStageIndex: Int
    public let targetStageName: String

    public init(
        id: String,
        kind: CompanionEventKind,
        animalInstanceID: UUID,
        companionName: String,
        targetStageIndex: Int,
        targetStageName: String
    ) {
        self.id = id
        self.kind = kind
        self.animalInstanceID = animalInstanceID
        self.companionName = companionName
        self.targetStageIndex = targetStageIndex
        self.targetStageName = targetStageName
    }
}

public enum CompanionEventEngine {
    public static func events(
        previous: AnimalInstance?,
        current: AnimalInstance?,
        definition: AnimalDefinition?
    ) -> [CompanionEvent] {
        guard let previous,
              let current,
              let definition,
              previous.id == current.id,
              current.isCurrent,
              previous.acknowledgedStageIndex == current.acknowledgedStageIndex,
              let target = EvolutionEngine.nextStage(
                after: current.acknowledgedStageIndex,
                stages: definition.stages
              ) else { return [] }

        let previousEligible = EvolutionEngine.eligibleStageIndex(
            xp: previous.currentXP,
            stages: definition.stages
        )
        let currentEligible = EvolutionEngine.eligibleStageIndex(
            xp: current.currentXP,
            stages: definition.stages
        )
        guard previousEligible < target.index, currentEligible >= target.index else { return [] }

        return [CompanionEvent(
            id: "companion|\(current.id.uuidString)|evolution-ready|\(target.index)",
            kind: .evolutionReady,
            animalInstanceID: current.id,
            companionName: current.name,
            targetStageIndex: target.index,
            targetStageName: target.fallbackName
        )]
    }
}
