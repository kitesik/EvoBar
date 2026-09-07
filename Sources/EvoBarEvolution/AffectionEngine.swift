import EvoBarCore
import Foundation

/// How the companion currently feels about the user. Purely cosmetic: mood never
/// changes XP, evolution speed, or anything the user is working toward.
public enum AffectionMood: String, CaseIterable, Sendable {
    case sulking
    case distant
    case content
    case happy
    case adoring
}

/// Affection is stored in hundredths so a gentle daily decay stays exact in
/// integer arithmetic. Displayed values divide by `scale`.
public enum AffectionEngine {
    public static let scale: Int64 = 100
    public static let maximum: Int64 = 100 * scale
    public static let starting: Int64 = 50 * scale

    public static let petGain: Int64 = 2 * scale
    public static let treatGain: Int64 = 12 * scale
    /// 0.20 per neglected day.
    public static let decayPerDay: Int64 = 20
    /// A full day of grace before neglect counts at all.
    public static let graceDays: Int64 = 1

    public static let maxPetsPerDay = 5
    public static let maxTreatsPerDay = 2

    public static func mood(for points: Int64) -> AffectionMood {
        switch points {
        case (80 * scale)...: .adoring
        case (60 * scale)...: .happy
        case (40 * scale)...: .content
        case (20 * scale)...: .distant
        default: .sulking
        }
    }

    /// Affection as of `now`, decaying whole neglected days beyond the grace
    /// period. Partial days do not count, so the value only ever steps.
    public static func currentPoints(
        stored: Int64,
        updatedAt: Date?,
        now: Date = Date()
    ) -> Int64 {
        guard let updatedAt, now > updatedAt else { return clamp(stored) }
        let elapsedDays = Int64(now.timeIntervalSince(updatedAt) / 86_400)
        let neglected = max(0, elapsedDays - graceDays)
        guard neglected > 0 else { return clamp(stored) }
        return clamp(stored - neglected * decayPerDay)
    }

    public static func afterPetting(points: Int64) -> Int64 {
        clamp(points + petGain)
    }

    public static func afterTreat(points: Int64) -> Int64 {
        clamp(points + treatGain)
    }

    public static func clamp(_ points: Int64) -> Int64 {
        min(maximum, max(0, points))
    }

    /// Whole-number affection for display, 0 through 100.
    public static func displayValue(_ points: Int64) -> Int {
        Int(clamp(points) / scale)
    }
}
