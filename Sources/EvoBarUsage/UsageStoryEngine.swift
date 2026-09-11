import EvoBarCore
import Foundation

/// Turns a window's events into the numbers people feel: how long we worked
/// together, when it peaked, the longest sitting, and what the tokens come to
/// in novels. Input, output and cache are for the curious; this is for everyone.
public enum UsageStoryEngine {
    public struct Sample: Equatable, Sendable {
        /// Provider and session together, so two tools' sessions never merge.
        public let session: String
        public let timestamp: Date
        public let tokens: Int64

        public init(session: String, timestamp: Date, tokens: Int64) {
            self.session = session
            self.timestamp = timestamp
            self.tokens = tokens
        }
    }

    /// Two events of one session closer than this are one stretch of work.
    public static let sessionGap: TimeInterval = 10 * 60
    /// A lone event still stands for about this much attention.
    public static let eventFloor: TimeInterval = 60
    /// About a novel: 90,000 words at three quarters of a word per token.
    public static let tokensPerNovel: Int64 = 120_000

    public static func story(_ samples: [Sample], timeZone: TimeZone) -> UsageStory {
        guard !samples.isEmpty else { return .empty }

        // A stretch runs from an event to the next in its session when that
        // follows within the gap, and a little past the last one either way.
        var stretches: [DateInterval] = []
        var longest: TimeInterval = 0
        for events in Dictionary(grouping: samples, by: \.session).values {
            let times = events.map(\.timestamp).sorted()
            var start = times[0]
            var end = times[0].addingTimeInterval(eventFloor)
            for (previous, next) in zip(times, times.dropFirst()) {
                if next.timeIntervalSince(previous) <= sessionGap {
                    end = max(end, next.addingTimeInterval(eventFloor))
                } else {
                    stretches.append(DateInterval(start: start, end: end))
                    longest = max(longest, end.timeIntervalSince(start))
                    start = next
                    end = next.addingTimeInterval(eventFloor)
                }
            }
            stretches.append(DateInterval(start: start, end: end))
            longest = max(longest, end.timeIntervalSince(start))
        }

        // Two tools open at once are one person working; the time is their union.
        var active: TimeInterval = 0
        var open: DateInterval?
        for stretch in stretches.sorted(by: { $0.start < $1.start }) {
            if let current = open, stretch.start <= current.end {
                open = DateInterval(start: current.start, end: max(current.end, stretch.end))
            } else {
                if let current = open { active += current.duration }
                open = stretch
            }
        }
        if let current = open { active += current.duration }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var byHour = [Int64](repeating: 0, count: 24)
        for sample in samples {
            byHour[calendar.component(.hour, from: sample.timestamp)] += max(0, sample.tokens)
        }
        let peak = byHour.indices.max { byHour[$0] < byHour[$1] }.flatMap { byHour[$0] > 0 ? $0 : nil }

        return UsageStory(activeSeconds: active, peakHour: peak, longestSessionSeconds: longest)
    }

    public static func novels(tokens: Int64) -> Double {
        Double(max(0, tokens)) / Double(tokensPerNovel)
    }
}
