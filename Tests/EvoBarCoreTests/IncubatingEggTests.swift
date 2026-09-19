import EvoBarCore
import Foundation
import Testing

struct IncubatingEggTests {
    @Test func focusPrefersReadyThenNearestAndIsStable() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let young = IncubatingEgg(placedAt: date, activeDays: 0)
        let nearer = IncubatingEgg(placedAt: date.addingTimeInterval(10), activeDays: 2)
        let ready = IncubatingEgg(placedAt: date.addingTimeInterval(20), activeDays: 3)
        let olderReady = IncubatingEgg(placedAt: date.addingTimeInterval(-10), activeDays: 3)
        #expect(IncubatingEgg.focus(in: []) == nil)
        #expect(IncubatingEgg.focus(in: [young, nearer]) == nearer)
        #expect(IncubatingEgg.focus(in: [nearer, young, ready]) == ready)
        #expect(IncubatingEgg.focus(in: [ready, olderReady, nearer]) == olderReady)
        #expect(IncubatingEgg.focus(in: [nearer, olderReady, ready]) == olderReady)
    }

    @Test func outOfOrderDaysCountOnlyOnceAndSurviveEncoding() throws {
        var egg = IncubatingEgg()
        for day in ["2026-09-19", "2026-09-17", "2026-09-19", "2026-09-17", ""] {
            egg.count(dayKey: day)
        }
        #expect(egg.activeDays == 2)
        #expect(!egg.isReady)
        egg = try JSONDecoder().decode(IncubatingEgg.self, from: JSONEncoder().encode(egg))
        egg.count(dayKey: "2026-09-19")
        #expect(egg.activeDays == 2)
        egg.count(dayKey: "2026-09-18")
        #expect(egg.isReady)
        egg.count(dayKey: "2026-09-20")
        #expect(egg.countedDayKeys?.count == 3)
    }

    @Test func legacyEggRestoresDaysWithoutTakingBackProgress() throws {
        let original = IncubatingEgg(activeDays: 2, lastCountedDayKey: "2026-09-19")
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object.removeValue(forKey: "countedDayKeys")
        var restored = try JSONDecoder().decode(IncubatingEgg.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(restored.countedDayKeys == nil)
        restored.restoreCountedDays(["2026-09-17", "2026-09-19"])
        restored.count(dayKey: "2026-09-17")
        #expect(restored.activeDays == 2)
        restored.count(dayKey: "2026-09-18")
        #expect(restored.isReady)
    }
}
