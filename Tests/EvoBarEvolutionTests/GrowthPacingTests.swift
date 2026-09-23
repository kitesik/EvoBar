import EvoBarCore
import EvoBarEvolution
import Testing

/// Controlled active days, not a forecast: one absorption/day, no purchases,
/// no missed days, unchanged production bonus and daily-gift rules.
@Suite struct GrowthPacingTests {
    @Test(arguments: [50_000, 250_000, 500_000, 1_000_000, 5_000_000, 20_000_000] as [Int64])
    func fullLineComparison(tokens: Int64) throws {
        let economy = try ManifestLoader.bundledEconomy()
        let candy = try #require(economy.items.first { $0.kind == .rareCandy }?.xpGrant)
        let xp = EffectiveTokenCalculator.targetXP(forRawTokens: tokens)
        let catalog = try ManifestLoader.bundledCatalog()
        for count in [7, 8] {
            let old: [Int64] = count == 7
                ? [0, 15, 150, 900, 2_000, 4_000, 7_000]
                : [0, 15, 150, 900, 2_000, 3_600, 6_000, 9_500]
            let revised = try #require(catalog.animals.first { $0.stages.count == count })
                .stages.map(\.xpThreshold)
            let oldBase = old.map { ($0 + xp - 1) / xp }
            let newBase = revised.map { ($0 + xp - 1) / xp }
            let oldGaps = zip(oldBase.dropFirst(), oldBase).map(-)
            let newGaps = zip(newBase.dropFirst(), newBase).map(-)
            #expect(newGaps.max()! < oldGaps.max()!)
            #expect(newBase.prefix(3) == oldBase.prefix(3))
            var previousFinals: [Int] = []
            var revisedFinals: [Int] = []
            for seed in 1...32 {
                var random = PacingRandom(state: UInt64(seed))
                var total: Int64 = 0
                var day = 0
                var newFinal: Int?
                while total < old.last! && day < 3_000 {
                    day += 1
                    let gift = DailyGiftEngine.gift(
                        coinRoll: random.unit(), itemRoll: random.unit(), candyXP: candy)
                    total += GrowthBonusEngine.absorption(of: xp, roll: random.unit()).with(gift: gift).total
                    if newFinal == nil && total >= revised.last! { newFinal = day }
                }
                #expect(total >= old.last!)
                let reached = try #require(newFinal)
                #expect(reached <= day)
                previousFinals.append(day)
                revisedFinals.append(reached)
            }
            previousFinals.sort()
            revisedFinals.sort()
            print("Pacing tokens=\(tokens) stages=\(count) baseFinal=\(oldBase.last!)->\(newBase.last!) maxBaseGap=\(oldGaps.max()!)->\(newGaps.max()!) seededMedian=\(previousFinals[15])->\(revisedFinals[15]) revisedSeedRange=\(revisedFinals.first!)...\(revisedFinals.last!)")
        }
    }
}

private struct PacingRandom {
    var state: UInt64
    mutating func unit() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return Double(state >> 11) / 9_007_199_254_740_992
    }
}
