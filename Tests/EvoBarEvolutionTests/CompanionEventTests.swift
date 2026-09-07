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
        let before = instance(id: id, xp: 2_000, acknowledged: 4)
        let after = instance(id: id, xp: 2_000, acknowledged: 5)
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
}
