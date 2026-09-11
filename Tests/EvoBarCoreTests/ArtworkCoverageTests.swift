import CoreGraphics
import CryptoKit
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct ArtworkCoverageTests {
    @Test(arguments: [false, true])
    func bundledFormsHaveFourDistinctTransparentPoses(isShiny: Bool) throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        let states: [CompanionVisualState] = [.idle, .working, .evolutionReady, .sleeping]
        var allHashes = Set<String>()
        #expect(catalog.animals.flatMap(\.stages).count == 72)
        #expect(catalog.animals.filter { $0.hasShinyArtwork == true }.map(\.id) == ["cat", "dog", "capybara", "mammoth"])
        for animal in catalog.animals where !isShiny || animal.hasShinyArtwork == true {
            #expect(BundledAnimalSpriteStore.hasArtwork(for: animal))
            for stage in animal.stages {
                #expect(stage.artworkPending != true)
                #expect(stage.normalAssetID == "\(animal.id.rawValue).\(stage.index)")
                for state in states {
                    let reference = provider.asset(for: animal, stageIndex: stage.index,
                                                   isShiny: isShiny, visualState: state)
                    let data = try #require(BundledAnimalSpriteStore.imageData(for: reference))
                    // Missing-state fallback and exact copies must fail coverage.
                    let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                    #expect(allHashes.insert(digest).inserted, "duplicate \(reference.assetID).\(state)")
                    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
                    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
                    #expect(image.width >= 64 && image.width <= 400)
                    #expect(image.height >= 64 && image.height <= 400)
                    var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
                    rgba.withUnsafeMutableBytes { bytes in
                        let context = CGContext(data: bytes.baseAddress, width: image.width, height: image.height,
                                                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                                space: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
                    }
                    var visible = 0, borderPixels = 0
                    for y in 0..<image.height {
                        for x in 0..<image.width {
                            let alpha = rgba[(y * image.width + x) * 4 + 3]
                            if alpha > 32 { visible += 1 }
                            if (x < 8 || y < 8 || x >= image.width - 8 || y >= image.height - 8) && alpha > 0 {
                                borderPixels += 1
                            }
                        }
                    }
                    #expect(borderPixels == 0, "missing transparent gutter \(reference.assetID).\(state)")
                    #expect(visible > 1_000)
                    #expect(visible < image.width * image.height * 9 / 10, "opaque background")
                }
            }
        }
        #expect(allHashes.count == (isShiny ? 112 : 288))
    }

    @Test func featheredBipedsNeverUseTheFourLeggedRig() throws {
        let animal = try #require(ManifestLoader.bundledCatalog().animals.first { $0.id == "raptor" })
        #expect(animal.locomotion == .biped)
        for quality in ["powerSaver", "balanced", "smooth"] {
            #expect(CompanionMotionProfile.resolve(qualityID: quality, visualState: .working,
                                                   locomotion: .biped) == .still)
        }
    }
}
