import EvoBarCore
import EvoBarUsage
import Foundation

public struct UsageTrackingResult: Sendable {
    public let snapshot: PersistedAppSnapshot
    public let reports: [ProviderTrackingReport]
}

/// The app uses one refresh worker for timer, file-change and manual requests.
/// Failures are reported per provider while readable sources keep progressing.
public actor UsageTrackingCoordinator {
    private let store: EvoBarStore
    private let providers: [any UsageProvider]
    private let effectiveTokensPerCoin: Int64

    public init(store: EvoBarStore, providers: [any UsageProvider], effectiveTokensPerCoin: Int64) {
        self.store = store
        self.providers = providers
        self.effectiveTokensPerCoin = effectiveTokensPerCoin
    }

    public func scanOnce() async throws -> UsageTrackingResult {
        try Task.checkCancellation()
        let before = await store.snapshot()
        let cutoff = UsageIngestionPolicy.eventCutoff(
            trackingStartedAt: before.trackingStartedAt, timeZoneID: before.growthTimeZoneID)
        var reports: [ProviderTrackingReport] = []
        for provider in providers {
            try Task.checkCancellation()
            var report = ProviderTrackingReport(providerID: provider.providerID)
            let discovery: LogDiscoveryReport
            do {
                discovery = try await provider.discoverLogs()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                report.issues.insert(TrackingIssue.reading(error) == .permissionRequired
                    ? .permissionRequired : .discoveryFailed)
                reports.append(report)
                continue
            }
            report.sourceCount = discovery.locations.count
            report.issues = discovery.issues
            for location in discovery.locations {
                try Task.checkCancellation()
                let sourceKey = StableHasher.sha256([provider.providerID.rawValue, location.url.path])
                let existing = await store.checkpoint(for: sourceKey)
                let batch: ScanBatch
                do {
                    let values = try location.url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                    if existing == nil, (values.contentModificationDate ?? .distantPast) < cutoff {
                        let size = UInt64(max(0, values.fileSize ?? 0))
                        batch = ScanBatch(events: [], checkpoint: SourceCheckpoint(byteOffset: size, fileSize: size), malformedLineCount: 0)
                    } else {
                        batch = try await provider.scan(location: location, checkpoint: existing ?? SourceCheckpoint())
                    }
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    report.issues.insert(TrackingIssue.reading(error))
                    continue
                }
                try Task.checkCancellation()
                do {
                    if existing != batch.checkpoint || !batch.events.isEmpty {
                        try await store.ingest(
                            batch: batch, sourceKey: sourceKey, providerID: provider.providerID,
                            effectiveTokensPerCoin: effectiveTokensPerCoin,
                            eventCutoff: existing == nil ? cutoff : nil)
                    }
                    report.checkedSourceCount += 1
                    report.malformedLineCount += batch.malformedLineCount
                } catch {
                    report.issues.insert(.saveFailed)
                }
            }
            report.checkedAt = Date()
            reports.append(report)
        }
        try Task.checkCancellation()
        return UsageTrackingResult(snapshot: await store.snapshot(), reports: reports)
    }
}
