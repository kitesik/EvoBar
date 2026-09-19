import EvoBarCore
import Foundation
import Testing

@Suite struct CompanionMotionTests {
    @Test(arguments: [AnimalLocomotion.walk, .biped, .fly])
    func authoredFramesNeverUseTheQuadrupedRig(locomotion: AnimalLocomotion) throws {
        let idle = CompanionMotionProfile.resolve(qualityID: "balanced", visualState: .idle,
                                                 locomotion: locomotion, authoredFrameCount: 4)
        let working = CompanionMotionProfile.resolve(qualityID: "smooth", visualState: .working,
                                                    locomotion: locomotion, authoredFrameCount: 4)
        #expect(idle.usesAuthoredFrames && working.usesAuthoredFrames)
        #expect(idle.gait == nil && working.gait == nil)
        #expect(idle.frameCount == 4 && working.frameCount == 4)
        #expect(try #require(working.frameInterval) < #require(idle.frameInterval))
    }

    @Test func accessibilityPowerAndDisabledMotionKeepStatePoses() {
        for locomotion in [AnimalLocomotion.walk, .biped, .fly] {
            #expect(CompanionMotionProfile.resolve(qualityID: "powerSaver", visualState: .working,
                      locomotion: locomotion, authoredFrameCount: 4) == .still)
            #expect(CompanionMotionProfile.resolve(qualityID: "smooth", visualState: .sleeping,
                      locomotion: locomotion, authoredFrameCount: 4) == .still)
            #expect(CompanionMotionProfile.resolve(qualityID: "smooth", visualState: .working,
                      locomotion: locomotion, reduceMotion: true, authoredFrameCount: 4) == .still)
            #expect(CompanionMotionProfile.resolve(qualityID: "smooth", visualState: .working,
                      locomotion: locomotion, animationEnabled: false, authoredFrameCount: 4) == .still)
        }
    }

    @Test func absentOrMalformedStripPreservesFallback() {
        for count in [0, 1, 3, 5, 8] {
            let walker = CompanionMotionProfile.resolve(qualityID: "balanced", visualState: .working,
                                                       authoredFrameCount: count)
            #expect(!walker.usesAuthoredFrames)
            #expect(walker.gait == .trot && walker.frameCount == 8)
            for locomotion in [AnimalLocomotion.biped, .fly] {
                #expect(CompanionMotionProfile.resolve(qualityID: "balanced", visualState: .working,
                          locomotion: locomotion, authoredFrameCount: count) == .still)
            }
        }
    }

    @Test func sharedFrameSelectionWrapsAndRejectsInvalidTime() {
        let profile = CompanionMotionProfile(gait: nil, frameCount: 4, frameInterval: 0.25,
                                             usesAuthoredFrames: true)
        #expect((0..<8).map { profile.frameIndex(at: Double($0) * 0.25) } == [0, 1, 2, 3, 0, 1, 2, 3])
        for time in [-1.0, .infinity, -.infinity, .nan] {
            #expect(profile.frameIndex(at: time) == 0)
        }
        #expect(profile.frameIndex(at: 9_000_000_000.75) == 3)
        #expect(CompanionMotionProfile.still.frameIndex(at: 0.75) == 0)
        #expect(CompanionMotionProfile(gait: nil, frameCount: 4, frameInterval: 0)
            .frameIndex(at: 0.75) == 0)
    }
}
