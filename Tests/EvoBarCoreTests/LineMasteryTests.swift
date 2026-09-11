import EvoBarCore
import Foundation
import Testing

@Suite struct LineMasteryTests {
    private func instance(
        stage: Int, shiny: Bool = false, nature: String = "curious"
    ) -> AnimalInstance {
        AnimalInstance(
            definitionID: "cat", name: "Mochi", acknowledgedStageIndex: stage, isShiny: shiny,
            natureID: nature, rarity: .common)
    }

    /// A line asks for patience, luck and a turn of the collection loop, and
    /// gives its crown only when it has all three.
    @Test func masteryNeedsEveryStageAShinyAndThreeNatures() throws {
        let cat = try #require(try ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" })
        let top = cat.stages.count

        let fresh = LineMastery.of(cat, instances: [])
        #expect(fresh.partsDone == 0)
        #expect(!fresh.isMastered)
        #expect(fresh.raised == 0)

        let patient = LineMastery.of(cat, instances: [instance(stage: top)])
        #expect(patient.everyStageSeen)
        #expect(patient.partsDone == 1)
        #expect(!patient.isMastered)

        let lucky = LineMastery.of(cat, instances: [
            instance(stage: top), instance(stage: 2, shiny: true, nature: "steady"),
        ])
        #expect(lucky.hasShiny)
        #expect(lucky.naturesSeen == 2)
        #expect(lucky.partsDone == 2)
        #expect(!lucky.isMastered)

        let complete = LineMastery.of(cat, instances: [
            instance(stage: top), instance(stage: 2, shiny: true, nature: "steady"),
            instance(stage: 1, nature: "bright"),
        ])
        #expect(complete.isMastered)
        #expect(complete.partsDone == 3)
        #expect(complete.raised == 3)
    }

    /// Another line's individuals say nothing about this one.
    @Test func masteryIgnoresOtherLines() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let cat = try #require(catalog.animals.first { $0.id == "cat" })
        let dogs = (1...3).map { index in
            AnimalInstance(
                definitionID: "dog", name: "Biscuit\(index)", acknowledgedStageIndex: 7,
                isShiny: true, natureID: ["curious", "steady", "bright"][index - 1], rarity: .common)
        }
        #expect(LineMastery.of(cat, instances: dogs).partsDone == 0)
        #expect(LineMastery.masteredCount(in: catalog, instances: dogs) == 1)
    }
}
