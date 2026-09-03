import EvoBarCore
import EvoBarUsage
import Foundation

public final class CodexLogParser: JSONLUsageParsing {
    public private(set) var sessionID: String?
    public private(set) var modelID: String?
    private let sourceFingerprint: String
    private let decoder = JSONDecoder()
    private var cumulativeResetEpoch = 0
    private var lastCumulativeTotal: Int64?

    public init(sourceFingerprint: String, sessionID: String? = nil, modelID: String? = nil) {
        self.sourceFingerprint = sourceFingerprint
        self.sessionID = sessionID
        self.modelID = modelID
    }

    public func parse(line: Data) throws -> UsageEvent? {
        let record = try decoder.decode(Record.self, from: line)
        if record.type == "session_meta" {
            sessionID = record.payload?.sessionId ?? record.payload?.id ?? sessionID
            modelID = record.payload?.model ?? modelID
            return nil
        }
        if record.type == "turn_context" {
            modelID = record.payload?.model ?? modelID
            return nil
        }
        guard record.type == "event_msg",
              record.payload?.type == "token_count",
              let last = record.payload?.info?.lastTokenUsage,
              let timestamp = UsageTimestampParser.parse(record.timestamp ?? record.payload?.timestamp),
              let resolvedSessionID = sessionID else {
            return nil
        }

        let totalUsage = record.payload?.info?.totalTokenUsage
        if let cumulativeTotal = totalUsage?.totalTokens?.value {
            if let previous = lastCumulativeTotal, cumulativeTotal < previous {
                cumulativeResetEpoch += 1
            }
            lastCumulativeTotal = cumulativeTotal
        }

        let input = last.inputTokens?.value ?? 0
        let output = last.outputTokens?.value ?? 0
        let cacheRead = last.cachedInputTokens?.value ?? 0
        let cacheWrite = last.cacheWriteInputTokens?.value ?? 0
        let reasoning = last.reasoningOutputTokens?.value ?? 0
        let authoritativeTotal = last.totalTokens?.value ?? max(0, input + output)
        let identityTuple: [String]
        if let totalUsage {
            identityTuple = [
                "codex", resolvedSessionID, String(cumulativeResetEpoch),
                String(totalUsage.inputTokens?.value ?? 0),
                String(totalUsage.outputTokens?.value ?? 0),
                String(totalUsage.cachedInputTokens?.value ?? 0),
                String(totalUsage.cacheWriteInputTokens?.value ?? 0),
                String(totalUsage.totalTokens?.value ?? 0),
            ]
        } else {
            identityTuple = [
                "codex", resolvedSessionID, record.timestamp ?? "", String(input),
                String(output), String(cacheRead), String(cacheWrite), String(authoritativeTotal),
            ]
        }

        return UsageEvent(
            stableID: UsageEventID(rawValue: StableHasher.sha256(identityTuple)),
            provider: .codex,
            sessionID: resolvedSessionID,
            timestamp: timestamp,
            modelID: record.payload?.model ?? modelID,
            usage: TokenUsage(
                inputTokens: input,
                outputTokens: output,
                cacheReadTokens: cacheRead,
                cacheWriteTokens: cacheWrite,
                reasoningTokens: reasoning,
                totalTokens: authoritativeTotal
            ),
            sourceFingerprint: sourceFingerprint
        )
    }
}

private extension CodexLogParser {
    struct Record: Decodable {
        let type: String?
        let timestamp: String?
        let payload: Payload?
    }

    struct Payload: Decodable {
        let type: String?
        let id: String?
        let sessionId: String?
        let timestamp: String?
        let model: String?
        let info: Info?

        enum CodingKeys: String, CodingKey {
            case type, id, timestamp, model, info
            case sessionId = "session_id"
        }
    }

    struct Info: Decodable {
        let lastTokenUsage: Usage?
        let totalTokenUsage: Usage?

        enum CodingKeys: String, CodingKey {
            case lastTokenUsage = "last_token_usage"
            case totalTokenUsage = "total_token_usage"
        }
    }

    struct Usage: Decodable {
        let inputTokens: FlexibleInt64?
        let outputTokens: FlexibleInt64?
        let cachedInputTokens: FlexibleInt64?
        let cacheWriteInputTokens: FlexibleInt64?
        let reasoningOutputTokens: FlexibleInt64?
        let totalTokens: FlexibleInt64?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cachedInputTokens = "cached_input_tokens"
            case cacheWriteInputTokens = "cache_write_input_tokens"
            case reasoningOutputTokens = "reasoning_output_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
