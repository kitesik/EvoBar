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
                // From the belly line to the ground: a stubby capybara shows less than
                // a tenth of its height as leg, a tiger about a fifth, never over half.
                #expect(legRatio > 0.06 && legRatio < 0.5, "\(reference.assetID) leg ratio \(legRatio)")

                // Both legs of a pair must move, or the animal hops on two legs.
                #expect(analysis.legs[0].phase != analysis.legs[1].phase, "\(reference.assetID) hind pair")
                #expect(analysis.legs[2].phase != analysis.legs[3].phase, "\(reference.assetID) front pair")
                // Legs must sit side by side, hind before front.
                let pivots = analysis.drawnLegs.map(\.pivotX)
                #expect(pivots == pivots.sorted(), "\(reference.assetID) pivots \(pivots)")
                #expect(Set(pivots).count == pivots.count, "\(reference.assetID) legs share a pivot")
                // Ownership must cover the whole leg span, or a column belongs to
                // no leg, the body drops it, and a notch is cut out of the thigh.
                let owned = analysis.drawnLegs.map(\.columns).sorted { $0.lowerBound < $1.lowerBound }
                #expect(owned.first?.lowerBound == analysis.legSpan.lowerBound, "\(reference.assetID) left edge")
                #expect(owned.last?.upperBound == analysis.legSpan.upperBound, "\(reference.assetID) right edge")
                for (earlier, later) in zip(owned, owned.dropFirst()) {
                    #expect(earlier.upperBound >= later.lowerBound - 1, "\(reference.assetID) gap in ownership")
                }

                let cycle = try #require(SpriteGaitRenderer.frames(from: image, gait: .trot, frameCount: 8))
                #expect(cycle.frames.count == 8)
                #expect(cycle.frames.allSatisfy { $0.width == image.width && $0.height == image.height })
                #expect(cycle.metrics.legHeightFraction > 0.05)
            }
        }
        #expect(analysed == 20)
    }

    /// Posing must move the companion, not eat it. Inverse mapping gives every
    /// destination pixel one lookup, so a frame keeps essentially all of the
    /// drawing; anything much lower means a limb was cut away or left a hole.
    @Test func posedFramesKeepTheWholeDrawing() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var checked = 0
        for animal in catalog.animals where animal.locomotion != .fly {
            for stage in animal.stages {
                for state in [CompanionVisualState.idle, .working] {
                    let reference = provider.asset(
                        for: animal,
                        stageIndex: stage.index,
                        isShiny: false,
                        visualState: state
                    )
                    guard let data = BundledAnimalSpriteStore.imageData(for: reference),
                          let source = CGImageSourceCreateWithData(data as CFData, nil),
                          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                          let cycle = SpriteGaitRenderer.frames(
                              from: image,
                              gait: .trot,
                              pose: state == .working ? .running : .standing,
                              frameCount: 6
                          )
                    else { continue }
                    let frames = cycle.frames
                    checked += 1
                    let original = opaquePixels(image)
                    for (index, frame) in frames.enumerated() {
                        let kept = Double(opaquePixels(frame)) / Double(original)
                        #expect(kept > 0.9, "\(reference.assetID).\(state.rawValue) frame \(index) kept \(kept)")
                        #expect(kept < 1.25, "\(reference.assetID).\(state.rawValue) frame \(index) grew \(kept)")
                    }
                }
            }
        }
        #expect(checked == 40)
    }

    /// The feet lead and the body follows them down, so at every moment some
    /// foot stands on the ground line the sprite was drawn with. Without the
    /// body dropping, a long stride pulls every planted foot up at the ends of
    /// its stance and the animal skates above the ground.
    @Test(arguments: SpriteGait.allCases)
    func someFootAlwaysStandsOnTheGround(gait: SpriteGait) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var checked = 0
        for animal in catalog.animals where animal.locomotion != .fly {
            for stage in animal.stages {
                let reference = provider.asset(for: animal, stageIndex: stage.index, isShiny: false, visualState: .idle)
                guard let data = BundledAnimalSpriteStore.imageData(for: reference),
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      let analysis = SpriteGaitRenderer.analyze(image, gait: gait),
                      let cycle = SpriteGaitRenderer.frames(from: image, gait: gait, frameCount: 8)
                else { continue }
                checked += 1
                for (index, frame) in cycle.frames.enumerated() {
                    let lowest = lowestOpaqueRow(frame)
                    #expect(
                        lowest >= analysis.groundY - 1,
                        "\(reference.assetID) frame \(index) floats at \(lowest), ground \(analysis.groundY)"
                    )
                }
            }
        }
        #expect(checked == 20)
    }

    private func opaquePixels(_ image: CGImage) -> Int {
        alpha(of: image).count { $0 > 8 }
    }

    private func lowestOpaqueRow(_ image: CGImage) -> Int {
        let alpha = alpha(of: image)
        return alpha.indices.last { alpha[$0] > 8 }.map { $0 / image.width } ?? -1
    }

    /// Alpha of every pixel, rows top to bottom.
    private func alpha(of image: CGImage) -> [UInt8] {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            )?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
    }

    /// Fenrir's sheet carries a fragment of the next cell below its paws. The
    /// ground must come from the animal, not from a detached speck.
    @Test func straySpecksDoNotSetTheGround() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        let animal = try #require(catalog.animals.first { $0.id == AnimalDefinitionID(rawValue: "dog") })
        let reference = provider.asset(for: animal, stageIndex: 5, isShiny: false, visualState: .idle)
        let data = try #require(BundledAnimalSpriteStore.imageData(for: reference))
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let analysis = try #require(SpriteGaitRenderer.analyze(image, gait: .walk))
        #expect(analysis.groundY < image.height - 10, "ground \(analysis.groundY) of \(image.height)")
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
