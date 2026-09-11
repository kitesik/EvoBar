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

    public init(base: Int64, bonus: Int64, coins: Int64, tier: GrowthBonusTier?) {
        self.base = base
        self.bonus = bonus
        self.coins = coins
        self.tier = tier
    }

    public var total: Int64 { base + bonus }
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
