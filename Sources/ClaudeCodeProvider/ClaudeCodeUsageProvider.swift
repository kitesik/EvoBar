import EvoBarCore
import EvoBarUsage
import Foundation

public final class ClaudeCodeUsageProvider: UsageProvider, @unchecked Sendable {
    public let providerID = ProviderID.claudeCode
    private let roots: [URL]
    private let additionalPatterns: [String]

    public init(roots: [URL]? = nil, additionalPatterns: [String] = []) {
        self.roots = roots ?? [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/projects", isDirectory: true)
        ]
        self.additionalPatterns = additionalPatterns
    }

    public func detectionStatus() async -> DetectionStatus {
        do {
            let locations = try await discoverLogLocations()
            return locations.isEmpty ? .notFound : .found(sourceCount: locations.count)
        } catch CocoaError.fileReadNoPermission {
            return .permissionRequired
        } catch {
            return .failed(code: "discovery_failed")
        }
    }

    public func discoverLogLocations() async throws -> [LogLocation] {
        try LogPathResolver.jsonlLocations(
            defaultRoots: roots,
            additionalPatterns: additionalPatterns,
            providerID: providerID
        )
    }

    public func scan(location: LogLocation, checkpoint: SourceCheckpoint) async throws -> ScanBatch {
        let fingerprint = StableHasher.sha256([providerID.rawValue, location.url.path])
        let parser = ClaudeLogParser(
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
