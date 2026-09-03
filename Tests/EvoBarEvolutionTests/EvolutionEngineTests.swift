import EvoBarCore
import EvoBarEvolution
import Foundation
import Testing

@Suite struct EvolutionEngineTests {
    @Test func effectiveTokenBoundaries() {
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 0) == 0)
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 500_000) == 500_000)
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 1_000_000) == 1_000_000)
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 5_000_000) == 3_000_000)
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 20_000_000) == 6_000_000)
        #expect(EffectiveTokenCalculator.effectiveTokens(for: 40_000_000) == 7_000_000)
        #expect(EffectiveTokenCalculator.targetXP(forRawTokens: 500_000) == 50)
    }

    @Test func dailyLedgerOnlyAwardsPositiveDifference() {
        var ledger = DailyGrowthLedger()
        let first = ledger.recompute(rawTokens: 500_000, effectiveTokensPerCoin: 100_000)
        let duplicate = ledger.recompute(rawTokens: 500_000, effectiveTokensPerCoin: 100_000)
        let increased = ledger.recompute(rawTokens: 1_000_000, effectiveTokensPerCoin: 100_000)
        #expect(first.xpDelta == 50)
        #expect(first.tokenCoinDelta == 5)
        #expect(duplicate.xpDelta == 0)
        #expect(duplicate.tokenCoinDelta == 0)
        #expect(increased.xpDelta == 50)
        #expect(increased.tokenCoinDelta == 5)
    }

    @Test func allEvolutionThresholds() throws {
        let cat = try #require(try ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" })
        #expect(EvolutionEngine.eligibleStageIndex(xp: 0, stages: cat.stages) == 1)
        #expect(EvolutionEngine.eligibleStageIndex(xp: 49, stages: cat.stages) == 1)
        #expect(EvolutionEngine.eligibleStageIndex(xp: 50, stages: cat.stages) == 2)
        #expect(EvolutionEngine.eligibleStageIndex(xp: 300, stages: cat.stages) == 3)
        #expect(EvolutionEngine.eligibleStageIndex(xp: 900, stages: cat.stages) == 4)
        #expect(EvolutionEngine.eligibleStageIndex(xp: 2_000, stages: cat.stages) == 5)
    }

    @Test func hatchOnlyUsesOwnedAnimals() throws {
        var generator = SeededGenerator(seed: 7)
        let catalog = try ManifestLoader.bundledCatalog()
        let result = try HatchEngine.hatch(
            ownedAnimalIDs: ["fox"], catalog: catalog,
            economy: try ManifestLoader.bundledEconomy(), hasShinyCharm: false,
            using: &generator
        )
        #expect(result.animal.id == "fox")
        #expect(catalog.natures.contains(result.nature))
    }

    @Test func evolutionEventIsEmittedOnlyWhenUsageCrossesNextThreshold() throws {
        let cat = try #require(try ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" })
        let id = UUID()
        let before = AnimalInstance(
            id: id,
            definitionID: "cat",
            name: "Mochi",
            currentXP: 49,
            isCurrent: true,
            natureID: "curious",
            rarity: .common
        )
        var after = before
        after.currentXP = 50

        let events = CompanionEventEngine.events(previous: before, current: after, definition: cat)
        let event = try #require(events.first)
        #expect(events.count == 1)
        #expect(event.kind == .evolutionReady)
        #expect(event.targetStageIndex == 2)
        #expect(event.targetStageName == "House Cat")
        #expect(event.companionName == "Mochi")
    }

    @Test func evolutionEventDoesNotRepeatForRescanOrAnimalSwitch() throws {
        let cat = try #require(try ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" })
        let ready = AnimalInstance(
            definitionID: "cat",
            name: "Mochi",
            currentXP: 50,
            isCurrent: true,
            natureID: "curious",
            rarity: .common
        )
        #expect(CompanionEventEngine.events(previous: ready, current: ready, definition: cat).isEmpty)

        let replacement = AnimalInstance(
            definitionID: "cat",
            name: "Nova",
            currentXP: 50,
            isCurrent: true,
            natureID: "bold",
            rarity: .common
        )
        #expect(CompanionEventEngine.events(previous: ready, current: replacement, definition: cat).isEmpty)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
