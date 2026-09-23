import EvoBarCore
import Foundation
import Testing

@Suite struct LoreTests {
    /// Every stage of every line has a page, and every line carries at least one
    /// real prehistoric relative, so the guide is never thin for a companion.
    @Test func bundledLoreCoversEveryStageAndValidates() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let lore = try ManifestLoader.bundledLore()
        try ManifestLoader.validate(lore: lore, catalog: catalog)
        #expect(lore.lines.count == catalog.animals.count)
        for animal in catalog.animals {
            let line = try #require(lore.line(for: animal.id))
            #expect(line.entries.filter { $0.kind == .stage }.count == animal.stages.count, "\(animal.id.rawValue)")
            #expect(line.entries.contains { $0.kind == .relative }, "\(animal.id.rawValue) has no relative")
            // Relatives carry a scientific name and a size; that is what makes them real.
            for relative in line.entries where relative.kind == .relative {
                #expect(relative.scientificName != nil, "\(relative.id)")
                #expect(relative.size != nil, "\(relative.id)")
            }
            // Entries read in evolution order, so the guide follows the journey.
            let order = line.entries.map(\.stageIndex)
            #expect(order == order.sorted(), "\(animal.id.rawValue)")
        }
        #expect(lore.entryCount == 58)
    }

    @Test func pagesReadInBothCarriedLanguages() throws {
        let lore = try ManifestLoader.bundledLore()
        for entry in lore.lines.flatMap(\.entries) {
            #expect(entry.facts.count == 2, "\(entry.id)")
            #expect(!entry.name.resolved(languageCode: "ko").isEmpty && !entry.name.resolved(languageCode: "en").isEmpty, "\(entry.id)")
            // Languages the guide does not carry read English, never an empty string.
            #expect(entry.note.resolved(languageCode: "fr") == entry.note.en)
        }
    }

    /// Discovery follows the highest stage any companion of the line reached,
    /// graduated ones included, and a relative opens with the stage it sits on.
    @Test func discoveryFollowsTheHighestStageReached() throws {
        let lore = try ManifestLoader.bundledLore()
        let cat = try #require(lore.line(for: "cat"))
        #expect(FieldGuide.progress(in: lore, instances: []).discovered == 0)

        let graduated = AnimalInstance(
            definitionID: "cat", name: "Old", acknowledgedStageIndex: 4,
            natureID: "curious", rarity: .common, graduatedAt: Date())
        let current = AnimalInstance(
            definitionID: "cat", name: "New", acknowledgedStageIndex: 2, isCurrent: true,
            natureID: "steady", rarity: .common)
        let reached = FieldGuide.reachedStage(of: "cat", in: [graduated, current])
        #expect(reached == 4)
        let open = cat.entries.filter { FieldGuide.isDiscovered($0, reachedStage: reached) }.map(\.id)
        #expect(open.contains("cat.relative.proailurus"))
        #expect(open.contains("cat.4"))
        #expect(!open.contains("cat.5"))
        #expect(!open.contains("cat.6"))
        #expect(FieldGuide.progress(in: lore, instances: [graduated, current]).discovered == open.count)
        #expect(FieldGuide.reachedStage(of: "dog", in: [graduated, current]) == 0)
    }
}
