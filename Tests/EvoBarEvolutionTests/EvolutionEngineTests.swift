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

    /// A roll can add to what arrived, never take from it; a bonus that would
    /// round to nothing is not announced.
    @Test func growthBonusTiersFollowTheRoll() {
        #expect(GrowthBonusEngine.absorption(of: 100, roll: 0.01)
            == GrowthAbsorption(base: 100, bonus: 100, coins: 3, tier: .golden))
        #expect(GrowthBonusEngine.absorption(of: 100, roll: 0.10)
            == GrowthAbsorption(base: 100, bonus: 50, coins: 0, tier: .lucky))
        #expect(GrowthBonusEngine.absorption(of: 100, roll: 0.18)
            == GrowthAbsorption(base: 100, bonus: 0, coins: 0, tier: nil))
        #expect(GrowthBonusEngine.absorption(of: 1, roll: 0.0)
            == GrowthAbsorption(base: 1, bonus: 0, coins: 0, tier: nil))
        #expect(GrowthBonusEngine.absorption(of: 7, roll: 0.99).total == 7)
    }

    /// Coins always, a candy's worth of XP often, an egg now and then. Nothing
    /// the gift can roll takes anything away.
    @Test func theDailyGiftAlwaysGivesCoinsAndSometimesMore() {
        #expect(DailyGiftEngine.gift(coinRoll: 0, itemRoll: 0.5, candyXP: 60)
            == DailyGift(coins: 2, xp: 0, eggs: 0))
        #expect(DailyGiftEngine.gift(coinRoll: 0.999, itemRoll: 0.5, candyXP: 60)
            == DailyGift(coins: 5, xp: 0, eggs: 0))
        #expect(DailyGiftEngine.gift(coinRoll: 0.5, itemRoll: 0.01, candyXP: 60)
            == DailyGift(coins: 4, xp: 0, eggs: 1))
        #expect(DailyGiftEngine.gift(coinRoll: 0.5, itemRoll: 0.10, candyXP: 60)
            == DailyGift(coins: 4, xp: 60, eggs: 0))
        // The gift rides in the same sweep, so its XP counts toward the total.
        let arrival = GrowthAbsorption(base: 100, bonus: 50, coins: 0, tier: .lucky)
            .with(gift: DailyGift(coins: 3, xp: 60, eggs: 0))
        #expect(arrival.total == 210)
    }

    @Test func candyGrantSpansItsListedValue() {
        #expect(GrowthBonusEngine.candyGrant(mean: 60, roll: 0) == 40)
        #expect(GrowthBonusEngine.candyGrant(mean: 60, roll: 0.5) == 60)
        #expect(GrowthBonusEngine.candyGrant(mean: 60, roll: 1) == 79)
        #expect(GrowthBonusEngine.candyGrant(mean: 0, roll: 0.5) == 0)
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

    @Test func evolutionEventDoesNotRepeatForRescanAndSwitchReportsAHatchInstead() throws {
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
        // Switching individuals must not re-announce readiness; it is a hatch.
        let switched = CompanionEventEngine.events(previous: ready, current: replacement, definition: cat)
        #expect(switched.map(\.kind) == [.hatched])
        #expect(switched.first?.companionName == "Nova")
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
