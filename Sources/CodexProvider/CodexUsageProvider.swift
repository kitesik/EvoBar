import EvoBarCore
import EvoBarUsage
import Foundation

public final class CodexUsageProvider: UsageProvider, @unchecked Sendable {
    public let providerID = ProviderID.codex
    private let roots: [URL]
    private let additionalPatterns: [String]

    public init(roots: [URL]? = nil, additionalPatterns: [String] = []) {
        self.roots = roots ?? [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".codex/sessions", isDirectory: true)
        ]
        self.additionalPatterns = additionalPatterns
    }

    public func detectionStatus() async -> DetectionStatus {
        do {
            let report = try await discoverLogs()
            if report.issues.contains(.permissionRequired) { return .permissionRequired }
            if !report.issues.isEmpty { return .failed(code: "discovery_failed") }
            return report.locations.isEmpty ? .notFound : .found(sourceCount: report.locations.count)
        } catch CocoaError.fileReadNoPermission {
            return .permissionRequired
        } catch {
            return .failed(code: "discovery_failed")
        }
    }

    public func discoverLogLocations() async throws -> [LogLocation] {
        try await discoverLogs().locations
    }

    public func discoverLogs() async throws -> LogDiscoveryReport {
        try LogPathResolver.discoveryReport(
            defaultRoots: roots,
            additionalPatterns: additionalPatterns,
            providerID: providerID
        )
    }

    public func scan(location: LogLocation, checkpoint: SourceCheckpoint) async throws -> ScanBatch {
        let fingerprint = StableHasher.sha256([providerID.rawValue, location.url.path])
        let parser = CodexLogParser(
            sourceFingerprint: fingerprint,
            sessionID: checkpoint.sessionID,
            modelID: checkpoint.modelID
        )
        return try IncrementalJSONLScanner.scan(
            url: location.url,
            checkpoint: checkpoint,
            parser: parser
        )
    }
}
