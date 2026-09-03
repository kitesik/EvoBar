import EvoBarCore
import Foundation

public enum QuotaServiceError: Error, Equatable {
    case credentialsUnavailable
    case unsupported
    case invalidResponse
    case transport(code: String)
}

public protocol QuotaService: Sendable {
    var providerID: ProviderID { get }
    func fetchQuota() async throws -> ProviderQuotaSnapshot
}

public struct UnavailableQuotaService: QuotaService {
    public let providerID: ProviderID

    public init(providerID: ProviderID) {
        self.providerID = providerID
    }

    public func fetchQuota() async throws -> ProviderQuotaSnapshot {
        throw QuotaServiceError.unsupported
    }
}

public struct ProviderQuotaStatus: Equatable, Identifiable, Sendable {
    public var id: ProviderID { providerID }
    public let providerID: ProviderID
    public let windows: [QuotaWindow]
    public let freshness: QuotaFreshness
    public let message: String?

    public init(
        providerID: ProviderID,
        windows: [QuotaWindow],
        freshness: QuotaFreshness,
        message: String? = nil
    ) {
        self.providerID = providerID
        self.windows = windows
        self.freshness = freshness
        self.message = message
    }
}

public struct QuotaDashboardSnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let providers: [ProviderQuotaStatus]

    public init(generatedAt: Date, providers: [ProviderQuotaStatus]) {
        self.generatedAt = generatedAt
        self.providers = providers
    }
}

public actor QuotaMonitor {
    private let services: [any QuotaService]
    private var latestSamples: [String: QuotaWindowSample] = [:]

    public init(services: [any QuotaService]) {
        self.services = services
    }

    public func refresh(now: Date = Date()) async -> QuotaDashboardSnapshot {
        var statuses: [ProviderQuotaStatus] = []
        for service in services {
            do {
                let snapshot = try await service.fetchQuota()
                let windows = snapshot.windows.map { sample in
                    let key = Self.sampleKey(providerID: sample.providerID, windowID: sample.windowID)
                    let window = QuotaForecastEngine.window(
                        current: sample,
                        previous: latestSamples[key],
                        freshness: snapshot.freshness
                    )
                    latestSamples[key] = sample
                    return window
                }
                statuses.append(ProviderQuotaStatus(
                    providerID: snapshot.providerID,
                    windows: windows,
                    freshness: snapshot.freshness
                ))
            } catch {
                let cached = latestSamples.values
                    .filter { $0.providerID == service.providerID }
                    .sorted { $0.name < $1.name }
                    .map {
                        QuotaForecastEngine.window(current: $0, previous: nil, freshness: .stale)
                    }
                statuses.append(ProviderQuotaStatus(
                    providerID: service.providerID,
                    windows: cached,
                    freshness: cached.isEmpty ? .unavailable : .stale,
                    message: Self.message(for: error)
                ))
            }
        }
        return QuotaDashboardSnapshot(
            generatedAt: now,
            providers: statuses.sorted { $0.providerID.rawValue < $1.providerID.rawValue }
        )
    }

    private static func sampleKey(providerID: ProviderID, windowID: String) -> String {
        "\(providerID.rawValue)|\(windowID)"
    }

    private static func message(for error: Error) -> String {
        guard let quotaError = error as? QuotaServiceError else {
            return "Quota refresh failed."
        }
        return switch quotaError {
        case .credentialsUnavailable: "Credentials are not connected."
        case .unsupported: "No supported personal quota API is available."
        case .invalidResponse: "The provider returned an unsupported response."
        case .transport(let code): "Quota refresh failed (\(code))."
        }
    }
}

