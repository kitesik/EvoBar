import Foundation

/// How completely a line has been explored, derived from the individuals kept
/// in the collection. Nothing is stored for it: a line's mastery is a fact
/// about the record, the way the field guide's discovery is.
///
/// The three parts are deliberately different kinds of work. Every stage is
/// patience, a shiny is luck, and three natures is the collection loop turning
/// more than once. A line asks for all three, so mastering one is a season
/// rather than an afternoon.
public struct LineMastery: Equatable, Sendable {
    public static let naturesNeeded = 3

    public let stagesSeen: Int
    public let stages: Int
    public let hasShiny: Bool
    public let naturesSeen: Int
    public let raised: Int

    public var everyStageSeen: Bool { stages > 0 && stagesSeen >= stages }
    public var enoughNatures: Bool { naturesSeen >= Self.naturesNeeded }
    public var isMastered: Bool { everyStageSeen && hasShiny && enoughNatures }

    /// Parts finished, of three.
    public var partsDone: Int {
        [everyStageSeen, hasShiny, enoughNatures].filter { $0 }.count
    }

    public init(stagesSeen: Int, stages: Int, hasShiny: Bool, naturesSeen: Int, raised: Int) {
        self.stagesSeen = stagesSeen
        self.stages = stages
        self.hasShiny = hasShiny
        self.naturesSeen = naturesSeen
        self.raised = raised
    }

    /// A line's mastery, read off every individual of it ever raised. The
    /// highest stage any one of them reached counts for all of them, because a
    /// graduated companion's record keeps what it reached.
    public static func of(
        _ animal: AnimalDefinition, instances: [AnimalInstance]
    ) -> LineMastery {
        let own = instances.filter { $0.definitionID == animal.id }
        return LineMastery(
            stagesSeen: own.map(\.acknowledgedStageIndex).max() ?? 0,
            stages: animal.stages.count,
            hasShiny: own.contains(where: \.isShiny),
            naturesSeen: Set(own.map(\.natureID)).count,
            raised: own.count
        )
    }

    public static func masteredCount(
        in catalog: AnimalCatalogManifest, instances: [AnimalInstance]
    ) -> Int {
        catalog.animals.filter { of($0, instances: instances).isMastered }.count
    }
}
