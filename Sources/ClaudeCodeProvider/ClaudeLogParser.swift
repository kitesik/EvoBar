import EvoBarCore
import EvoBarUsage
import Foundation

public final class ClaudeLogParser: JSONLUsageParsing {
    public private(set) var sessionID: String?
    public private(set) var modelID: String?
    private let sourceFingerprint: String
    private let decoder = JSONDecoder()

    public init(sourceFingerprint: String, sessionID: String? = nil, modelID: String? = nil) {
        self.sourceFingerprint = sourceFingerprint
        self.sessionID = sessionID
        self.modelID = modelID
    }

    public func parse(line: Data) throws -> UsageEvent? {
        let record = try decoder.decode(Record.self, from: line)
        guard record.type == "assistant",
              record.message?.role == "assistant",
              let usage = record.message?.usage,
              let timestamp = UsageTimestampParser.parse(record.timestamp),
              let resolvedSessionID = record.sessionId ?? sessionID else {
            return nil
        }
        sessionID = resolvedSessionID
        modelID = record.message?.model ?? modelID
        let input = usage.inputTokens?.value ?? 0
        let output = usage.outputTokens?.value ?? 0
        let cacheRead = usage.cacheReadInputTokens?.value ?? 0
        let cacheWrite = usage.cacheCreationInputTokens?.value ?? 0
        let total = [input, output, cacheRead, cacheWrite].reduce(Int64(0)) { result, value in
            let (sum, overflow) = result.addingReportingOverflow(max(0, value))
            return overflow ? Int64.max : sum
        }
        let nativeID = record.uuid ?? record.requestId ?? record.message?.id
            ?? StableHasher.sha256([record.timestamp ?? "", String(total)])
        let stableID = StableHasher.sha256(["claude", resolvedSessionID, nativeID])
        return UsageEvent(
            stableID: UsageEventID(rawValue: stableID),
            provider: .claudeCode,
            sessionID: resolvedSessionID,
            timestamp: timestamp,
            modelID: modelID,
            usage: TokenUsage(
                inputTokens: input,
                outputTokens: output,
                cacheReadTokens: cacheRead,
                cacheWriteTokens: cacheWrite,
                totalTokens: total
            ),
            sourceFingerprint: sourceFingerprint
        )
    }
}

private extension ClaudeLogParser {
    struct Record: Decodable {
        let type: String?
        let uuid: String?
        let requestId: String?
        let sessionId: String?
        let timestamp: String?
        let message: Message?
    }

    struct Message: Decodable {
        let id: String?
        let role: String?
        let model: String?
        let usage: Usage?
    }

    struct Usage: Decodable {
        let inputTokens: FlexibleInt64?
        let outputTokens: FlexibleInt64?
        let cacheReadInputTokens: FlexibleInt64?
        let cacheCreationInputTokens: FlexibleInt64?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
        }
    }
}
