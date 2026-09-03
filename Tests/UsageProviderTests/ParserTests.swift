import ClaudeCodeProvider
import CodexProvider
import EvoBarUsage
import Foundation
import Testing

@Suite struct ParserTests {
    @Test func claudeParserMapsUsageWithoutContent() throws {
        let lines = try fixtureLines(file: "claude_usage")
        let parser = ClaudeLogParser(sourceFingerprint: "source")
        let events = try lines.compactMap { try parser.parse(line: $0) }
        #expect(events.count == 2)
        #expect(events[0].usage.totalTokens == 460)
        #expect(events[0].usage.cacheWriteTokens == 40)
        #expect(events[1].usage.totalTokens == 15)
        #expect(events[0].stableID != events[1].stableID)
        #expect(!String(describing: events).contains("CANARY"))
    }

    @Test func codexParserUsesSessionContextAndAuthoritativeTotal() throws {
        let lines = try fixtureLines(file: "codex_usage")
        let parser = CodexLogParser(sourceFingerprint: "source")
        let events = try lines.compactMap { try parser.parse(line: $0) }
        #expect(events.count == 2)
        #expect(events[0].sessionID == "codex-session-1")
        #expect(events[0].usage.totalTokens == 1_220)
        #expect(events[0].usage.cacheReadTokens == 600)
        #expect(events[0].usage.reasoningTokens == 50)
        #expect(!String(describing: events).contains("CANARY"))
    }

    @Test func codexParserCarriesTurnContextModelIntoUsageAndCheckpoint() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarModelContextTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("usage.jsonl")
        let jsonl = """
        {"timestamp":"2026-09-03T01:00:00Z","type":"session_meta","payload":{"id":"session-model"}}
        {"timestamp":"2026-09-03T01:00:01Z","type":"turn_context","payload":{"model":"gpt-5.6-terra","cwd":"CANARY_PATH"}}
        {"timestamp":"2026-09-03T01:00:02Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"input_tokens":10,"output_tokens":5,"total_tokens":15},"total_token_usage":{"input_tokens":10,"output_tokens":5,"total_tokens":15}}}}
        """
        try Data((jsonl + "\n").utf8).write(to: file)

        let batch = try IncrementalJSONLScanner.scan(
            url: file,
            checkpoint: SourceCheckpoint(),
            parser: CodexLogParser(sourceFingerprint: "source")
        )

        #expect(batch.events.first?.modelID == "gpt-5.6-terra")
        #expect(batch.checkpoint.modelID == "gpt-5.6-terra")
        #expect(!String(describing: batch.events).contains("CANARY"))
    }

    @Test func malformedLineDoesNotStopIncrementalScan() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let file = temporaryDirectory.appendingPathComponent("usage.jsonl")
        let valid = try fixtureLines(file: "claude_usage")[0]
        var data = Data("{malformed}\n".utf8)
        data.append(valid)
        data.append(0x0A)
        try data.write(to: file)

        let first = try IncrementalJSONLScanner.scan(
            url: file,
            checkpoint: SourceCheckpoint(),
            parser: ClaudeLogParser(sourceFingerprint: "source")
        )
        #expect(first.malformedLineCount == 1)
        #expect(first.events.count == 1)

        let duplicate = try IncrementalJSONLScanner.scan(
            url: file,
            checkpoint: first.checkpoint,
            parser: ClaudeLogParser(
                sourceFingerprint: "source",
                sessionID: first.checkpoint.sessionID
            )
        )
        #expect(duplicate.events.isEmpty)
    }

    @Test func truncatedLogRestartsAtBeginningWithNewGeneration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarRotationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("usage.jsonl")
        let lines = try fixtureLines(file: "claude_usage")
        var original = lines[0]
        original.append(0x0A)
        original.append(Data(repeating: 0x20, count: 1_024))
        original.append(0x0A)
        try original.write(to: file)

        let first = try IncrementalJSONLScanner.scan(
            url: file,
            checkpoint: SourceCheckpoint(),
            parser: ClaudeLogParser(sourceFingerprint: "source")
        )
        var rotated = lines[1]
        rotated.append(0x0A)
        try rotated.write(to: file)

        let second = try IncrementalJSONLScanner.scan(
            url: file,
            checkpoint: first.checkpoint,
            parser: ClaudeLogParser(sourceFingerprint: "source")
        )

        #expect(second.checkpoint.generation == first.checkpoint.generation + 1)
        #expect(second.events.count == 1)
        #expect(second.events[0].usage.totalTokens == 15)
    }

    private func fixtureLines(file: String) throws -> [Data] {
        let url = try #require(Bundle.module.url(forResource: file, withExtension: "jsonl"))
        let contents = try #require(String(data: Data(contentsOf: url), encoding: .utf8))
        return contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { Data($0.utf8) }
    }
}
