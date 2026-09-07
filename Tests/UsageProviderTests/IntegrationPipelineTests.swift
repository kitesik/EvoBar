import ClaudeCodeProvider
import EvoBarCore
import EvoBarEvolution
import EvoBarPersistence
import EvoBarUsage
import Foundation
import Testing

@Suite struct IntegrationPipelineTests {
    @Test func appendedLogFlowsThroughGrowthAndSurvivesRelaunchWithoutDuplicates() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarPipelineTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logURL = directory.appendingPathComponent("session.jsonl")
        let stateURL = directory.appendingPathComponent("state.json")
        let timestamp = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
        let provider = ClaudeCodeUsageProvider(roots: [])
        let location = LogLocation(url: logURL, providerID: .claudeCode)
        let sourceKey = StableHasher.sha256([ProviderID.claudeCode.rawValue, logURL.path])
        let stages = try #require(
            ManifestLoader.bundledCatalog().animals.first { $0.id == "cat" }
        ).stages

        let store = try EvoBarStore(fileURL: stateURL)
        try await store.completeOnboarding(
            starterID: "cat",
            companionName: "Pipeline",
            startedAt: timestamp.addingTimeInterval(-10)
        )

        try usageLine(
            id: "pipeline-event-1",
            timestamp: timestamp,
            inputTokens: 400_000,
            outputTokens: 100_000
        ).write(to: logURL, options: .atomic)

        let firstBatch = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        let firstInserted = try await store.ingest(
            batch: firstBatch,
            sourceKey: sourceKey,
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let first = await store.snapshot(now: timestamp)

        #expect(firstInserted == 1)
        #expect(first.todayTokens == 500_000)
        // Tokens become food; XP only moves when the user feeds.
        #expect(first.pendingFoodXP == 50)
        #expect(first.currentXP == 0)
        #expect(EvolutionEngine.eligibleStageIndex(xp: first.currentXP, stages: stages) == 1)

        let served = try await store.feedCurrentAnimal()
        let afterFeeding = await store.snapshot(now: timestamp)
        #expect(served == 50)
        #expect(afterFeeding.pendingFoodXP == 0)
        #expect(afterFeeding.currentXP == 50)
        #expect(EvolutionEngine.eligibleStageIndex(xp: afterFeeding.currentXP, stages: stages) == 2)

        try append(
            usageLine(
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
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let afterAppend = await store.snapshot(now: timestamp)

        #expect(incrementalBatch.events.count == 1)
        #expect(incrementalInserted == 1)
        #expect(afterAppend.todayTokens == 1_000_000)
        // 50 already eaten, the newest 50 still waiting in the bowl.
        #expect(afterAppend.currentXP == 50)
        #expect(afterAppend.pendingFoodXP == 50)

        let relaunchedStore = try EvoBarStore(fileURL: stateURL)
        let restored = await relaunchedStore.snapshot(now: timestamp)
        #expect(restored.todayTokens == afterAppend.todayTokens)
        #expect(restored.currentXP == afterAppend.currentXP)
        #expect(restored.pendingFoodXP == afterAppend.pendingFoodXP)

        let fullRescan = try await provider.scan(location: location, checkpoint: SourceCheckpoint())
        let duplicateInsert = try await relaunchedStore.ingest(
            batch: fullRescan,
            sourceKey: sourceKey,
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let afterDuplicate = await relaunchedStore.snapshot(now: timestamp)

        #expect(fullRescan.events.count == 2)
        #expect(duplicateInsert == 0)
        #expect(afterDuplicate.todayTokens == restored.todayTokens)
        #expect(afterDuplicate.currentXP == restored.currentXP)
        #expect(afterDuplicate.tokenCoins == restored.tokenCoins)
    }

    private func usageLine(
        id: String,
        timestamp: Date,
        inputTokens: Int64,
        outputTokens: Int64
    ) throws -> Data {
        let object: [String: Any] = [
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
                    "cache_read_input_tokens": 0,
                    "cache_creation_input_tokens": 0,
                ],
            ],
        ]
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
