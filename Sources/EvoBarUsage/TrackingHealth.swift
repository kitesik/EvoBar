import EvoBarCore
import Foundation

/// Safe, transient diagnostics. Never contains paths, session IDs or error text.
public enum TrackingIssue: String, Hashable, Sendable {
    case permissionRequired, discoveryFailed, readFailed, saveFailed

    public static func reading(_ error: any Error) -> Self {
        let error = error as NSError
        if (error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoPermissionError)
            || (error.domain == NSPOSIXErrorDomain && [1, 13].contains(error.code)) {
            return .permissionRequired
        }
        return .readFailed
    }
}

public struct ProviderTrackingReport: Equatable, Sendable, Identifiable {
    public var id: ProviderID { providerID }
    public let providerID: ProviderID
    public var sourceCount: Int
    public var checkedSourceCount: Int
    public var malformedLineCount: Int
    public var issues: Set<TrackingIssue>
    public var checkedAt: Date

    public init(
        providerID: ProviderID, sourceCount: Int = 0, checkedSourceCount: Int = 0,
        malformedLineCount: Int = 0, issues: Set<TrackingIssue> = [], checkedAt: Date = Date()
    ) {
        self.providerID = providerID
        self.sourceCount = sourceCount
        self.checkedSourceCount = checkedSourceCount
        self.malformedLineCount = malformedLineCount
        self.issues = issues
        self.checkedAt = checkedAt
    }

    public var needsAttention: Bool { !issues.isEmpty || malformedLineCount > 0 }
    public var isConnected: Bool { checkedSourceCount > 0 }
}

public struct LogDiscoveryReport: Sendable {
    public var locations: [LogLocation]
    public var issues: Set<TrackingIssue>

    public init(locations: [LogLocation] = [], issues: Set<TrackingIssue> = []) {
        self.locations = locations
        self.issues = issues
    }
}
