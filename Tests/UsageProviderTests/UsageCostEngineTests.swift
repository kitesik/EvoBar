import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct UsageCostEngineTests {
    @Test func openAISeparatesCachedInputAndMarksUnknownCacheWriteUnpriced() throws {
        let pricing = try ManifestLoader.bundledPricing()
        let estimate = UsageCostEngine.estimate(
            usage: TokenUsage(
                inputTokens: 1_000,
                outputTokens: 200,
                cacheReadTokens: 600,
                cacheWriteTokens: 20,
                totalTokens: 1_220
            ),
            providerID: .codex,
            modelID: "gpt-5.6-terra",
            manifest: pricing
        )

        #expect(estimate.amountUSD == Decimal(string: "0.00332"))
        #expect(estimate.pricedTokens == 1_200)
        #expect(estimate.unpricedTokens == 20)
        #expect(estimate.coverage > 0.98 && estimate.coverage < 1)
    }

    @Test func claudeIncludesFiveMinuteCacheWriteRate() throws {
        let pricing = try ManifestLoader.bundledPricing()
        let estimate = UsageCostEngine.estimate(
            usage: TokenUsage(
                inputTokens: 1_000,
                outputTokens: 200,
                cacheReadTokens: 600,
                cacheWriteTokens: 40,
                totalTokens: 1_840
            ),
            providerID: .claudeCode,
            modelID: "claude-sonnet-4-5-20250929",
            manifest: pricing
        )

        #expect(estimate.amountUSD == Decimal(string: "0.00633"))
        #expect(estimate.coverage == 1)
    }

    @Test func unknownModelsRemainExplicitlyUnpriced() throws {
        let pricing = try ManifestLoader.bundledPricing()
        let estimate = UsageCostEngine.estimate(
            usage: TokenUsage(inputTokens: 500, outputTokens: 100, totalTokens: 600),
            providerID: .codex,
            modelID: "future-unlisted-model",
            manifest: pricing
        )

        #expect(estimate.amountUSD == 0)
        #expect(estimate.pricedTokens == 0)
        #expect(estimate.unpricedTokens == 600)
        #expect(UsageCostEngine.price(
            for: .codex,
            modelID: "codex-auto-review",
            in: pricing
        )?.canonicalModelID == "gpt-5.4")
    }
}
