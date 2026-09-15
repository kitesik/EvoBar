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

/// The numbers people feel about a window of usage, read off its events.
public struct UsageStory: Equatable, Sendable {
    /// Seconds the user and the tools were at work, parallel sessions counted once.
    public let activeSeconds: TimeInterval
    /// Hour of the day (0 through 23, growth time zone) that saw the most
    /// tokens; nil when the window has no events.
    public let peakHour: Int?
    /// The longest unbroken stretch of one session, in seconds.
    public let longestSessionSeconds: TimeInterval

    public init(activeSeconds: TimeInterval, peakHour: Int?, longestSessionSeconds: TimeInterval) {
        self.activeSeconds = activeSeconds
        self.peakHour = peakHour
        self.longestSessionSeconds = longestSessionSeconds
    }

    public static let empty = UsageStory(activeSeconds: 0, peakHour: nil, longestSessionSeconds: 0)
}

/// One recorded growth day and its raw token total.
public struct UsageRecordDay: Equatable, Sendable {
    public let date: Date
    public let tokens: Int64

    public init(date: Date, tokens: Int64) {
        self.date = date
        self.tokens = tokens
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
    public let story: UsageStory

    public init(
        kind: UsageWindowKind,
        interval: DateInterval,
        usage: TokenUsage,
        sessionCount: Int,
        providers: [ProviderUsageBreakdown],
        models: [ModelUsageBreakdown],
        estimatedAPICostUSD: Decimal? = nil,
        costCoverage: Double = 0,
        story: UsageStory = .empty
    ) {
        self.kind = kind
        self.interval = interval
        self.usage = usage
        self.sessionCount = sessionCount
        self.providers = providers
        self.models = models
        self.estimatedAPICostUSD = estimatedAPICostUSD
        self.costCoverage = costCoverage
        self.story = story
    }
}

public enum DayRank {
    /// Where today sits among recorded days, 1 being the busiest. `history` holds
    /// the other days' raw token totals; nil when there is nothing to compare.
    public static func rank(today: Int64, history: [Int64]) -> (rank: Int, total: Int)? {
        guard !history.isEmpty else { return nil }
        let busier = history.filter { $0 > today }.count
        return (busier + 1, history.count + 1)
    }
}

public enum UsageIngestionPolicy {
    /// Events at or after this instant count toward growth. Tracking starts at
    /// install time, but the first scan also backfills the current growth day so a
    /// fresh install does not open on zero.
    public static func eventCutoff(trackingStartedAt: Date, now: Date = Date(), timeZoneID: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        return min(trackingStartedAt, calendar.startOfDay(for: now))
    }
}

/// Absolute label for a day's raw token total, judged against fixed thresholds
/// rather than other people's usage.
public enum UsageBand: String, CaseIterable, Sendable {
    case light
    case steady
    case heavy
    case extreme

    public static func band(for tokens: Int64, thresholds: [Int64]) -> UsageBand {
        let bounds = AppSettings.validatedUsageBandThresholds(thresholds)
        if tokens < bounds[0] { return .light }
        if tokens < bounds[1] { return .steady }
        if tokens < bounds[2] { return .heavy }
        return .extreme
    }

}

public struct UsageDashboardSnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let windows: [UsageWindowSnapshot]
    /// Growth days in a row with usage, counted back from today, or from
    /// yesterday while today is still empty.
    public let streakDays: Int
    /// The busiest recorded day, today included.
    public let bestDay: UsageRecordDay?
    public let yesterdayTokens: Int64

    public init(
        generatedAt: Date,
        windows: [UsageWindowSnapshot],
        streakDays: Int = 0,
        bestDay: UsageRecordDay? = nil,
        yesterdayTokens: Int64 = 0
    ) {
        self.generatedAt = generatedAt
        self.windows = windows
        self.streakDays = streakDays
        self.bestDay = bestDay
        self.yesterdayTokens = yesterdayTokens
    }

    public func window(_ kind: UsageWindowKind) -> UsageWindowSnapshot? {
        windows.first { $0.kind == kind }
    }
}
