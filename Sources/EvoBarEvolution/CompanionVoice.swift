import EvoBarCore
import Foundation

public enum VoiceOccasion: Sendable {
    /// The panel has just opened on the companion.
    case greeting
    case pet
    /// XP has just arrived.
    case growth
    /// A quiet moment while the panel stays open.
    case idle
}

/// Which line the companion says. The lines themselves are catalog strings,
/// so this only chooses a key: a nature has three idle lines and a reply to
/// petting, a state has lines of its own, an unhappy mood cuts in, and growth
/// has its own small set. `roll` is any integer; the same roll always gives
/// the same key, so a test can walk every one.
public enum CompanionVoice {
    public static let idleLinesPerNature = 3
    public static let growthLines = 3
    public static let sleepingLines = 2
    public static let workingLines = 2

    public static func key(
        nature: String,
        mood: AffectionMood,
        state: CompanionVisualState,
        occasion: VoiceOccasion,
        roll: Int
    ) -> String {
        let roll = abs(roll)
        switch occasion {
        case .growth:
            return "voice.growth.\(roll % growthLines)"
        case .pet:
            return mood == .sulking ? "voice.mood.sulking.pet" : "voice.\(nature).pet"
        case .greeting, .idle:
            switch state {
            case .sleeping:
                return "voice.state.sleeping.\(roll % sleepingLines)"
            case .evolutionReady:
                return "voice.state.ready.0"
            case .working:
                return roll % 3 == 0
                    ? "voice.state.working.\(roll % workingLines)"
                    : "voice.\(nature).\(roll % idleLinesPerNature)"
            case .idle:
                switch mood {
                case .sulking where roll % 2 == 0: return "voice.mood.sulking.0"
                case .distant where roll % 2 == 0: return "voice.mood.distant.0"
                default: return "voice.\(nature).\(roll % idleLinesPerNature)"
                }
            }
        }
    }
}
