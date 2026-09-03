import ClaudeCodeProvider
import CodexProvider
import EvoBarCore
import EvoBarPersistence
import EvoBarUsage
import Foundation

actor UsageTrackingCoordinator {
    private let store: EvoBarStore
    private let providers: [any UsageProvider]
    private let effectiveTokensPerCoin: Int64

    init(
        store: EvoBarStore,
        providers: [any UsageProvider],
        effectiveTokensPerCoin: Int64
    ) {
        self.store = store
        self.providers = providers
        self.effectiveTokensPerCoin = effectiveTokensPerCoin
    }

    func scanOnce() async throws -> PersistedAppSnapshot {
        let before = await store.snapshot()
        let cutoff = before.trackingStartedAt

        for provider in providers {
            let locations: [LogLocation]
            do {
                locations = try await provider.discoverLogLocations()
            } catch {
                continue
            }
            for location in locations {
                let sourceKey = StableHasher.sha256([provider.providerID.rawValue, location.url.path])
                let existing = await store.checkpoint(for: sourceKey)
                if existing == nil, try shouldBaseline(location.url, before: cutoff) {
                    let size = try fileSize(location.url)
                    try await store.saveBaseline(
                        sourceKey: sourceKey,
                        providerID: provider.providerID,
                        checkpoint: SourceCheckpoint(byteOffset: size, fileSize: size)
                    )
                    continue
                }

                do {
                    let batch = try await provider.scan(
                        location: location,
                        checkpoint: existing ?? SourceCheckpoint()
                    )
                    try await store.ingest(
                        batch: batch,
                        sourceKey: sourceKey,
                        providerID: provider.providerID,
                        effectiveTokensPerCoin: effectiveTokensPerCoin,
                        eventCutoff: existing == nil ? cutoff : nil
                    )
                } catch {
                    continue
                }
            }
        }
        return await store.snapshot()
    }

    private func shouldBaseline(_ url: URL, before cutoff: Date) throws -> Bool {
        let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
        return (values.contentModificationDate ?? .distantPast) < cutoff
    }

    private func fileSize(_ url: URL) throws -> UInt64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return UInt64(max(0, values.fileSize ?? 0))
    }
}
