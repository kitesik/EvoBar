import ClaudeCodeProvider
import EvoBarCore
import EvoBarPersistence
import EvoBarUsage
import Foundation
import Testing

@Suite struct TrackingCoordinatorTests {
    @Test func missingLogsAreAnEmptyConnectionNotSuccessOrFailure() async throws {
        let store = try EvoBarStore(fileURL: nil)
        let result = try await UsageTrackingCoordinator(store: store, providers: [StubProvider()], effectiveTokensPerCoin: 100_000).scanOnce()
        let report = try #require(result.reports.first)
        #expect(report.sourceCount == 0)
        #expect(!report.isConnected)
        #expect(!report.needsAttention)
    }

    @Test func oneProviderFailureDoesNotHideTheOtherProvider() async throws {
        let store = try EvoBarStore(fileURL: nil)
        let denied = StubProvider(providerID: .claudeCode, discoveryError: .fileReadNoPermission)
        let result = try await UsageTrackingCoordinator(store: store, providers: [denied, StubProvider(providerID: .codex)], effectiveTokensPerCoin: 100_000).scanOnce()
        #expect(result.reports.count == 2)
        #expect(result.reports[0].issues == [.permissionRequired])
        #expect(!result.reports[1].needsAttention)
    }

    @Test func vanishedFileDoesNotAbortOtherSources() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let good = root.appendingPathComponent("good.jsonl")
        try Data("{}\n".utf8).write(to: good)
        let store = try EvoBarStore(fileURL: nil)
        let provider = StubProvider(locations: [
            LogLocation(url: root.appendingPathComponent("removed.jsonl"), providerID: .codex),
            LogLocation(url: good, providerID: .codex)
        ])
        let result = try await UsageTrackingCoordinator(store: store, providers: [provider], effectiveTokensPerCoin: 100_000).scanOnce()
        let report = try #require(result.reports.first)
        #expect(report.sourceCount == 2)
        #expect(report.checkedSourceCount == 1)
        #expect(report.isConnected && report.needsAttention)
        #expect(report.issues == [.readFailed])
    }

    @Test func malformedLinesAndPartialDiscoveryAreVisibleWhileUsageStillCounts() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let log = root.appendingPathComponent("session.jsonl")
        let now = Date()
        let line = "{\"type\":\"assistant\",\"uuid\":\"safe-event\",\"sessionId\":\"fixture\",\"timestamp\":\"\(ISO8601DateFormatter().string(from: now))\",\"message\":{\"id\":\"safe-message\",\"role\":\"assistant\",\"usage\":{\"input_tokens\":500000,\"output_tokens\":0}}}\n"
        try Data(("malformed\n" + line).utf8).write(to: log)
        let store = try EvoBarStore(fileURL: root.appendingPathComponent("state.json"))
        try await store.completeOnboarding(starterID: "cat", companionName: "Fixture", startedAt: now.addingTimeInterval(-5))
        let provider = ClaudeCodeUsageProvider(roots: [root])
        let coordinator = UsageTrackingCoordinator(store: store, providers: [provider], effectiveTokensPerCoin: 100_000)
        let first = try await coordinator.scanOnce()
        #expect(first.reports[0].malformedLineCount == 1)
        #expect(first.reports[0].needsAttention)
        #expect(first.snapshot.todayTokens == 500_000)
        #expect(first.snapshot.pendingXP == 75)
        let savedBeforeRescan = try Data(contentsOf: root.appendingPathComponent("state.json"))
        let next = try await coordinator.scanOnce()
        #expect(try Data(contentsOf: root.appendingPathComponent("state.json")) == savedBeforeRescan)
        #expect(next.reports[0].malformedLineCount == 0)
        #expect(!next.reports[0].needsAttention)
        #expect(next.snapshot.todayTokens == first.snapshot.todayTokens)
        let reopened = try EvoBarStore(fileURL: root.appendingPathComponent("state.json"))
        let restored = try await UsageTrackingCoordinator(store: reopened, providers: [provider], effectiveTokensPerCoin: 100_000).scanOnce()
        #expect(restored.snapshot.todayTokens == 500_000)
        #expect(restored.snapshot.pendingXP == 75)

        let partial = StubProvider(locations: [LogLocation(url: log, providerID: .codex)], discoveryIssues: [.permissionRequired])
        let report = try await UsageTrackingCoordinator(store: reopened, providers: [partial], effectiveTokensPerCoin: 100_000).scanOnce().reports[0]
        #expect(report.isConnected && report.needsAttention)
    }

    @Test func cancelledScanNeverWritesACheckpoint() async throws {
        let store = try EvoBarStore(fileURL: nil)
        let provider = StubProvider(cancelDuringDiscovery: true)
        do {
            _ = try await UsageTrackingCoordinator(store: store, providers: [provider], effectiveTokensPerCoin: 100_000).scanOnce()
            Issue.record("Cancellation must reach the caller")
        } catch is CancellationError { }
        #expect(await store.snapshot().todayTokens == 0)
    }

    @Test func failedSaveRollsBackUsageAndCheckpointSoRetryIsExact() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let stateURL = root.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: stateURL)
        let now = Date()
        try await store.completeOnboarding(starterID: "cat", companionName: "Fixture", startedAt: now)
        let saved = try Data(contentsOf: stateURL)
        // A directory at the expected file location deterministically refuses writes.
        try FileManager.default.removeItem(at: stateURL)
        try FileManager.default.createDirectory(at: stateURL, withIntermediateDirectories: false)
        let event = UsageEvent(stableID: UsageEventID(rawValue: "retry-event"), provider: .codex, sessionID: "fixture", timestamp: now, modelID: nil,
                               usage: TokenUsage(inputTokens: 500_000, outputTokens: 0, totalTokens: 500_000), sourceFingerprint: "fixture")
        let batch = ScanBatch(events: [event], checkpoint: SourceCheckpoint(byteOffset: 42, fileSize: 42), malformedLineCount: 0)
        do {
            try await store.ingest(batch: batch, sourceKey: "fixture", providerID: .codex, effectiveTokensPerCoin: 100_000)
            Issue.record("The blocked storage path must fail")
        } catch { }
        #expect(await store.checkpoint(for: "fixture") == nil)
        #expect(await store.snapshot(now: now).todayTokens == 0)
        #expect(await store.snapshot(now: now).pendingXP == 0)
        try FileManager.default.removeItem(at: stateURL)
        try saved.write(to: stateURL)
        #expect(try await store.ingest(batch: batch, sourceKey: "fixture", providerID: .codex, effectiveTokensPerCoin: 100_000) == 1)
        let reopened = try EvoBarStore(fileURL: stateURL)
        #expect(await reopened.snapshot(now: now).todayTokens == 500_000)
        #expect(await reopened.snapshot(now: now).pendingXP == 75)
        #expect(try await reopened.ingest(batch: batch, sourceKey: "fixture", providerID: .codex, effectiveTokensPerCoin: 100_000) == 0)
    }

    private func temporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarTracking-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

private struct StubProvider: UsageProvider {
    var providerID: ProviderID = .codex
    var locations: [LogLocation] = []
    var discoveryError: CocoaError.Code?
    var discoveryIssues: Set<TrackingIssue> = []
    var cancelDuringDiscovery = false
    func detectionStatus() async -> DetectionStatus { .notFound }
    func discoverLogLocations() async throws -> [LogLocation] { locations }
    func discoverLogs() async throws -> LogDiscoveryReport {
        if cancelDuringDiscovery { throw CancellationError() }
        if let discoveryError { throw CocoaError(discoveryError) }
        return LogDiscoveryReport(locations: locations, issues: discoveryIssues)
    }
    func scan(location: LogLocation, checkpoint: SourceCheckpoint) async throws -> ScanBatch {
        ScanBatch(events: [], checkpoint: checkpoint, malformedLineCount: 0)
    }
}
