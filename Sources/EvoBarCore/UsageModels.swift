import Foundation

public struct TokenUsage: Codable, Equatable, Sendable {
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let cacheReadTokens: Int64
    public let cacheWriteTokens: Int64
    public let reasoningTokens: Int64
    public let totalTokens: Int64

    public init(
        inputTokens: Int64,
        outputTokens: Int64,
        cacheReadTokens: Int64 = 0,
        cacheWriteTokens: Int64 = 0,
        reasoningTokens: Int64 = 0,
        totalTokens: Int64
    ) {
        self.inputTokens = max(0, inputTokens)
        self.outputTokens = max(0, outputTokens)
        self.cacheReadTokens = max(0, cacheReadTokens)
        self.cacheWriteTokens = max(0, cacheWriteTokens)
        self.reasoningTokens = max(0, reasoningTokens)
        self.totalTokens = max(0, totalTokens)
    }
}

public struct UsageEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UsageEventID { stableID }

    public let stableID: UsageEventID
    public let provider: ProviderID
    public let sessionID: String
    public let timestamp: Date
    public let modelID: String?
    public let usage: TokenUsage
    public let sourceFingerprint: String

    public init(
        stableID: UsageEventID,
        provider: ProviderID,
        sessionID: String,
        timestamp: Date,
        modelID: String?,
        usage: TokenUsage,
        sourceFingerprint: String
    ) {
        self.stableID = stableID
        self.provider = provider
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.modelID = modelID
        self.usage = usage
        self.sourceFingerprint = sourceFingerprint
    }
}

public struct UsageSummary: Codable, Equatable, Sendable {
    public let interval: DateInterval
    public let usage: TokenUsage
    public let estimatedCost: Decimal?

    public init(interval: DateInterval, usage: TokenUsage, estimatedCost: Decimal? = nil) {
        self.interval = interval
        self.usage = usage
        self.estimatedCost = estimatedCost
    }
}

public struct ModelUsage: Codable, Equatable, Sendable {
    public let providerID: ProviderID
    public let modelID: String
    public let usage: TokenUsage
    public let estimatedCost: Decimal?
}

public enum QuotaFreshness: String, Codable, Sendable {
    case fresh
    case stale
    case unavailable
}

public struct QuotaWindow: Codable, Equatable, Sendable {
    public let providerID: ProviderID
    public let name: String
    public let utilization: Double
    public let resetsAt: Date?
    public let projectedExhaustionAt: Date?
    public let freshness: QuotaFreshness

    public init(
        providerID: ProviderID,
        name: String,
        utilization: Double,
        resetsAt: Date?,
        projectedExhaustionAt: Date?,
        freshness: QuotaFreshness
    ) {
        self.providerID = providerID
        self.name = name
        self.utilization = min(1, max(0, utilization))
        self.resetsAt = resetsAt
        self.projectedExhaustionAt = projectedExhaustionAt
        self.freshness = freshness
    }
}

public struct QuotaWindowSample: Codable, Equatable, Sendable {
    public let providerID: ProviderID
    public let windowID: String
    public let name: String
    public let utilization: Double
    public let resetsAt: Date?
    public let capturedAt: Date

    public init(
        providerID: ProviderID,
        windowID: String,
        name: String,
        utilization: Double,
        resetsAt: Date?,
        capturedAt: Date
    ) {
        self.providerID = providerID
        self.windowID = windowID
        self.name = name
        self.utilization = min(1, max(0, utilization))
        self.resetsAt = resetsAt
        self.capturedAt = capturedAt
    }
}

public struct ProviderQuotaSnapshot: Codable, Equatable, Sendable {
    public let providerID: ProviderID
    public let windows: [QuotaWindowSample]
    public let capturedAt: Date
    public let freshness: QuotaFreshness

    public init(
        providerID: ProviderID,
        windows: [QuotaWindowSample],
        capturedAt: Date,
        freshness: QuotaFreshness
    ) {
        self.providerID = providerID
        self.windows = windows
        self.capturedAt = capturedAt
        self.freshness = freshness
    }
}

public enum UsageWindowKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case today
    case rollingFiveHours
    case week
    case month

    public var id: String { rawValue }

    public var fallbackTitle: String {
        switch self {
        case .today: "Today"
        case .rollingFiveHours: "5 Hours"
        case .week: "Week"
        case .month: "Month"
        }
    }
}

public struct ProviderUsageBreakdown: Equatable, Identifiable, Sendable {
    public var id: ProviderID { providerID }
    public let providerID: ProviderID
    public let usage: TokenUsage
    public let sessionCount: Int
    public let estimatedAPICostUSD: Decimal?
    public let costCoverage: Double

    public init(
        providerID: ProviderID,
        usage: TokenUsage,
        sessionCount: Int,
        estimatedAPICostUSD: Decimal? = nil,
        costCoverage: Double = 0
    ) {
        self.providerID = providerID
        self.usage = usage
        self.sessionCount = sessionCount
        self.estimatedAPICostUSD = estimatedAPICostUSD
        self.costCoverage = costCoverage
    }
}

public struct ModelUsageBreakdown: Equatable, Identifiable, Sendable {
    public var id: String { "\(providerID.rawValue)|\(modelID)" }
    public let providerID: ProviderID
    public let modelID: String
    public let usage: TokenUsage
    public let estimatedAPICostUSD: Decimal?
    public let costCoverage: Double

    public init(
        providerID: ProviderID,
        modelID: String,
        usage: TokenUsage,
        estimatedAPICostUSD: Decimal? = nil,
        costCoverage: Double = 0
    ) {
        self.providerID = providerID
        self.modelID = modelID
        self.usage = usage
        self.estimatedAPICostUSD = estimatedAPICostUSD
        self.costCoverage = costCoverage
    }
}

public struct UsageWindowSnapshot: Equatable, Identifiable, Sendable {
    public var id: UsageWindowKind { kind }
    public let kind: UsageWindowKind
    public let interval: DateInterval
    public let usage: TokenUsage
    public let sessionCount: Int
    public let providers: [ProviderUsageBreakdown]
    public let models: [ModelUsageBreakdown]
    public let estimatedAPICostUSD: Decimal?
    public let costCoverage: Double

    public init(
        kind: UsageWindowKind,
        interval: DateInterval,
        usage: TokenUsage,
        sessionCount: Int,
        providers: [ProviderUsageBreakdown],
        models: [ModelUsageBreakdown],
        estimatedAPICostUSD: Decimal? = nil,
        costCoverage: Double = 0
    ) {
        self.kind = kind
        self.interval = interval
        self.usage = usage
        self.sessionCount = sessionCount
        self.providers = providers
        self.models = models
        self.estimatedAPICostUSD = estimatedAPICostUSD
        self.costCoverage = costCoverage
    }
}

public struct UsageDashboardSnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let windows: [UsageWindowSnapshot]

    public init(generatedAt: Date, windows: [UsageWindowSnapshot]) {
        self.generatedAt = generatedAt
        self.windows = windows
    }

    public func window(_ kind: UsageWindowKind) -> UsageWindowSnapshot? {
        windows.first { $0.kind == kind }
    }
}
