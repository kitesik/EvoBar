import EvoBarCore
import Foundation

public enum UsageCostEngine {
    public static func price(
        for providerID: ProviderID,
        modelID: String?,
        in manifest: ModelPricingManifest
    ) -> ModelPriceDefinition? {
        guard let modelID else { return nil }
        let normalized = modelID.lowercased()
        return manifest.models.first { price in
            price.providerID == providerID && price.matchPatterns.contains { pattern in
                wildcardMatch(normalized, pattern: pattern.lowercased())
            }
        }
    }

    public static func estimate(
        usage: TokenUsage,
        providerID: ProviderID,
        modelID: String?,
        manifest: ModelPricingManifest
    ) -> UsageCostEstimate {
        guard let price = price(for: providerID, modelID: modelID, in: manifest) else {
            return UsageCostEstimate(
                amountUSD: 0,
                pricedTokens: 0,
                unpricedTokens: usage.totalTokens
            )
        }

        let uncachedInput = price.inputIncludesCachedTokens
            ? max(0, usage.inputTokens - usage.cacheReadTokens)
            : usage.inputTokens
        var amount = perMillion(uncachedInput, rate: price.inputUSDPerMillion)
            + perMillion(usage.cacheReadTokens, rate: price.cachedInputUSDPerMillion)
            + perMillion(usage.outputTokens, rate: price.outputUSDPerMillion)
        var unpricedTokens: Int64 = 0
        if let cacheWriteRate = price.cacheWriteUSDPerMillion {
            amount += perMillion(usage.cacheWriteTokens, rate: cacheWriteRate)
        } else {
            unpricedTokens = usage.cacheWriteTokens
        }
        return UsageCostEstimate(
            amountUSD: amount,
            pricedTokens: max(0, usage.totalTokens - unpricedTokens),
            unpricedTokens: unpricedTokens
        )
    }

    private static func perMillion(_ tokens: Int64, rate: Decimal) -> Decimal {
        Decimal(max(0, tokens)) * rate / Decimal(1_000_000)
    }

    private static func wildcardMatch(_ value: String, pattern: String) -> Bool {
        let parts = pattern.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
        if parts.count == 1 { return value == pattern }

        var searchStart = value.startIndex
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index == 0, !pattern.hasPrefix("*") {
                guard value[searchStart...].hasPrefix(part) else { return false }
                searchStart = value.index(searchStart, offsetBy: part.count)
                continue
            }
            guard let range = value.range(of: part, range: searchStart..<value.endIndex) else {
                return false
            }
            searchStart = range.upperBound
        }
        if !pattern.hasSuffix("*"), let last = parts.last, !last.isEmpty {
            return value.hasSuffix(last)
        }
        return true
    }
}
