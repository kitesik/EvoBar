import CoreGraphics
import CryptoKit
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct AnimationCoverageTests {
    @Test func babyStatePortraitsAreDistinctAndTransparent() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var hashes = Set<String>()
        for animal in catalog.animals {
            for state in [CompanionVisualState.idle, .working, .evolutionReady, .sleeping] {
                let reference = provider.asset(for: animal, stageIndex: 1, isShiny: false, visualState: state)
                let data = try #require(BundledAnimalSpriteStore.imageData(for: reference))
                let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
                let frame = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
                let rgba = pixels(of: frame)
                let hash = SHA256.hash(data: Data(rgba)).map { String(format: "%02x", $0) }.joined()
                #expect(hashes.insert(hash).inserted, "Duplicated baby state: \(reference.assetID)/\(state)")
                var visible = 0
                for y in 0..<frame.height {
                    for x in 0..<frame.width {
                        let alpha = rgba[(y * frame.width + x) * 4 + 3]
                        if alpha > 32 { visible += 1 }
                        if x < 8 || y < 8 || x >= frame.width - 8 || y >= frame.height - 8 {
                            #expect(alpha == 0, "Missing state portrait gutter: \(reference.assetID)/\(state)")
                        }
                    }
                }
                #expect(visible > 700)
                #expect(visible < frame.width * frame.height * 9 / 10)
            }
        }
        #expect(hashes.count == 40)
    }

    /// Shipping motion is deliberately hybrid: existing quadruped rigs plus
    /// independently drawn wing/biped phases. Every stage and colour must move.
    @Test func allVariantsHaveMotionWithoutBorrowingAnotherColour() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var variants = 0, authored = 0, procedural = 0
        for animal in catalog.animals {
            #expect(animal.hasShinyArtwork == true)
            for stage in animal.stages {
                for shiny in [false, true] {
                    let reference = provider.asset(for: animal, stageIndex: stage.index,
                                                   isShiny: shiny, visualState: .working)
                    let frames = BundledAnimalSpriteStore.motionData(for: reference)
                        .flatMap(AuthoredSpriteMotion.decodeFrames(from:)) ?? []
                    let locomotion = animal.locomotion ?? .walk
                    if locomotion != .walk || stage.index == 1 || animal.id == "cat" || animal.id == "dog" || animal.id == "fox" || animal.id == "capybara" || (animal.id == "mammoth" && stage.index <= 4) {
                        #expect(frames.count == 4, "Missing dedicated motion: \(reference.assetID)")
                        authored += 1
                    } else {
                        procedural += 1
                    }
                    for state in [CompanionVisualState.idle, .working, .evolutionReady] {
                        let profile = CompanionMotionProfile.resolve(qualityID: "balanced", visualState: state,
                            locomotion: locomotion, authoredFrameCount: frames.count)
                        #expect(profile.frameCount > 1 && profile.frameInterval != nil,
                                "Static variant: \(reference.assetID)/\(state)")
                    }
                    variants += 1
                }
            }
        }
        #expect(variants == 144)
        #expect(authored == 126)
        #expect(procedural == 18)
    }

    // Validate every strip that is actually bundled, including a partially
    // imported line. The separate strict completion gate below must be enabled
    // before claiming all normal/alternate-colour animation is finished.
    @Test func bundledMotionFramesAreDistinctSquareAndTransparent() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        var allFrameHashes = Set<String>()
        for animal in catalog.animals {
            for stage in animal.stages {
                for shiny in [false, true] {
                    let reference = provider.asset(for: animal, stageIndex: stage.index,
                                                   isShiny: shiny, visualState: .working)
                    guard let data = BundledAnimalSpriteStore.motionData(for: reference) else { continue }
                    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
                    let strip = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
                    #expect(strip.height >= 64 && strip.height <= 256, "\(reference.assetID) frame bounds")
                    #expect(strip.width == strip.height * 4, "\(reference.assetID) must have four square phases")
                    #expect([CGImageAlphaInfo.premultipliedFirst, .premultipliedLast, .first, .last].contains(strip.alphaInfo))
                    let frames = try #require(AuthoredSpriteMotion.decodeFrames(from: data))
                    #expect(frames.count == 4)
                    for (phase, frame) in frames.enumerated() {
                        #expect(frame.width == strip.height && frame.height == strip.height)
                        let rgba = pixels(of: frame)
                        let hash = SHA256.hash(data: Data(rgba)).map { String(format: "%02x", $0) }.joined()
                        #expect(allFrameHashes.insert(hash).inserted,
                                "Duplicated authored frame: \(reference.assetID), phase \(phase)")
                        var visible = 0, borderPixels = 0
                        for y in 0..<frame.height {
                            for x in 0..<frame.width {
                                let alpha = rgba[(y * frame.width + x) * 4 + 3]
                                if alpha > 32 { visible += 1 }
                                if (x < 8 || y < 8 || x >= frame.width - 8 || y >= frame.height - 8) && alpha > 0 {
                                    borderPixels += 1
                                }
                            }
                        }
                        #expect(borderPixels == 0, "Clipped phase or missing transparent gutter: \(reference.assetID)/\(phase)")
                        #expect(visible > 700, "Empty or undersized phase: \(reference.assetID)/\(phase)")
                        #expect(visible < frame.width * frame.height * 9 / 10, "Opaque phase background")
                    }
                }
            }
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["EVOBAR_REQUIRE_COMPLETE_ARTWORK"] == "1"))
    func allSeventyTwoFormsHaveBothAuthoredMotionVariants() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        #expect(catalog.animals.flatMap(\.stages).count == 72)
        var stripCount = 0
        for animal in catalog.animals {
            #expect(animal.hasShinyArtwork == true)
            for stage in animal.stages {
                for shiny in [false, true] {
                    let reference = provider.asset(for: animal, stageIndex: stage.index,
                                                   isShiny: shiny, visualState: .working)
                    let data = try #require(BundledAnimalSpriteStore.motionData(for: reference),
                                            "Missing dedicated strip: \(reference.assetID)")
                    let frames = try #require(AuthoredSpriteMotion.decodeFrames(from: data))
                    #expect(frames.count == 4)
                    stripCount += 1
                }
            }
        }
        #expect(stripCount == 144)
    }

    private func pixels(of image: CGImage) -> [UInt8] {
        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        rgba.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: image.width, height: image.height,
                                    bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return rgba
    }
}
