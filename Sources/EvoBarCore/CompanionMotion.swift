import Foundation

/// Shared motion policy for the menu bar, Home and floating companion.
public struct CompanionMotionProfile: Equatable, Sendable {
    /// Only procedural quadrupeds use a rig. Authored frames are never rigged.
    public let gait: SpriteGait?
    /// Frames rendered per gait cycle; the timer steps through them in order.
    public let frameCount: Int
    public let frameInterval: TimeInterval?
    public let usesAuthoredFrames: Bool

    public init(gait: SpriteGait?, frameCount: Int, frameInterval: TimeInterval?, usesAuthoredFrames: Bool = false) {
        self.gait = gait
        self.frameCount = frameCount
        self.frameInterval = frameInterval
        self.usesAuthoredFrames = usesAuthoredFrames
    }

    public static let still = CompanionMotionProfile(gait: nil, frameCount: 1, frameInterval: nil)

    public static func resolve(
        qualityID: String,
        visualState: CompanionVisualState,
        locomotion: AnimalLocomotion = .walk,
        reduceMotion: Bool = false,
        animationEnabled: Bool = true,
        authoredFrameCount: Int = 0
    ) -> CompanionMotionProfile {
        guard animationEnabled, !reduceMotion, qualityID != "powerSaver", visualState != .sleeping else { return .still }
        if authoredFrameCount == AuthoredSpriteMotion.frameCount {
            let duration: TimeInterval = visualState == .working ? 0.48 : 1.2
            return CompanionMotionProfile(gait: nil, frameCount: authoredFrameCount,
                                          frameInterval: duration / Double(authoredFrameCount),
                                          usesAuthoredFrames: true)
        }
        guard locomotion == .walk else { return .still }
        let gait: SpriteGait = visualState == .working ? .trot : .walk
        // Four frames a cycle read as a march; eight is the least that reads as a walk.
        let frameCount = qualityID == "smooth" ? 12 : 8
        return CompanionMotionProfile(
            gait: gait,
            frameCount: frameCount,
            frameInterval: gait.cycleDuration / Double(frameCount)
        )
    }

    /// Safe wraparound shared by every surface, including paused/static output.
    /// Reduce the time to one cycle before converting it to an integer so large
    /// wall-clock values cannot overflow the frame index.
    public func frameIndex(at elapsedTime: TimeInterval) -> Int {
        guard frameCount > 1, let frameInterval, frameInterval.isFinite,
              frameInterval > 0, elapsedTime.isFinite, elapsedTime >= 0 else { return 0 }
        let duration = frameInterval * Double(frameCount)
        guard duration.isFinite, duration > 0 else { return 0 }
        let phase = elapsedTime.truncatingRemainder(dividingBy: duration)
        return min(frameCount - 1, max(0, Int(phase / frameInterval)))
    }
}
