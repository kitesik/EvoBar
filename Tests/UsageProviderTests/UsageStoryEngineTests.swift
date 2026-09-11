import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct UsageStoryEngineTests {
    /// 2025-09-10 10:26:40 UTC, which is 19:26 in Seoul.
    private let base = Date(timeIntervalSince1970: 1_757_500_000)
    private let utc = TimeZone(identifier: "UTC")!

    private func sample(_ session: String, _ offset: TimeInterval, tokens: Int64 = 10) -> UsageStoryEngine.Sample {
        UsageStoryEngine.Sample(session: session, timestamp: base.addingTimeInterval(offset), tokens: tokens)
    }

    /// Two tools open at once are one person working, and a long silence in a
    /// session starts a new stretch rather than stretching the old one.
    @Test func parallelSessionsCountOnceAndGapsSplitStretches() {
        let story = UsageStoryEngine.story(
            [sample("a", 3_600), sample("a", 0), sample("b", 120), sample("a", 300)], timeZone: utc)
        #expect(story.activeSeconds == 360 + 60)
        #expect(story.longestSessionSeconds == 360)
    }

    @Test func peakHourFollowsTheGrowthTimeZone() {
        let samples = [sample("a", 0, tokens: 5), sample("a", 7_200, tokens: 1)]
        #expect(UsageStoryEngine.story(samples, timeZone: utc).peakHour == 10)
        #expect(UsageStoryEngine.story(samples, timeZone: TimeZone(identifier: "Asia/Seoul")!).peakHour == 19)
    }

    @Test func aLoneEventIsAMinuteAndNoEventsIsNoStory() {
        #expect(UsageStoryEngine.story([], timeZone: utc) == .empty)
        let story = UsageStoryEngine.story([sample("a", 0)], timeZone: utc)
        #expect(story.activeSeconds == 60)
        #expect(story.longestSessionSeconds == 60)
        #expect(story.peakHour == 10)
    }

    @Test func novelsComeToOnePerHundredTwentyThousandTokens() {
        #expect(UsageStoryEngine.novels(tokens: 120_000) == 1)
        #expect(UsageStoryEngine.novels(tokens: 60_000) == 0.5)
        #expect(UsageStoryEngine.novels(tokens: -5) == 0)
    }
}
