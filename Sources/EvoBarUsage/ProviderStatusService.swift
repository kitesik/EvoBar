import EvoBarCore
import Foundation

public enum ProviderServiceCondition: String, Equatable, Sendable {
    case operational
    case degraded
    case outage
    case unknown
}

public enum ProviderStatusFreshness: String, Equatable, Sendable {
    case fresh
    case stale
    case unavailable
}

public struct ProviderOperationalStatus: Equatable, Identifiable, Sendable {
    public var id: ProviderID { providerID }
    public let providerID: ProviderID
    public let condition: ProviderServiceCondition
    public let summary: String
    public let statusPageURL: URL
    public let checkedAt: Date
    public let freshness: ProviderStatusFreshness

    public init(
        providerID: ProviderID,
        condition: ProviderServiceCondition,
        summary: String,
        statusPageURL: URL,
        checkedAt: Date,
        freshness: ProviderStatusFreshness
    ) {
        self.providerID = providerID
        self.condition = condition
        self.summary = summary
        self.statusPageURL = statusPageURL
        self.checkedAt = checkedAt
        self.freshness = freshness
    }
}

public struct ProviderStatusDashboardSnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let providers: [ProviderOperationalStatus]

    public init(generatedAt: Date, providers: [ProviderOperationalStatus]) {
        self.generatedAt = generatedAt
        self.providers = providers
    }
}

public enum ProviderStatusServiceError: Error, Equatable {
    case invalidHTTPStatus(Int)
    case invalidResponse
    case transport
}

public protocol ProviderStatusService: Sendable {
    var providerID: ProviderID { get }
    var statusPageURL: URL { get }
    func fetchStatus() async throws -> ProviderOperationalStatus
}

public struct StatuspageProviderStatusService: ProviderStatusService {
    public let providerID: ProviderID
    private let endpoint: URL
    public let statusPageURL: URL

    public init(providerID: ProviderID, endpoint: URL, statusPageURL: URL) {
        self.providerID = providerID
        self.endpoint = endpoint
        self.statusPageURL = statusPageURL
    }

    public func fetchStatus() async throws -> ProviderOperationalStatus {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: endpoint)
        } catch {
            throw ProviderStatusServiceError.transport
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderStatusServiceError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ProviderStatusServiceError.invalidHTTPStatus(httpResponse.statusCode)
        }
        return try StatuspageStatusParser.parse(
            data: data,
            providerID: providerID,
            statusPageURL: statusPageURL,
            checkedAt: Date()
        )
    }
}

public enum StatuspageStatusParser {
    public static func parse(
        data: Data,
        providerID: ProviderID,
        statusPageURL: URL,
        checkedAt: Date
    ) throws -> ProviderOperationalStatus {
        let payload: StatuspagePayload
        do {
            payload = try JSONDecoder().decode(StatuspagePayload.self, from: data)
        } catch {
            throw ProviderStatusServiceError.invalidResponse
        }
        let summary = payload.status.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else { throw ProviderStatusServiceError.invalidResponse }
        return ProviderOperationalStatus(
            providerID: providerID,
            condition: condition(for: payload.status.indicator),
            summary: summary,
            statusPageURL: statusPageURL,
            checkedAt: checkedAt,
            freshness: .fresh
        )
    }

    public static func condition(for indicator: String) -> ProviderServiceCondition {
        switch indicator.lowercased() {
        case "none": .operational
        case "minor": .degraded
        case "major", "critical": .outage
        default: .unknown
        }
    }

    private struct StatuspagePayload: Decodable {
        let status: Status

        struct Status: Decodable {
            let indicator: String
            let description: String
        }
    }
}

public actor ProviderStatusMonitor {
    private let services: [any ProviderStatusService]
    private let minimumRefreshInterval: TimeInterval
    private var latestGood: [ProviderID: ProviderOperationalStatus] = [:]
    private var lastAttemptAt: Date?
    private var latestDashboard: ProviderStatusDashboardSnapshot?

    public init(
        services: [any ProviderStatusService],
        minimumRefreshInterval: TimeInterval = 5 * 60
    ) {
        self.services = services
        self.minimumRefreshInterval = max(0, minimumRefreshInterval)
    }

    public func refresh(
        now: Date = Date(),
        force: Bool = false
    ) async -> ProviderStatusDashboardSnapshot {
        if !force,
           let lastAttemptAt,
           now.timeIntervalSince(lastAttemptAt) < minimumRefreshInterval,
           let latestDashboard {
            return latestDashboard
        }
        lastAttemptAt = now

        var statuses: [ProviderOperationalStatus] = []
        for service in services {
            do {
                let status = try await service.fetchStatus()
                latestGood[service.providerID] = status
                statuses.append(status)
            } catch {
                if let cached = latestGood[service.providerID] {
                    statuses.append(ProviderOperationalStatus(
                        providerID: cached.providerID,
                        condition: cached.condition,
                        summary: cached.summary,
                        statusPageURL: cached.statusPageURL,
                        checkedAt: cached.checkedAt,
                        freshness: .stale
                    ))
                } else {
                    statuses.append(ProviderOperationalStatus(
                        providerID: service.providerID,
                        condition: .unknown,
                        summary: "Provider status is temporarily unavailable.",
                        statusPageURL: service.statusPageURL,
                        checkedAt: now,
                        freshness: .unavailable
                    ))
                }
            }
        }

        let dashboard = ProviderStatusDashboardSnapshot(
            generatedAt: now,
            providers: statuses.sorted { $0.providerID.rawValue < $1.providerID.rawValue }
        )
        latestDashboard = dashboard
        return dashboard
    }

}
