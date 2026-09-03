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
