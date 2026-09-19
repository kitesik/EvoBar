import EvoBarCore
import Foundation
import Testing

struct CollectionProgressTests {
    @Test func licensesAloneNeverCountAsDiscoveries() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let progress = CollectionProgress(animals: catalog.animals, instances: [])
        #expect(progress.discoveredLineIDs.isEmpty)
        #expect(progress.discoveredForms == 0)
        #expect(progress.totalLines == catalog.animals.count)
        #expect(progress.totalForms == catalog.animals.reduce(0) { $0 + $1.stages.count })
    }

    @Test func duplicatesAndSwitchingDoNotEraseOrInflateProgress() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let cat = try #require(catalog.animals.first { $0.id == "cat" })
        let retired = AnimalInstance(definitionID: "cat", name: "First friend",
            acknowledgedStageIndex: 4, natureID: "curious", rarity: .common, graduatedAt: Date())
        var current = AnimalInstance(definitionID: "cat", name: "Second friend",
            acknowledgedStageIndex: 1, isCurrent: true, isShiny: true, natureID: "curious", rarity: .common)
        let first = CollectionProgress(animals: catalog.animals, instances: [retired, current])
        current.isCurrent = false
        let switched = CollectionProgress(animals: catalog.animals, instances: [current, retired, retired])
        #expect(first == switched)
        #expect(first.discoveredLineIDs == ["cat"])
        #expect(first.discoveredForms == 4)
        #expect(first.nextUndiscoveredStage(in: cat)?.index == 5)
    }

    @Test func unknownAndInvalidRecordsCannotOverfillTheCollection() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let cat = try #require(catalog.animals.first { $0.id == "cat" })
        let progress = CollectionProgress(animals: catalog.animals, instances: [
            AnimalInstance(definitionID: "missing", name: "Unknown", acknowledgedStageIndex: 100, natureID: "curious", rarity: .common),
            AnimalInstance(definitionID: "cat", name: "Cat", acknowledgedStageIndex: 100, natureID: "curious", rarity: .common),
            AnimalInstance(definitionID: "dog", name: "Dog", acknowledgedStageIndex: -1, natureID: "steady", rarity: .common),
        ])
        #expect(progress.discoveredLineIDs == ["cat"])
        #expect(progress.discoveredForms == cat.stages.count)
        #expect(progress.reachedStage(for: "dog") == 0)
        #expect(progress.nextUndiscoveredStage(in: cat) == nil)
        #expect(CollectionProgress(animals: [], instances: []).totalForms == 0)
    }

    @Test func evolutionAddsExactlyOneNewFormAndHatchingAddsOneLine() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        var cat = AnimalInstance(definitionID: "cat", name: "Cat", natureID: "curious", rarity: .common)
        let first = CollectionProgress(animals: catalog.animals, instances: [cat])
        cat.acknowledgedStageIndex = 2
        let grown = CollectionProgress(animals: catalog.animals, instances: [cat])
        let hatched = CollectionProgress(animals: catalog.animals, instances: [cat,
            AnimalInstance(definitionID: "dog", name: "Dog", natureID: "steady", rarity: .common)])
        #expect(grown.discoveredForms == first.discoveredForms + 1)
        #expect(grown.discoveredLineIDs == first.discoveredLineIDs)
        #expect(hatched.discoveredForms == grown.discoveredForms + 1)
        #expect(hatched.discoveredLineIDs.count == grown.discoveredLineIDs.count + 1)
    }
}
