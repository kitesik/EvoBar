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

/// A noise a companion makes, and whether it is happy enough to throw hearts
/// while it makes it. The cry belongs to the animal, not to the reader, so it
/// is the same in every language and lives here rather than in a catalog.
public struct CompanionSound: Equatable, Sendable {
    public let cry: String
    public let heart: Bool

    public init(cry: String, heart: Bool) {
        self.cry = cry
        self.heart = heart
    }
}

/// Which noise a companion makes. A line has five sets, and the moment picks
/// one: asleep, at work, sulking, pleased, or simply awake. `roll` is any
/// integer; the same roll always gives the same sound, so a test can walk
/// every one of them.
public enum CompanionVoice {
    struct Voice {
        let calm: [String]
        let happy: [String]
        let grumpy: [String]
        let sleeping: [String]
        let excited: [String]
    }

    public static func sound(
        animal: String,
        mood: AffectionMood,
        state: CompanionVisualState,
        occasion: VoiceOccasion,
        roll: Int
    ) -> CompanionSound {
        let voice = voices[animal] ?? fallback
        let roll = abs(roll)
        func pick(_ set: [String]) -> String { set[roll % set.count] }

        if occasion == .pet {
            return mood == .sulking
                ? CompanionSound(cry: pick(voice.grumpy), heart: false)
                : CompanionSound(cry: pick(voice.happy), heart: true)
        }
        if state == .sleeping {
            return CompanionSound(cry: pick(voice.sleeping), heart: false)
        }
        if occasion == .growth || state == .working || state == .evolutionReady {
            return CompanionSound(cry: pick(voice.excited), heart: false)
        }
        switch mood {
        case .sulking:
            return CompanionSound(cry: pick(voice.grumpy), heart: false)
        case .happy, .adoring:
            // Not every happy moment throws a heart, or they stop meaning anything.
            return CompanionSound(cry: pick(voice.happy), heart: roll % 3 == 0)
        case .distant, .content:
            return CompanionSound(cry: pick(voice.calm), heart: false)
        }
    }

    /// A line the catalog has but the table has not, so it is never silent.
    static let fallback = Voice(
        calm: ["...", "hm?"], happy: ["\u{266a}"], grumpy: ["hm."],
        sleeping: ["... zzz"], excited: ["!"])

    static let voices: [String: Voice] = [
        "cat": Voice(
            calm: ["meow...", "mrrp?", "nya~"],
            happy: ["purrrr...", "mrrow♪", "nyaa♪"],
            grumpy: ["grrr...", "hsss.", "mrow."],
            sleeping: ["mrr... zzz", "purr... zzz"],
            excited: ["meow! meow!", "mrrp!"]),
        "dog": Voice(
            calm: ["woof.", "bork?", "hrrf."],
            happy: ["woof woof♪", "arf arf!", "*tail thump*"],
            grumpy: ["grrrf...", "hrmph.", "wuf."],
            sleeping: ["snf... zzz", "hnnn... zzz"],
            excited: ["WOOF!", "arf! arf! arf!"]),
        "fox": Voice(
            calm: ["yip.", "kekeke", "awoo~"],
            happy: ["yip yip♪", "kkk♪", "awooo♪"],
            grumpy: ["grrk...", "hmf.", "yek."],
            sleeping: ["kurr... zzz", "fff... zzz"],
            excited: ["YIP!", "awoo! awoo!"]),
        "capybara": Voice(
            calm: ["wheek.", "hmmm...", "*chomp*"],
            happy: ["wheek wheek♪", "hmmm♪", "*happy chomp*"],
            grumpy: ["wheh.", "hbbb.", "*slow blink*"],
            sleeping: ["hoo... zzz", "wheee... zzz"],
            excited: ["wheek!", "*munch munch munch*"]),
        "raptor": Voice(
            calm: ["skree.", "kkkk...", "rrrak?"],
            happy: ["skree♪", "chrrp!", "kak kak♪"],
            grumpy: ["SKRAA.", "rrrr...", "tkk."],
            sleeping: ["krrr... zzz", "kek... zzz"],
            excited: ["SKREE! SKREE!", "kak! kak!"]),
        "mammoth": Voice(
            calm: ["hrrooo...", "*stomp*", "mrrm?"],
            happy: ["pawooo♪", "hroo hroo♪", "*gentle stomp*"],
            grumpy: ["HRRMPH.", "grooo...", "mrf."],
            sleeping: ["hrooo... zzz", "brrr... zzz"],
            excited: ["PAWOOO!", "hroo! hroo!"]),
        "pterosaur": Voice(
            calm: ["kraa.", "kik kik", "shree?"],
            happy: ["kraa♪", "shreee♪", "kikiki♪"],
            grumpy: ["KRAAA.", "sss...", "kek."],
            sleeping: ["krr... zzz", "shh... zzz"],
            excited: ["SHREEE!", "kraa! kraa!"]),
        "dragon": Voice(
            calm: ["grrrm...", "*smoke*", "rrroar?"],
            happy: ["rrrumble♪", "grm grm♪", "*warm puff*"],
            grumpy: ["ROAAR.", "hssss...", "grn."],
            sleeping: ["snrrk... zzz", "rumble... zzz"],
            excited: ["ROAR!", "grrrm! grrrm!"]),
        "phoenix": Voice(
            calm: ["kiii~", "*ember crackle*", "trill?"],
            happy: ["kiii♪", "trill trill♪", "*warm spark*"],
            grumpy: ["KII.", "fsss...", "tsk."],
            sleeping: ["kirr... zzz", "ember... zzz"],
            excited: ["KIII!", "trrr! trrr!"]),
        "kirin": Voice(
            calm: ["hnnn...", "*chime*", "rrring~"],
            happy: ["hnnn♪", "*chime chime*", "riii♪"],
            grumpy: ["hnn.", "tnn.", "*dull chime*"],
            sleeping: ["hnn... zzz", "chime... zzz"],
            excited: ["HNNN!", "*bright chime*"]),
    ]
}
