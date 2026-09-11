import Foundation

/// An egg warming in the incubator. It grows on the days its owner works, not
/// on the days that merely pass, so it cannot be waited out by leaving the app
/// open over a weekend, and it cannot be lost by taking one off either.
///
/// The reveal used to happen only at graduation, which is weeks apart, so the
/// hatch was the rarest moment in the app. An egg placed here brings one every
/// few working days instead, and what it holds is still unknown until it opens.
public struct IncubatingEgg: Codable, Equatable, Identifiable, Sendable {
    /// Growth days of actual usage an egg needs.
    public static let activeDaysToHatch = 3
    /// How many can warm at once. More than this and the reveal stops being one.
    public static let capacity = 3

    public let id: UUID
    public let placedAt: Date
    /// Growth days with usage counted so far.
    public var activeDays: Int
    /// The growth day the last one was counted on, so a day counts once however
    /// many times usage arrives in it.
    public var lastCountedDayKey: String

    public init(
        id: UUID = UUID(),
        placedAt: Date = Date(),
        activeDays: Int = 0,
        lastCountedDayKey: String = ""
    ) {
        self.id = id
        self.placedAt = placedAt
        self.activeDays = activeDays
        self.lastCountedDayKey = lastCountedDayKey
    }

    public var isReady: Bool { activeDays >= Self.activeDaysToHatch }
    public var daysRemaining: Int { max(0, Self.activeDaysToHatch - activeDays) }

    /// Counts today, if today has not been counted for this egg already.
    public mutating func count(dayKey: String) {
        guard lastCountedDayKey != dayKey else { return }
        lastCountedDayKey = dayKey
        activeDays = min(Self.activeDaysToHatch, activeDays + 1)
    }
}

extension AnimalInstance {
    /// Hatched, named after its line, and waiting to be raised: not the
    /// companion growing now, not one that has graduated, and one that has
    /// never been raised at all. The last part matters because an individual
    /// set aside some other way has a stage and XP of its own to lose.
    public var isWaitingToBeRaised: Bool {
        !isCurrent && graduatedAt == nil && currentXP == 0 && acknowledgedStageIndex <= 1
    }

    /// Raised for a while and then set aside so another could grow. It keeps
    /// everything it earned and can be picked up again at any time; only
    /// graduation retires a companion for good.
    public var isResting: Bool {
        !isCurrent && graduatedAt == nil && !isWaitingToBeRaised
    }

    /// Neither growing now nor retired: it can be made the one that grows.
    public var canBeRaisedNext: Bool { !isCurrent && graduatedAt == nil }
}
