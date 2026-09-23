import EvoBarCore
import Foundation

public struct GrowthAward: Equatable, Sendable {
    public let rawTokens: Int64
    public let effectiveTokens: Int64
    public let xpDelta: Int64
    public let tokenCoinDelta: Int64
}

public struct DailyGrowthLedger: Codable, Equatable, Sendable {
    public private(set) var rawTokens: Int64
    public private(set) var effectiveTokens: Int64
    public private(set) var awardedXP: Int64
    public private(set) var awardedTokenCoins: Int64

    public init(
        rawTokens: Int64 = 0,
        effectiveTokens: Int64 = 0,
        awardedXP: Int64 = 0,
        awardedTokenCoins: Int64 = 0
    ) {
        self.rawTokens = max(0, rawTokens)
        self.effectiveTokens = max(0, effectiveTokens)
        self.awardedXP = max(0, awardedXP)
        self.awardedTokenCoins = max(0, awardedTokenCoins)
    }

    public mutating func recompute(
        rawTokens newRawTokens: Int64,
        cacheReadTokens: Int64? = nil,
        effectiveTokensPerCoin: Int64
    ) -> GrowthAward {
        rawTokens = max(rawTokens, max(0, newRawTokens))
        let growthTokens = cacheReadTokens.map {
            EffectiveTokenCalculator.growthTokens(rawTokens: rawTokens, cacheReadTokens: $0)
        } ?? rawTokens
        effectiveTokens = EffectiveTokenCalculator.effectiveTokens(for: growthTokens)
        let targetXP = effectiveTokens / 10_000
        let targetCoins = effectiveTokensPerCoin > 0 ? effectiveTokens / effectiveTokensPerCoin : 0
        let xpDelta = max(0, targetXP - awardedXP)
        let coinDelta = max(0, targetCoins - awardedTokenCoins)
        awardedXP += xpDelta
        awardedTokenCoins += coinDelta
        return GrowthAward(
            rawTokens: rawTokens,
            effectiveTokens: effectiveTokens,
            xpDelta: xpDelta,
            tokenCoinDelta: coinDelta
        )
    }
}

public enum EvolutionEngine {
    public static func eligibleStageIndex(
        xp: Int64,
        stages: [EvolutionStageDefinition]
    ) -> Int {
        stages
            .filter { $0.xpThreshold <= max(0, xp) }
            .map(\.index)
            .max() ?? 1
    }

    public static func nextStage(
        after acknowledgedStageIndex: Int,
        stages: [EvolutionStageDefinition]
    ) -> EvolutionStageDefinition? {
        stages.first { $0.index == acknowledgedStageIndex + 1 }
    }

    public static func progress(
        xp: Int64,
        acknowledgedStageIndex: Int,
        stages: [EvolutionStageDefinition]
    ) -> Double {
        guard let current = stages.first(where: { $0.index == acknowledgedStageIndex }),
              let next = nextStage(after: acknowledgedStageIndex, stages: stages) else {
            return 1
        }
        let span = max(1, next.xpThreshold - current.xpThreshold)
        let earned = min(span, max(0, xp - current.xpThreshold))
        return Double(earned) / Double(span)
    }
}