/// A deterministic storefront-style quota source for DEBUG builds and tests.
public actor MockQuotaService: QuotaService {
    public nonisolated let providerID: ProviderID
    private let definitions: [(id: String, name: String, resetInterval: TimeInterval)]
    private var utilization: [String: Double]
    private let step: Double
    private let epochStartedAt: Date

    public init(
        providerID: ProviderID,
        fiveHourUtilization: Double = 0.36,
        weeklyUtilization: Double = 0.58,
        step: Double = 0.015,
        startedAt: Date = Date()
    ) {
        self.providerID = providerID
        self.definitions = [
            ("five-hour", "5-hour", TimeInterval(5 * 60 * 60)),
            ("weekly", "Weekly", TimeInterval(7 * 24 * 60 * 60)),
        ]
        self.utilization = [
            "five-hour": min(1, max(0, fiveHourUtilization)),
            "weekly": min(1, max(0, weeklyUtilization)),
        ]
        self.step = max(0, step)
        self.epochStartedAt = startedAt
    }

    public func fetchQuota() -> ProviderQuotaSnapshot {
        let now = Date()
        let windows = definitions.map { definition in
            let value = utilization[definition.id] ?? 0
            utilization[definition.id] = min(1, value + step)
            return QuotaWindowSample(
                providerID: providerID,
                windowID: definition.id,
                name: definition.name,
                utilization: value,
                resetsAt: epochStartedAt.addingTimeInterval(definition.resetInterval),
                capturedAt: now
            )
        }
        return ProviderQuotaSnapshot(
            providerID: providerID,
            windows: windows,
            capturedAt: now,
            freshness: .fresh
        )
    }
}

public enum QuotaAlertLevel: String, Sendable {
    case warning
    case critical
}

public struct QuotaAlert: Equatable, Sendable {
    public let id: String
    public let providerID: ProviderID
    public let windowName: String
    public let level: QuotaAlertLevel
    public let utilization: Double

    public init(
        id: String,
        providerID: ProviderID,
        windowName: String,
        level: QuotaAlertLevel,
        utilization: Double
    ) {
        self.id = id
        self.providerID = providerID
        self.windowName = windowName
        self.level = level
        self.utilization = utilization
    }
}

public struct QuotaAlertEvaluator: Sendable {
    private var deliveredIDs: Set<String> = []

    public init() {}

    public mutating func newAlerts(for dashboard: QuotaDashboardSnapshot) -> [QuotaAlert] {
        dashboard.providers.flatMap { provider in
            provider.windows.compactMap { window in
                guard provider.freshness == .fresh else { return nil }
                let level: QuotaAlertLevel
                if window.utilization >= 0.95 {
                    level = .critical
                } else if window.utilization >= 0.80 {
                    level = .warning
                } else {
                    return nil
                }
                let resetEpoch = window.resetsAt.map { String(Int($0.timeIntervalSince1970)) } ?? "unknown"
                let id = "quota|\(window.providerID.rawValue)|\(window.name)|\(resetEpoch)|\(level.rawValue)"
                guard deliveredIDs.insert(id).inserted else { return nil }
                return QuotaAlert(
                    id: id,
                    providerID: window.providerID,
                    windowName: window.name,
                    level: level,
                    utilization: window.utilization
                )
            }
        }
    }
}

public enum QuotaForecastEngine {
    public static func window(
        current: QuotaWindowSample,
        previous: QuotaWindowSample?,
        freshness: QuotaFreshness
    ) -> QuotaWindow {
        QuotaWindow(
            providerID: current.providerID,
            name: current.name,
            utilization: current.utilization,
            resetsAt: current.resetsAt,
            projectedExhaustionAt: projectedExhaustion(current: current, previous: previous),
            freshness: freshness
        )
    }

    public static func projectedExhaustion(
        current: QuotaWindowSample,
        previous: QuotaWindowSample?
    ) -> Date? {
        guard let previous,
              previous.providerID == current.providerID,
              previous.windowID == current.windowID,
              previous.resetsAt == current.resetsAt,
              current.capturedAt > previous.capturedAt,
              current.utilization > previous.utilization,
              current.utilization < 1 else { return nil }

        let elapsed = current.capturedAt.timeIntervalSince(previous.capturedAt)
        let utilizationPerSecond = (current.utilization - previous.utilization) / elapsed
        guard utilizationPerSecond > 0 else { return nil }
        let projected = current.capturedAt.addingTimeInterval(
            (1 - current.utilization) / utilizationPerSecond
        )
        if let resetsAt = current.resetsAt, projected >= resetsAt { return nil }
        return projected
    }

    public static func resetCountdown(
        for window: QuotaWindow,
        now: Date = Date()
    ) -> TimeInterval? {
        window.resetsAt.map { max(0, $0.timeIntervalSince(now)) }
    }
}
