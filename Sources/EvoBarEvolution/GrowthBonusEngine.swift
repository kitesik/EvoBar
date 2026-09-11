import EvoBarCore
import Foundation

/// What landed when the companion took in the XP that had been waiting for it.
public struct GrowthAbsorption: Equatable, Sendable {
    /// XP the work had earned.
    public let base: Int64
    /// XP a lucky or golden roll added on top.
    public let bonus: Int64
    /// Token Coins a golden roll dropped.
    public let coins: Int64
    public let tier: GrowthBonusTier?
    /// Set only on the first arrival of a growth day.
    public let gift: DailyGift?

    public init(
        base: Int64, bonus: Int64, coins: Int64, tier: GrowthBonusTier?, gift: DailyGift? = nil
    ) {
        self.base = base
        self.bonus = bonus
        self.coins = coins
        self.tier = tier
        self.gift = gift
    }

    /// Every XP point that lands in this one sweep, the gift's included.
    public var total: Int64 { base + bonus + (gift?.xp ?? 0) }

    public func with(gift: DailyGift?) -> GrowthAbsorption {
        GrowthAbsorption(base: base, bonus: bonus, coins: coins, tier: tier, gift: gift)
    }
}

/// What the first growth of a day brought with it.
public struct DailyGift: Equatable, Sendable {
    public let coins: Int64
    /// A Rare Candy's worth of XP, or zero.
    public let xp: Int64
    /// A Random Egg, or none.
    public let eggs: Int

    public init(coins: Int64, xp: Int64, eggs: Int) {
        self.coins = coins
        self.xp = xp
        self.eggs = eggs
    }
}

/// The first growth of a day brings something, always. It is the one draw a day
/// that is paced by the calendar rather than by how the work happened to split,
/// so it cannot be farmed by opening the panel more often, and every outcome
/// adds: coins on the quiet days, a candy's worth of XP on many, and now and
/// then an egg, which is what turns the collection over.
///
/// Nothing here rerolls or replaces anything the user chose: a Mint would
/// change a nature the user can now see, hear and grow attached to, so the gift
/// never carries one.
public enum DailyGiftEngine {
    public static let leastCoins: Int64 = 2
    public static let mostCoins: Int64 = 5
    public static let candyChance = 0.18
    public static let eggChance = 0.04

    /// Each roll is uniform in 0 ..< 1. `candyXP` is the Rare Candy's listed XP,
    /// so the gift follows the economy manifest rather than a second number.
    public static func gift(coinRoll: Double, itemRoll: Double, candyXP: Int64) -> DailyGift {
        let span = mostCoins - leastCoins + 1
        let unit = min(max(coinRoll, 0), 0.999_999)
        let coins = leastCoins + Int64(Double(span) * unit)
        if itemRoll < eggChance {
            return DailyGift(coins: coins, xp: 0, eggs: 1)
        }
        if itemRoll < eggChance + candyChance {
            return DailyGift(coins: coins, xp: max(0, candyXP), eggs: 0)
        }
        return DailyGift(coins: coins, xp: 0, eggs: 0)
    }
}

public enum GrowthBonusTier: String, Sendable {
    case lucky
    case golden
}

/// Chance on top of certainty. Everything the work earned arrives in full and a
/// roll can only add to it, never take from it, so opening the panel is a small
/// draw with no losing ticket. The bonus is a share of what arrived, so opening
/// the panel more often changes nothing: the extra averages about a tenth of
/// all growth however the XP is split into arrivals.
public enum GrowthBonusEngine {
    public static let goldenChance = 0.03
    public static let luckyChance = 0.15
    public static let goldenCoins: Int64 = 3

    /// `roll` is uniform in 0 ..< 1.
    public static func absorption(of base: Int64, roll: Double) -> GrowthAbsorption {
        // A bonus that rounds to nothing would still be announced as one.
        guard base >= 2 else { return GrowthAbsorption(base: base, bonus: 0, coins: 0, tier: nil) }
        if roll < goldenChance {
            return GrowthAbsorption(base: base, bonus: base, coins: goldenCoins, tier: .golden)
        }
        if roll < goldenChance + luckyChance {
            return GrowthAbsorption(base: base, bonus: base / 2, coins: 0, tier: .lucky)
        }
        return GrowthAbsorption(base: base, bonus: 0, coins: 0, tier: nil)
    }

    /// A Rare Candy is worth about its listed XP: two thirds to four thirds of it.
    public static func candyGrant(mean: Int64, roll: Double) -> Int64 {
        let low = mean * 2 / 3
        let span = max(0, mean * 4 / 3 - low)
        let unit = min(max(roll, 0), 0.999_999)
        return low + Int64((Double(span) * unit).rounded(.down))
    }
}
