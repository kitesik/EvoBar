import EvoBarCore
import Foundation
import Testing

@Suite struct UsageIngestionPolicyTests {
    private let seoul = "Asia/Seoul"

    private func seoulDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: seoul)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func installDuringTheDayBackfillsFromMidnight() {
        let installed = seoulDate(2026, 9, 7, 15)
        let cutoff = UsageIngestionPolicy.eventCutoff(trackingStartedAt: installed, now: installed, timeZoneID: seoul)
        #expect(cutoff == seoulDate(2026, 9, 7, 0))
    }

    @Test func earlierInstallKeepsItsOwnStart() {
        let installed = seoulDate(2026, 9, 6, 23)
        let now = seoulDate(2026, 9, 7, 9)
        let cutoff = UsageIngestionPolicy.eventCutoff(trackingStartedAt: installed, now: now, timeZoneID: seoul)
        #expect(cutoff == installed)
    }
}
