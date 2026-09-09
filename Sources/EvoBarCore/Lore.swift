import Foundation

/// Text carried in Korean and English. The other app languages read English,
/// so the guide can grow without waiting on six translations of every fact.
public struct LoreText: Codable, Equatable, Sendable {
    public let ko: String
    public let en: String

    public init(ko: String, en: String) {
        self.ko = ko
        self.en = en
    }

    public func resolved(languageCode: String) -> String {
        languageCode.lowercased().hasPrefix("ko") ? ko : en
    }
}

/// How big the animal got, in one figure a reader can picture next to a person.
public struct LoreSize: Codable, Equatable, Sendable {
    public enum Measure: String, Codable, Sendable {
        case length
        case wingspan
        case shoulder
    }

    public let meters: Double
    public let measure: Measure
    public let kilograms: Double?
    public let label: LoreText
}

/// One page of the field guide: the real animal, era and size behind an
/// evolution stage, or a prehistoric relative met on the way up.
public struct LoreEntry: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case stage
        case relative
    }

    public let id: String
    public let kind: Kind
    /// The stage this page belongs to. A relative is discovered when a
    /// companion of the line reaches that stage.
    public let stageIndex: Int
    public let name: LoreText
    public let scientificName: String?
    public let era: LoreText
    public let region: LoreText
    public let size: LoreSize?
    public let facts: [LoreText]
    /// The one detail an enthusiast would tell a friend.
    public let note: LoreText
}

public struct LoreLine: Codable, Equatable, Sendable {
    public let animalID: AnimalDefinitionID
    /// In evolution order: each stage, then the relatives discovered with it.
    public let entries: [LoreEntry]
}

public struct LoreManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let lines: [LoreLine]

    public func line(for animalID: AnimalDefinitionID) -> LoreLine? {
        lines.first { $0.animalID == animalID }
    }

    public var entryCount: Int { lines.reduce(0) { $0 + $1.entries.count } }
}

/// What the user has uncovered. Discovery is read straight from the companions
/// they have raised, graduated ones included, so nothing extra is persisted and
/// nothing can drift out of step with the collection.
public enum FieldGuide {
    /// Highest stage any companion of the line reached; 0 when never raised.
    public static func reachedStage(of animalID: AnimalDefinitionID, in instances: [AnimalInstance]) -> Int {
        instances.filter { $0.definitionID == animalID }.map(\.acknowledgedStageIndex).max() ?? 0
    }

    public static func isDiscovered(_ entry: LoreEntry, reachedStage: Int) -> Bool {
        entry.stageIndex <= reachedStage
    }

    public static func progress(in lore: LoreManifest, instances: [AnimalInstance]) -> (discovered: Int, total: Int) {
        var discovered = 0
        for line in lore.lines {
            let reached = reachedStage(of: line.animalID, in: instances)
            discovered += line.entries.filter { isDiscovered($0, reachedStage: reached) }.count
        }
        return (discovered, lore.entryCount)
    }
}
