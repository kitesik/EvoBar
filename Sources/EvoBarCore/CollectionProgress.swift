import Foundation

/// A record of encounters, not purchases. Duplicate individuals and newly
/// granted licenses never inflate discovery progress; retired friends count.
public struct CollectionProgress: Equatable, Sendable {
    public let discoveredLineIDs: Set<AnimalDefinitionID>
    public let totalLines: Int
    public let discoveredForms: Int
    public let totalForms: Int
    private let reachedStages: [AnimalDefinitionID: Int]

    public init(animals: [AnimalDefinition], instances: [AnimalInstance]) {
        var reached: [AnimalDefinitionID: Int] = [:]
        var formCount = 0
        for animal in animals {
            let maximum = instances.lazy.filter { $0.definitionID == animal.id }
                .map(\.acknowledgedStageIndex).max() ?? 0
            let revealed = animal.stages.filter { $0.index <= maximum }
            if let stage = revealed.map(\.index).max() { reached[animal.id] = stage }
            formCount += revealed.count
        }
        reachedStages = reached
        discoveredLineIDs = Set(reached.keys)
        totalLines = animals.count
        discoveredForms = formCount
        totalForms = animals.reduce(0) { $0 + $1.stages.count }
    }

    public func reachedStage(for id: AnimalDefinitionID) -> Int { reachedStages[id] ?? 0 }

    public func nextUndiscoveredStage(in animal: AnimalDefinition) -> EvolutionStageDefinition? {
        animal.stages.filter { $0.index > reachedStage(for: animal.id) }.min { $0.index < $1.index }
    }
}
