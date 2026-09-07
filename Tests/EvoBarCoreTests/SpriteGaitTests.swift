import CoreGraphics
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct SpriteGaitTests {
    /// Every illustrated walking companion must yield a usable gait from its standing pose.
    @Test func standingSpritesYieldFourLegs() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var analysed = 0
        for animal in catalog.animals where animal.locomotion != .fly {
            for stage in animal.stages {
                let reference = provider.asset(for: animal, stageIndex: stage.index, isShiny: false, visualState: .idle)
                guard let data = BundledAnimalSpriteStore.imageData(for: reference),
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
                analysed += 1
                let analysis = try #require(SpriteGaitRenderer.analyze(image, gait: .walk), "\(reference.assetID)")
                #expect(analysis.legs.count == 4, "\(reference.assetID) legs \(analysis.legs.map(\.columns))")
                let legRatio = Double(analysis.legHeight) / Double(image.height)
                // Whole legs, not just paws: a quadruped's lower leg is a fifth to a half of its height.
                #expect(legRatio > 0.15 && legRatio < 0.5, "\(reference.assetID) leg ratio \(legRatio)")

                let frames = try #require(SpriteGaitRenderer.frames(from: image, gait: .trot, frameCount: 8))
                #expect(frames.count == 8)
                #expect(frames.allSatisfy { $0.width == image.width && $0.height == image.height })
            }
        }
        #expect(analysed == 20)
    }

    @Test func gaitsHaveDistinctFootfallPatterns() {
        #expect(SpriteGait.trot.cycleDuration < SpriteGait.walk.cycleDuration)
        #expect(SpriteGait.trot.phases == [0, 0.5, 0.5, 0])
        #expect(SpriteGait.walk.phases == [0, 0.5, 0.25, 0.75])
    }

    /// A planted foot must travel backward and a lifted foot forward, or the
    /// animal moonwalks against the scrolling ground.
    @Test(arguments: SpriteGait.allCases)
    func plantedFeetSlideBackAndLiftedFeetSwingForward(gait: SpriteGait) {
        let stance = gait.stanceFraction
        let touchdown = gait.footState(at: 0)
        let liftoff = gait.footState(at: stance - 0.001)
        #expect(touchdown.forward > 0.99 && touchdown.lift == 0)
        #expect(liftoff.forward < -0.99 && liftoff.lift == 0)

        let midStance = gait.footState(at: stance / 2)
        #expect(abs(midStance.forward) < 0.01 && midStance.lift == 0)

        let midSwing = gait.footState(at: stance + (1 - stance) / 2)
        #expect(abs(midSwing.forward) < 0.01 && midSwing.lift > 0.99)

        var previous = gait.footState(at: stance)
        for step in 1...20 {
            let next = gait.footState(at: stance + (1 - stance) * Double(step) / 21)
            #expect(next.forward > previous.forward, "swing must move forward monotonically")
            previous = next
        }
        #expect(gait.footState(at: 1.25).forward == gait.footState(at: 0.25).forward)
    }
}
