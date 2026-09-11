import EvoBarCore
import Foundation

public enum CompanionEventKind: String, Equatable, Sendable {
    /// The companion has enough XP for its next stage and is waiting to be evolved.
    case evolutionReady
    /// The user evolved the companion; the new stage is now current.
    case evolved
    /// The companion reached its final stage and can graduate into the collection.
    case graduationReady
    /// A new companion started, either chosen or hatched.
    case hatched
    /// A hatch produced a shiny variant.
    case shiny
    /// A daily token-coin balance milestone was crossed.
    case coinMilestone
    /// The companion's mood moved to a different band.
    case moodChanged
    /// The bond reached a level it had not before.
    case bondLevelReached
}

public struct CompanionEvent: Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: CompanionEventKind
    public let animalInstanceID: UUID
    public let companionName: String
    /// Stage the event points at; 0 for events that are not about a stage.
    public let targetStageIndex: Int
    /// Stage or line name the message shows; empty when unused.
    public let targetStageName: String
    /// Coin balance for `coinMilestone`; 0 otherwise.
    public let value: Int64

    public init(
        id: String,
        kind: CompanionEventKind,
        animalInstanceID: UUID,
        companionName: String,
        targetStageIndex: Int = 0,
        targetStageName: String = "",
        value: Int64 = 0
    ) {
        self.id = id
        self.kind = kind
        self.animalInstanceID = animalInstanceID
        self.companionName = companionName
        self.targetStageIndex = targetStageIndex
        self.targetStageName = targetStageName
        self.value = value
    }
}

public enum CompanionEventEngine {
    /// Coin balances worth announcing once each.
    public static let coinMilestones: [Int64] = [10, 50, 100, 250, 500, 1_000, 2_500, 5_000]

    /// Diffs two snapshots of the active companion. Every event is derived from a
    /// transition, so a repeated scan that changes nothing produces nothing, and
    /// each identifier is stable enough for the notification centre to coalesce.
    public static func events(
        previous: AnimalInstance?,
        current: AnimalInstance?,
        definition: AnimalDefinition?,
        previousCoins: Int64 = 0,
        currentCoins: Int64 = 0,
        now: Date = Date()
    ) -> [CompanionEvent] {
        var events: [CompanionEvent] = []
        events.append(contentsOf: coinEvents(
            previous: previousCoins,
            current: currentCoins,
            instance: current
        ))

        guard let current, let definition, current.isCurrent else { return events }

        if let previous, previous.id == current.id {
            let before = AffectionEngine.mood(for: AffectionEngine.currentPoints(
                stored: previous.affectionPoints,
                updatedAt: previous.affectionUpdatedAt,
                now: now
            ))
            let after = AffectionEngine.mood(for: AffectionEngine.currentPoints(
                stored: current.affectionPoints,
                updatedAt: current.affectionUpdatedAt,
                now: now
            ))
            // Only the bands worth interrupting for: the two unhappy ones and the top.
            if before != after, [.distant, .sulking, .adoring].contains(after) {
                events.append(CompanionEvent(
                    id: "companion|\(current.id.uuidString)|mood|\(after.rawValue)",
                    kind: .moodChanged,
                    animalInstanceID: current.id,
                    companionName: current.name,
                    targetStageName: after.rawValue
                ))
            }
        }

        if let previous, previous.id == current.id {
            let before = BondEngine.level(forCareCount: previous.careCount)
            let after = BondEngine.level(forCareCount: current.careCount)
            if after > before {
                events.append(CompanionEvent(
                    id: "companion|\(current.id.uuidString)|bond|\(after.rawValue)",
                    kind: .bondLevelReached,
                    animalInstanceID: current.id,
                    companionName: current.name,
                    targetStageName: after.titleKey
                ))
            }
        }

        // A different individual than last time means a hatch or a chosen start.
        guard let previous, previous.id == current.id else {
            if previous != nil {
                events.append(CompanionEvent(
                    id: "companion|\(current.id.uuidString)|hatched",
                    kind: .hatched,
                    animalInstanceID: current.id,
                    companionName: current.name,
                    targetStageName: definition.fallbackDisplayName
                ))
                if current.isShiny {
                    events.append(CompanionEvent(
                        id: "companion|\(current.id.uuidString)|shiny",
                        kind: .shiny,
                        animalInstanceID: current.id,
                        companionName: current.name,
                        targetStageName: definition.fallbackDisplayName
                    ))
                }
            }
            return events
        }

        let finalIndex = definition.stages.count

        // The user acted: the acknowledged stage moved forward.
        if current.acknowledgedStageIndex > previous.acknowledgedStageIndex {
            let stage = definition.stages.first { $0.index == current.acknowledgedStageIndex }
            events.append(CompanionEvent(
                id: "companion|\(current.id.uuidString)|evolved|\(current.acknowledgedStageIndex)",
                kind: .evolved,
                animalInstanceID: current.id,
                companionName: current.name,
                targetStageIndex: current.acknowledgedStageIndex,
                targetStageName: stage?.fallbackName ?? ""
            ))
            if current.acknowledgedStageIndex >= finalIndex {
                events.append(CompanionEvent(
                    id: "companion|\(current.id.uuidString)|graduation-ready",
                    kind: .graduationReady,
                    animalInstanceID: current.id,
                    companionName: current.name,
                    targetStageIndex: finalIndex,
                    targetStageName: stage?.fallbackName ?? ""
                ))
            }
            return events
        }

        // Otherwise growth may have unlocked the next stage.
        guard previous.acknowledgedStageIndex == current.acknowledgedStageIndex,
              let target = EvolutionEngine.nextStage(
                after: current.acknowledgedStageIndex,
                stages: definition.stages
              ) else { return events }

        let previousEligible = EvolutionEngine.eligibleStageIndex(
            xp: previous.currentXP,
            stages: definition.stages
        )
        let currentEligible = EvolutionEngine.eligibleStageIndex(
            xp: current.currentXP,
            stages: definition.stages
        )
        guard previousEligible < target.index, currentEligible >= target.index else { return events }

        events.append(CompanionEvent(
            id: "companion|\(current.id.uuidString)|evolution-ready|\(target.index)",
            kind: .evolutionReady,
            animalInstanceID: current.id,
            companionName: current.name,
            targetStageIndex: target.index,
            targetStageName: target.fallbackName
        ))
        return events
    }

    private static func coinEvents(
        previous: Int64,
        current: Int64,
        instance: AnimalInstance?
    ) -> [CompanionEvent] {
        guard let instance, current > previous else { return [] }
        // Only the highest milestone crossed, so a long catch-up scan stays quiet.
        guard let milestone = coinMilestones.last(where: { $0 > previous && $0 <= current }) else {
            return []
        }
        return [CompanionEvent(
            id: "wallet|milestone|\(milestone)",
            kind: .coinMilestone,
            animalInstanceID: instance.id,
            companionName: instance.name,
            value: milestone
        )]
    }
}
