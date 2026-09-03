import CryptoKit
import Foundation

public struct FlexibleInt64: Codable, Equatable, Sendable {
    public let value: Int64

    public init(_ value: Int64) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int64.self) {
            self.value = value
        } else if let value = try? container.decode(String.self), let integer = Int64(value) {
            self.value = integer
        } else if let value = try? container.decode(Double.self), value.isFinite {
            self.value = Int64(value)
        } else {
            self.value = 0
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

public enum StableHasher {
    public static func sha256(_ components: [String]) -> String {
        let data = Data(components.joined(separator: "|").utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public enum UsageTimestampParser {
    public static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
