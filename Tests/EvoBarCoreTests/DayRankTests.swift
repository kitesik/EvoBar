import EvoBarCore
import Testing

@Suite struct DayRankTests {
    @Test func ranksTodayAgainstRecordedHistory() {
        #expect(DayRank.rank(today: 500, history: []) == nil)
        #expect(DayRank.rank(today: 500, history: [100, 900, 500])! == (rank: 2, total: 4))
        #expect(DayRank.rank(today: 1_000, history: [100, 900])! == (rank: 1, total: 3))
        #expect(DayRank.rank(today: 0, history: [100, 900])! == (rank: 3, total: 3))
    }
}
