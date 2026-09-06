import EvoBarCore
import Testing

@Suite struct UsageBandTests {
    private let thresholds: [Int64] = [1_000_000, 5_000_000, 20_000_000]

    @Test func bandsFollowThresholds() {
        #expect(UsageBand.band(for: 0, thresholds: thresholds) == .light)
        #expect(UsageBand.band(for: 999_999, thresholds: thresholds) == .light)
        #expect(UsageBand.band(for: 1_000_000, thresholds: thresholds) == .steady)
        #expect(UsageBand.band(for: 19_999_999, thresholds: thresholds) == .heavy)
        #expect(UsageBand.band(for: 20_000_000, thresholds: thresholds) == .extreme)
    }

    @Test func invalidThresholdsFallBackToDefaults() {
        #expect(AppSettings.validatedUsageBandThresholds([3, 2, 1]) == AppSettings.defaultUsageBandThresholds)
        #expect(AppSettings.validatedUsageBandThresholds([1, 2]) == AppSettings.defaultUsageBandThresholds)
        #expect(UsageBand.band(for: 3, thresholds: [5, 2]) == .light)
        #expect(AppSettings(usageBandThresholds: [0, 1, 2]).usageBandThresholds == AppSettings.defaultUsageBandThresholds)
    }
}
