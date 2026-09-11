import EvoBarCore
import Foundation

/// How far the two of you have come, as against how the companion feels today.
///
/// Affection fills in about three days of ordinary care and then has nowhere to
/// go, which left the five hearts at their top for the rest of a companion's
/// life. This counts every act of care it ever received instead, so it only
/// ever rises, a neglected week costs nothing already earned, and there is
/// still something ahead on the hundredth day.
public enum BondLevel: Int, CaseIterable, Sendable, Comparable {
    case metRecently
    case familiar
    case trusted
    case close
    case inseparable

    /// Acts of care needed to reach each level. A full day is at most eight:
    /// five pettings, two treats and the day's first growth.
    public var careNeeded: Int {
        switch self {
        case .metRecently: 0
        case .familiar: 20
        case .trusted: 60
        case .close: 150
        case .inseparable: 300
        }
    }

    public var titleKey: String { "bond.\(rawValue)" }

    public static func < (lhs: BondLevel, rhs: BondLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum BondEngine {
    public static func level(forCareCount count: Int) -> BondLevel {
        BondLevel.allCases.last { count >= $0.careNeeded } ?? .metRecently
    }

    /// Acts of care still to give before the next level, or nil at the top.
    public static func careToNextLevel(from count: Int) -> Int? {
        guard let next = BondLevel.allCases.first(where: { count < $0.careNeeded }) else { return nil }
        return next.careNeeded - count
    }
}
