import ClaudeCodeProvider
import CodexProvider
import EvoBarCore
import EvoBarEvolution
import EvoBarPersistence
import EvoBarUsage
import Foundation
import Testing

@Suite struct IntegrationPipelineTests {
    @Test(arguments: [ProviderID.claudeCode, .codex])
    func appendedLogFlowsThroughGrowthAndSurvivesRelaunchWithoutDuplicates(providerID: ProviderID) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarPipelineTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logURL = directory.appendingPathComponent("session.jsonl")
        let stateURL = directory.appendingPathComponent("state.json")
        let timestamp = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
        let provider: any UsageProvider = providerID == .codex
            ? CodexUsageProvider(roots: []) : ClaudeCodeUsageProvider(roots: [])
        let location = LogLocation(url: logURL, providerID: providerID)
        let sourceKey = StableHasher.sha256([providerID.rawValue, logURL.path])
        let stages = try #require(
            ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" }
        ).stages

        let store = try EvoBarStore(fileURL: stateURL)
        try await store.completeOnboarding(
            starterID: "cat",
            companionName: "Pipeline",
            startedAt: timestamp.addingTimeInterval(-10)
        )

        var initialData = Data()
        if providerID == .codex {
            initialData = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"synthetic-pipeline\",\"model\":\"fixture-model\"}}\n".utf8)
        }
        initialData.append(try usageLine(
            providerID: providerID, cumulativeTotal: 500_000,
            id: "pipeline-event-1",
            timestamp: timestamp,
            inputTokens: 400_000,
            outputTokens: 100_000
        ))
        try initialData.write(to: logURL, options: .atomic)

        let firstBatch = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        let firstInserted = try await store.ingest(
            batch: firstBatch,
            sourceKey: sourceKey,
            providerID: providerID,
            effectiveTokensPerCoin: 100_000
        )
        let first = await store.snapshot(now: timestamp)

        #expect(firstInserted == 1)
        #expect(first.todayTokens == 500_000)
        // XP waits until the Home tab is on screen, then arrives on its own.
        #expect(first.pendingXP == 75)
        #expect(first.currentXP == 0)
        #expect(EvolutionEngine.eligibleStageIndex(xp: first.currentXP, stages: stages) == 1)

        // Pinned to the gift's smallest outcome, coins alone, so the XP is exact.
        let arrived = try await store.absorbPendingXP(
            now: timestamp, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        let afterArrival = await store.snapshot(now: timestamp)
        #expect(arrived.total == 75)
        #expect(afterArrival.pendingXP == 0)
        #expect(afterArrival.currentXP == 75)
        #expect(EvolutionEngine.eligibleStageIndex(xp: afterArrival.currentXP, stages: stages) == 2)

        try append(
            usageLine(
                providerID: providerID, cumulativeTotal: 1_000_000,
                id: "pipeline-event-2",
                timestamp: timestamp.addingTimeInterval(0.5),
                inputTokens: 350_000,
                outputTokens: 150_000
            ),
            to: logURL
        )
        let checkpoint = try #require(await store.checkpoint(for: sourceKey))
        let incrementalBatch = try await provider.scan(location: location, checkpoint: checkpoint)
        let incrementalInserted = try await store.ingest(
            batch: incrementalBatch,
            sourceKey: sourceKey,
            providerID: providerID,
            effectiveTokensPerCoin: 100_000
        )
        let afterAppend = await store.snapshot(now: timestamp)

        #expect(incrementalBatch.events.count == 1)
        #expect(incrementalInserted == 1)
        #expect(afterAppend.todayTokens == 1_000_000)
        // 75 already absorbed; the day's total now reaches 100, leaving 25.
        #expect(afterAppend.currentXP == 75)
        #expect(afterAppend.pendingXP == 25)

        let relaunchedStore = try EvoBarStore(fileURL: stateURL)
        let restored = await relaunchedStore.snapshot(now: timestamp)
        #expect(restored.todayTokens == afterAppend.todayTokens)
        #expect(restored.currentXP == afterAppend.currentXP)
        #expect(restored.pendingXP == afterAppend.pendingXP)

        let fullRescan = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        let duplicateInsert = try await relaunchedStore.ingest(
            batch: fullRescan,
            sourceKey: sourceKey,
            providerID: providerID,
            effectiveTokensPerCoin: 100_000
        )
        let afterDuplicate = await relaunchedStore.snapshot(now: timestamp)

        #expect(fullRescan.events.count == 2)
        #expect(duplicateInsert == 0)
        #expect(afterDuplicate.todayTokens == restored.todayTokens)
        #expect(afterDuplicate.currentXP == restored.currentXP)
        #expect(afterDuplicate.pendingXP == restored.pendingXP)
        #expect(afterDuplicate.tokenCoins == restored.tokenCoins)
    }

    @Test(arguments: [ProviderID.claudeCode, .codex])
    func cachedContextKeepsRawUsageButCreditsLessGrowth(providerID: ProviderID) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarCachedPipeline-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let logURL = directory.appendingPathComponent("session.jsonl")
        let stateURL = directory.appendingPathComponent("state.json")
        let timestamp = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
        let provider: any UsageProvider = providerID == .codex
            ? CodexUsageProvider(roots: []) : ClaudeCodeUsageProvider(roots: [])
        let location = LogLocation(url: logURL, providerID: providerID)
        let sourceKey = StableHasher.sha256([providerID.rawValue, logURL.path])
        let store = try EvoBarStore(fileURL: stateURL)
        try await store.completeOnboarding(
            starterID: "cat", companionName: "Cache fixture",
            startedAt: timestamp.addingTimeInterval(-10))

        var data = Data()
        if providerID == .codex {
            data = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"cached-fixture\"}}\n".utf8)
        }
        data.append(try usageLine(
            providerID: providerID, cumulativeTotal: 4_500_000,
            id: "cached-event-1", timestamp: timestamp,
            inputTokens: 400_000, outputTokens: 100_000,
            cacheReadTokens: 4_000_000))
        try data.write(to: logURL, options: .atomic)
        let firstBatch = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        #expect(try await store.ingest(
            batch: firstBatch, sourceKey: sourceKey, providerID: providerID,
            effectiveTokensPerCoin: 100_000) == 1)
        let first = await store.snapshot(now: timestamp)
        #expect(first.todayTokens == 4_500_000)
        #expect(first.pendingXP == 95)
        #expect(first.tokenCoins == 3)

        try append(usageLine(
            providerID: providerID, cumulativeTotal: 5_500_000,
            id: "cached-event-2", timestamp: timestamp.addingTimeInterval(60),
            inputTokens: 0, outputTokens: 0, cacheReadTokens: 1_000_000), to: logURL)
        let checkpoint = try #require(await store.checkpoint(for: sourceKey))
        let appendBatch = try await provider.scan(location: location, checkpoint: checkpoint)
        #expect(try await store.ingest(
            batch: appendBatch, sourceKey: sourceKey, providerID: providerID,
            effectiveTokensPerCoin: 100_000) == 1)
        let after = await store.snapshot(now: timestamp.addingTimeInterval(60))
        #expect(after.todayTokens == 5_500_000)
        #expect(after.pendingXP == 100)
        #expect(after.tokenCoins == 3)

        let reopened = try EvoBarStore(fileURL: stateURL)
        let fullRescan = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        #expect(try await reopened.ingest(
            batch: fullRescan, sourceKey: sourceKey, providerID: providerID,
            effectiveTokensPerCoin: 100_000) == 0)
        let restored = await reopened.snapshot(now: timestamp.addingTimeInterval(60))
        #expect(restored.todayTokens == after.todayTokens)
        #expect(restored.pendingXP == after.pendingXP)
        #expect(restored.tokenCoins == after.tokenCoins)
    }

    private func usageLine(
        providerID: ProviderID,
        cumulativeTotal: Int64,
        id: String,
        timestamp: Date,
        inputTokens: Int64,
        outputTokens: Int64,
        cacheReadTokens: Int64 = 0
    ) throws -> Data {
        var object: [String: Any] = [
            "type": "assistant",
            "uuid": id,
            "sessionId": "sanitized-pipeline-session",
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "message": [
                "role": "assistant",
                "model": "claude-sonnet-5",
                "usage": [
                    "input_tokens": inputTokens,
                    "output_tokens": outputTokens,
                    "cache_read_input_tokens": cacheReadTokens,
                    "cache_creation_input_tokens": 0,
                ],
            ],
        ]
        if providerID == .codex {
            object = [
                "type": "event_msg",
                "timestamp": ISO8601DateFormatter().string(from: timestamp),
                "payload": ["type": "token_count", "info": [
                    "last_token_usage": ["input_tokens": inputTokens + cacheReadTokens,
                                         "cached_input_tokens": cacheReadTokens,
                                         "output_tokens": outputTokens,
                                         "total_tokens": inputTokens + cacheReadTokens + outputTokens],
                    "total_token_usage": ["total_tokens": cumulativeTotal],
                ]],
            ]
        }
        var data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        data.append(0x0A)
        return data
    }

    private func append(_ data: Data, to fileURL: URL) throws {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
}
