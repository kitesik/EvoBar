import Foundation

/// How the menu bar cycles the companion's gait frames for a state and quality.
public struct CompanionMotionProfile: Equatable, Sendable {
    /// `nil` when the companion stands still (sleeping, power saver, fliers).
    public let gait: SpriteGait?
    /// Frames rendered per gait cycle; the timer steps through them in order.
    public let frameCount: Int
    public let frameInterval: TimeInterval?

    public init(gait: SpriteGait?, frameCount: Int, frameInterval: TimeInterval?) {
        self.gait = gait
        self.frameCount = frameCount
        self.frameInterval = frameInterval
    }

    public static let still = CompanionMotionProfile(gait: nil, frameCount: 1, frameInterval: nil)

    public static func resolve(
        qualityID: String,
        visualState: CompanionVisualState,
        locomotion: AnimalLocomotion = .walk,
        reduceMotion: Bool = false
    ) -> CompanionMotionProfile {
        // ponytail: fliers hold their pose in the menu bar; add a wing-beat once a flying sheet exists.
        guard !reduceMotion, qualityID != "powerSaver", visualState != .sleeping, locomotion == .walk else { return .still }
        let gait: SpriteGait = visualState == .working ? .trot : .walk
        let frameCount = qualityID == "smooth" ? 8 : 4
        return CompanionMotionProfile(
            gait: gait,
            frameCount: frameCount,
            frameInterval: gait.cycleDuration / Double(frameCount)
        )
    }
}
