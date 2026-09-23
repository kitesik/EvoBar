import CoreGraphics
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct SpriteGaitTests {
    /// Every illustrated walking companion must yield a usable gait from its standing pose.
    @Test(arguments: [false, true])
    func standingSpritesYieldFourLegs(isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var analysed = 0
        var seen = Set<String>()
        for animal in catalog.animals where (animal.locomotion ?? .walk) == .walk && (!isShiny || animal.hasShinyArtwork == true) {
            for stage in animal.stages {
                let reference = provider.asset(for: animal, stageIndex: stage.index, isShiny: isShiny, visualState: .idle)
                guard seen.insert(reference.assetID).inserted else { continue }
                guard let data = BundledAnimalSpriteStore.imageData(for: reference),
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
                analysed += 1
                let analysis = try #require(SpriteGaitRenderer.analyze(image, gait: .walk), "\(reference.assetID)")
                #expect(analysis.legs.count == 4, "\(reference.assetID) legs \(analysis.legs.map(\.columns))")
                // Measure anatomy, not PNG padding/export haze. Transparent
                // margins must not change whether a leg is considered usable.
                let legRatio = Double(analysis.legHeight) / Double(max(1, analysis.bodyHeight))
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
        #expect(analysed == 35)
    }

    /// Posing must move the companion, not eat it. Every piece is drawn row by
    /// row from its whole source row, so a frame keeps nearly all of the
    /// drawing; a lifted leg is squeezed shorter and a leaning haunch narrower,
    /// which costs a trotting tiger a tenth at the ends of its stride. Anything
    /// much lower means a limb was cut away or left a hole.
    @Test(arguments: [false, true])
    func posedFramesKeepTheWholeDrawing(isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var checked = 0
        var seen = Set<String>()
        for animal in catalog.animals where (animal.locomotion ?? .walk) == .walk && (!isShiny || animal.hasShinyArtwork == true) {
            for stage in animal.stages {
                for state in [CompanionVisualState.idle, .working] {
                    let reference = provider.asset(
                        for: animal,
                        stageIndex: stage.index,
                        isShiny: isShiny,
                        visualState: state
                    )
                    guard seen.insert("\(reference.assetID).\(state.rawValue)").inserted else { continue }
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
                        #expect(kept > 0.85, "\(reference.assetID).\(state.rawValue) frame \(index) kept \(kept)")
                        #expect(kept < 1.25, "\(reference.assetID).\(state.rawValue) frame \(index) grew \(kept)")
                    }
                }
            }
        }
        #expect(checked == 70)
    }

    /// The feet lead and the body follows them down, so at every moment some
    /// foot stands on the ground line the sprite was drawn with. Without the
    /// body dropping, a long stride pulls every planted foot up at the ends of
    /// its stance and the animal skates above the ground.
    @Test(arguments: SpriteGait.allCases, [false, true])
    func someFootAlwaysStandsOnTheGround(gait: SpriteGait, isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var checked = 0
        var seen = Set<String>()
        for animal in catalog.animals where (animal.locomotion ?? .walk) == .walk && (!isShiny || animal.hasShinyArtwork == true) {
            for stage in animal.stages {
                let reference = provider.asset(for: animal, stageIndex: stage.index, isShiny: isShiny, visualState: .idle)
                guard seen.insert(reference.assetID).inserted else { continue }
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
        #expect(checked == 35)
    }

    /// The hind feet must swing as far as the front feet. Posing only what hangs
    /// below the belly line left the haunch still and the hind paws sliding a
    /// few pixels, which is what the owner saw as legs that did not move: the
    /// rearmost and foremost paw edges must each travel most of a stride.
    @Test func hindAndFrontFeetTravelTheStride() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        for (animalID, stage) in [("cat", 4), ("dog", 4), ("capybara", 2), ("fox", 2)] {
            let animal = try #require(catalog.animals.first { $0.id == AnimalDefinitionID(rawValue: animalID) })
            let reference = provider.asset(for: animal, stageIndex: stage, isShiny: false, visualState: .idle)
            let data = try #require(BundledAnimalSpriteStore.imageData(for: reference))
            let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
            let analysis = try #require(SpriteGaitRenderer.analyze(image, gait: .walk))
            let cycle = try #require(SpriteGaitRenderer.frames(from: image, gait: .walk, frameCount: 16))
            var rear: [Int] = [], front: [Int] = []
            for frame in cycle.frames {
                let alpha = alpha(of: frame)
                var leftmost = frame.width, rightmost = -1
                for y in (analysis.groundY - 3)...analysis.groundY {
                    for x in 0..<frame.width where alpha[y * frame.width + x] > 8 {
                        leftmost = min(leftmost, x)
                        rightmost = max(rightmost, x)
                    }
                }
                rear.append(leftmost)
                front.append(rightmost)
            }
            let stride = 2 * SpriteGait.walk.strideFraction * Double(analysis.strideLength)
            let rearTravel = Double(rear.max()! - rear.min()!)
            let frontTravel = Double(front.max()! - front.min()!)
            // Each edge is the envelope of two paws in opposite phase, so when
            // the pair stands close together, as a fox's front paws do, the
            // envelope moves less than either paw; and a tail hanging to the
            // ground behind the hind paws, as the fox's does, is the rear edge
            // itself and only sways with the haunch.
            #expect(rearTravel > 0.4 * stride, "\(reference.assetID) rear paw travels \(rearTravel) of \(stride)")
            #expect(frontTravel > 0.3 * stride, "\(reference.assetID) front paw travels \(frontTravel) of \(stride)")
            // The stride is measured from the joint, so it is far longer than the
            // visible leg: a lynx whose belly line leaves a quarter of its height
            // as leg swings its paws through more than half that leg height.
            #expect(stride > 1.2 * Double(analysis.legHeight), "\(reference.assetID) stride \(stride) for leg \(analysis.legHeight)")
        }
    }

    /// Posing moves the drawing; it must never break it up. A paw that snaps
    /// off ahead of the body, a leg stretched into a detached blade, a slab of
    /// belly left behind: whatever the cause, each of them shows up as pixels
    /// that no longer touch the rest of the animal. Some sheets do draw
    /// separate pieces on purpose, floating leaves and sparkles and a tail tip
    /// clear of the rump, so the bar is the sheet's own wholeness, not a fixed
    /// number: a frame may be no more broken up than the artist drew it.
    @Test(arguments: SpriteGait.allCases, [false, true])
    func posingNeverBreaksTheDrawingUp(gait: SpriteGait, isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var checked = 0
        var seen = Set<String>()
        for animal in catalog.animals where (animal.locomotion ?? .walk) == .walk && (!isShiny || animal.hasShinyArtwork == true) {
            for stage in animal.stages {
                for state in [CompanionVisualState.idle, .working] {
                    let reference = provider.asset(
                        for: animal, stageIndex: stage.index, isShiny: isShiny, visualState: state)
                    guard seen.insert("\(reference.assetID).\(state.rawValue).\(gait.rawValue)").inserted else { continue }
                    guard let data = BundledAnimalSpriteStore.imageData(for: reference),
                          let source = CGImageSourceCreateWithData(data as CFData, nil),
                          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                          let cycle = SpriteGaitRenderer.frames(
                              from: image, gait: gait,
                              pose: state == .working ? .running : .standing, frameCount: 8)
                    else { continue }
                    checked += 1
                    let drawn = largestPieceShare(image)
                    for (index, frame) in cycle.frames.enumerated() {
                        let posed = largestPieceShare(frame)
                        #expect(
                            posed > drawn - 0.005,
                            "\(reference.assetID).\(state.rawValue) frame \(index) holds \(posed) of itself, drawn \(drawn)"
                        )
                    }
                }
            }
        }
        #expect(checked == 70)
    }

    /// Share of the opaque pixels that belong to the single largest run of
    /// pixels touching one another, corners included.
    private func largestPieceShare(_ image: CGImage) -> Double {
        let width = image.width, height = image.height
        let alpha = alpha(of: image)
        var solid = [Bool](repeating: false, count: width * height)
        var total = 0
        for index in 0..<(width * height) where alpha[index] > 8 {
            solid[index] = true
            total += 1
        }
        guard total > 0 else { return 1 }
        var seen = [Bool](repeating: false, count: width * height)
        var best = 0
        var stack: [Int] = []
        for start in 0..<(width * height) where solid[start] && !seen[start] {
            var size = 0
            seen[start] = true
            stack.append(start)
            while let index = stack.popLast() {
                size += 1
                let (x, y) = (index % width, index / width)
                for dy in -1...1 {
                    for dx in -1...1 where dx != 0 || dy != 0 {
                        let (nx, ny) = (x + dx, y + dy)
                        guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                        let neighbour = ny * width + nx
                        guard solid[neighbour], !seen[neighbour] else { continue }
                        seen[neighbour] = true
                        stack.append(neighbour)
                    }
                }
            }
            best = max(best, size)
        }
        return Double(best) / Double(total)
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
    @Test(arguments: [false, true])
    func straySpecksDoNotSetTheGround(isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        let animal = try #require(catalog.animals.first { $0.id == AnimalDefinitionID(rawValue: "dog") })
        // Fenrir is the seventh stage since the ladder grew.
        let reference = provider.asset(for: animal, stageIndex: 7, isShiny: isShiny, visualState: .idle)
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
