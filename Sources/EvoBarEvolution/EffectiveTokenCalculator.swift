import EvoBarCore
import Foundation

public enum EffectiveTokenCalculator {
    /// Cached context is useful work, but rereading it should not overwhelm
    /// the growth earned from new input and output. Raw usage totals are unchanged.
    public static let cacheReadGrowthDivisor: Int64 = 10

    public static func growthTokens(rawTokens: Int64, cacheReadTokens: Int64) -> Int64 {
        let raw = max(0, rawTokens)
        let cacheRead = min(raw, max(0, cacheReadTokens))
        return raw - cacheRead + cacheRead / cacheReadGrowthDivisor
    }

    public static func effectiveTokens(for rawTokens: Int64) -> Int64 {
        let total = max(0, rawTokens)
        let first = min(total, 1_000_000)
        let second = min(max(total - 1_000_000, 0), 4_000_000)
        let third = min(max(total - 5_000_000, 0), 15_000_000)
        let fourth = max(total - 20_000_000, 0)

        return saturatingSum([
            scaled(first, basisPoints: 10_000),
            scaled(second, basisPoints: 5_000),
            scaled(third, basisPoints: 2_000),
            scaled(fourth, basisPoints: 500),
        ])
    }

    public static func targetXP(forRawTokens rawTokens: Int64) -> Int64 {
        effectiveTokens(for: rawTokens) / 10_000
    }

    public static func targetTokenCoins(
        forRawTokens rawTokens: Int64,
        effectiveTokensPerCoin: Int64
    ) -> Int64 {
        guard effectiveTokensPerCoin > 0 else { return 0 }
        return effectiveTokens(for: rawTokens) / effectiveTokensPerCoin
    }

    private static func scaled(_ value: Int64, basisPoints: Int64) -> Int64 {
        let quotient = value / 10_000
        let remainder = value % 10_000
        let (whole, wholeOverflow) = quotient.multipliedReportingOverflow(by: basisPoints)
        let (partialProduct, partialOverflow) = remainder.multipliedReportingOverflow(by: basisPoints)
        guard !wholeOverflow, !partialOverflow else { return Int64.max }
        return saturatingSum([whole, partialProduct / 10_000])
    }

    private static func saturatingSum(_ values: [Int64]) -> Int64 {
        values.reduce(0) { result, value in
            let (sum, overflow) = result.addingReportingOverflow(value)
            return overflow ? Int64.max : sum
        }
    }
}
