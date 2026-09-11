import EvoBarCore
import EvoBarEvolution
import Foundation
import Testing

@Suite struct CompanionEventTests {
    private func catalogCat() throws -> AnimalDefinition {
        try #require(ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" })
    }

    private func instance(
        id: UUID,
        xp: Int64,
        acknowledged: Int,
        shiny: Bool = false
    ) -> AnimalInstance {
        AnimalInstance(
            id: id,
            definitionID: "cat",
            name: "Mochi",
            currentXP: xp,
            acknowledgedStageIndex: acknowledged,
            isCurrent: true,
            isShiny: shiny,
            natureID: "curious",
            rarity: .common
        )
    }

    @Test func acknowledgingAStageReportsEvolvedAndFinalForm() throws {
        let cat = try catalogCat()
        let id = UUID()
        // The final form is whatever the ladder ends on, seven stages for the cat.
        let final = cat.stages.count
        let xp = try #require(cat.stages.last?.xpThreshold)
        let before = instance(id: id, xp: xp, acknowledged: final - 1)
        let after = instance(id: id, xp: xp, acknowledged: final)
        let kinds = CompanionEventEngine.events(previous: before, current: after, definition: cat).map(\.kind)
        #expect(kinds == [.evolved, .graduationReady])
    }

    @Test func aDifferentIndividualReportsHatchAndShiny() throws {
        let cat = try catalogCat()
        let before = instance(id: UUID(), xp: 2_000, acknowledged: 5)
        let after = instance(id: UUID(), xp: 0, acknowledged: 1, shiny: true)
        let kinds = CompanionEventEngine.events(previous: before, current: after, definition: cat).map(\.kind)
        #expect(kinds == [.hatched, .shiny])
    }

    @Test func onlyTheHighestCoinMilestoneCrossedIsReported() throws {
        let cat = try catalogCat()
        let id = UUID()
        let steady = instance(id: id, xp: 10, acknowledged: 1)
        let events = CompanionEventEngine.events(
            previous: steady,
            current: steady,
            definition: cat,
            previousCoins: 5,
            currentCoins: 120
        )
        #expect(events.map(\.kind) == [.coinMilestone])
        #expect(events.first?.value == 100)
    }

    @Test func unchangedStateAndSpentCoinsReportNothing() throws {
        let cat = try catalogCat()
        let id = UUID()
        let steady = instance(id: id, xp: 10, acknowledged: 1)
        #expect(CompanionEventEngine.events(
            previous: steady,
            current: steady,
            definition: cat,
            previousCoins: 300,
            currentCoins: 40
        ).isEmpty)
    }

    /// Crossing a bond threshold is announced once, and staying inside one is
    /// not announced at all.
    @Test func aRisingBondIsReportedOnce() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let definition = try #require(catalog.animals.first { $0.id == "cat" })
        let before = AnimalInstance(
            definitionID: "cat", name: "Mochi", isCurrent: true, natureID: "curious",
            rarity: .common, careCount: 19)
        var after = before
        after.careCount = 20
        let crossed = CompanionEventEngine.events(
            previous: before, current: after, definition: definition)
        #expect(crossed.contains { $0.kind == .bondLevelReached })
        #expect(crossed.first { $0.kind == .bondLevelReached }?.targetStageName == BondLevel.familiar.titleKey)

        var same = after
        same.careCount = 21
        let quiet = CompanionEventEngine.events(
            previous: after, current: same, definition: definition)
        #expect(!quiet.contains { $0.kind == .bondLevelReached })
    }
}
