import Foundation

public struct PricingSourceDefinition: Codable, Equatable, Sendable {
    public let providerID: ProviderID
    public let title: String
    public let url: URL
    public let retrievedAt: String
}

public struct ModelPriceDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(providerID.rawValue)|\(canonicalModelID)" }
    public let providerID: ProviderID
    public let canonicalModelID: String
    public let matchPatterns: [String]
    public let inputUSDPerMillion: Decimal
    public let cachedInputUSDPerMillion: Decimal
    public let cacheWriteUSDPerMillion: Decimal?
    public let outputUSDPerMillion: Decimal
    public let inputIncludesCachedTokens: Bool
}

public struct ModelPricingManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let currencyCode: String
    public let effectiveAt: String
    public let sources: [PricingSourceDefinition]
    public let models: [ModelPriceDefinition]
}

public struct UsageCostEstimate: Equatable, Sendable {
    public let amountUSD: Decimal
    public let pricedTokens: Int64
    public let unpricedTokens: Int64

    public var coverage: Double {
        let total = pricedTokens + unpricedTokens
        return total > 0 ? Double(pricedTokens) / Double(total) : 1
    }

    public init(amountUSD: Decimal, pricedTokens: Int64, unpricedTokens: Int64) {
        self.amountUSD = amountUSD
        self.pricedTokens = max(0, pricedTokens)
        self.unpricedTokens = max(0, unpricedTokens)
    }
}
