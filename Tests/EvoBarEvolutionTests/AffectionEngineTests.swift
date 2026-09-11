import EvoBarEvolution
import Foundation
import Testing

@Suite struct AffectionEngineTests {
    private let day: TimeInterval = 86_400

    @Test func neglectDecaysGentlyAfterOneGraceDay() {
        let start = Date()
        let stored = AffectionEngine.starting

        // Same day and the grace day itself cost nothing.
        #expect(AffectionEngine.currentPoints(stored: stored, updatedAt: start, now: start) == stored)
        #expect(AffectionEngine.currentPoints(
            stored: stored,
            updatedAt: start,
            now: start.addingTimeInterval(day)
        ) == stored)

        // Then 0.20 per further day.
        #expect(AffectionEngine.currentPoints(
            stored: stored,
            updatedAt: start,
            now: start.addingTimeInterval(3 * day)
        ) == stored - 40)
        #expect(AffectionEngine.currentPoints(
            stored: stored,
            updatedAt: start,
            now: start.addingTimeInterval(101 * day)
        ) == stored - 2_000)
    }

    @Test func affectionStaysWithinBounds() {
        let start = Date()
        #expect(AffectionEngine.currentPoints(
            stored: 100,
            updatedAt: start,
            now: start.addingTimeInterval(400 * day)
        ) == 0)
        var points = AffectionEngine.maximum
        points = AffectionEngine.afterTreat(points: points)
        #expect(points == AffectionEngine.maximum)
    }

    @Test func moodBandsFollowThePublishedThresholds() {
        #expect(AffectionEngine.mood(for: 0) == .sulking)
        #expect(AffectionEngine.mood(for: 1_999) == .sulking)
        #expect(AffectionEngine.mood(for: 2_000) == .distant)
        #expect(AffectionEngine.mood(for: 4_000) == .content)
        #expect(AffectionEngine.mood(for: 6_000) == .happy)
        #expect(AffectionEngine.mood(for: 8_000) == .adoring)
        #expect(AffectionEngine.displayValue(7_350) == 73)
    }

    @Test func careGainsMatchTheDesign() {
        #expect(AffectionEngine.afterPetting(points: 5_000) == 5_200)
        #expect(AffectionEngine.afterTreat(points: 5_000) == 6_200)
        // Five pets and two treats is a full day of care.
        var points: Int64 = 5_000
        for _ in 0..<AffectionEngine.maxPetsPerDay { points = AffectionEngine.afterPetting(points: points) }
        for _ in 0..<AffectionEngine.maxTreatsPerDay { points = AffectionEngine.afterTreat(points: points) }
        #expect(points == 5_000 + 1_000 + 2_400)
    }

    /// The bond only ever rises, and it keeps rising long after affection has
    /// filled, which is the point of counting care rather than reading it.
    @Test func bondLevelsFollowLifetimeCare() {
        #expect(BondEngine.level(forCareCount: 0) == .metRecently)
        #expect(BondEngine.level(forCareCount: 19) == .metRecently)
        #expect(BondEngine.level(forCareCount: 20) == .familiar)
        #expect(BondEngine.level(forCareCount: 59) == .familiar)
        #expect(BondEngine.level(forCareCount: 60) == .trusted)
        #expect(BondEngine.level(forCareCount: 150) == .close)
        #expect(BondEngine.level(forCareCount: 299) == .close)
        #expect(BondEngine.level(forCareCount: 300) == .inseparable)
        #expect(BondEngine.level(forCareCount: 10_000) == .inseparable)
        #expect(BondEngine.careToNextLevel(from: 0) == 20)
        #expect(BondEngine.careToNextLevel(from: 155) == 145)
        #expect(BondEngine.careToNextLevel(from: 300) == nil)
        // Every level's title is a distinct key, so none of them goes unnamed.
        #expect(Set(BondLevel.allCases.map(\.titleKey)).count == BondLevel.allCases.count)
    }
}
