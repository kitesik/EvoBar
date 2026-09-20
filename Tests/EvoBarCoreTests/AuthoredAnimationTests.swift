import CoreGraphics
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct AuthoredAnimationTests {
    @Test func stripGeometryIsFourEqualSquaresWithoutOverflow() throws {
        let rects = try #require(AuthoredSpriteMotion.frameRects(width: 1_024, height: 256))
        #expect(rects.count == 4)
        #expect(rects.map(\.minX) == [0, 256, 512, 768])
        #expect(rects.allSatisfy { $0.width == 256 && $0.height == 256 && $0.minY == 0 })
        for dimensions in [(256, 256), (1_023, 256), (64, 0), (60, 15), (2_048, 512), (8_192, 2_048), (Int.max, Int.max)] {
            #expect(AuthoredSpriteMotion.frameRects(width: dimensions.0, height: dimensions.1) == nil)
        }
    }

    @Test func decoderSplitsFourDistinctFramesInLeftToRightOrder() throws {
        let frames = try #require(AuthoredSpriteMotion.decodeFrames(from: png(width: 64, height: 16)))
        #expect(frames.count == 4)
        #expect(frames.allSatisfy { $0.width == 16 && $0.height == 16 })
        var redValues: [UInt8] = []
        for image in frames {
            var pixel = [UInt8](repeating: 0, count: 4)
            try pixel.withUnsafeMutableBytes { bytes in
                let context = try #require(CGContext(data: bytes.baseAddress, width: 1, height: 1,
                    bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            redValues.append(pixel[0])
        }
        #expect(Set(redValues).count == 4)
        #expect(redValues == redValues.sorted())
    }

    @Test func malformedImagesDoNotBecomeAnimation() throws {
        #expect(AuthoredSpriteMotion.decodeFrames(from: Data()) == nil)
        #expect(AuthoredSpriteMotion.decodeFrames(from: Data("not an image".utf8)) == nil)
        #expect(AuthoredSpriteMotion.decodeFrames(from: try png(width: 16, height: 16)) == nil)
        #expect(AuthoredSpriteMotion.decodeFrames(from: try png(width: 63, height: 16)) == nil)
        let missing = AnimalAssetReference(assetID: "missing-animation-test.shiny", fallbackEmoji: "", visualState: .working)
        #expect(BundledAnimalSpriteStore.motionData(for: missing) == nil)
    }

    @Test func presentationIgnoresDistantHazeWithoutChangingPhaseAlignment() throws {
        let clean = try (0..<4).map { try phaseImage(phase: $0, haze: false) }
        let hazy = try (0..<4).map { try phaseImage(phase: $0, haze: true) }
        let crop = try #require(AuthoredSpriteMotion.presentationCrop(for: hazy))
        #expect(crop == AuthoredSpriteMotion.presentationCrop(for: clean))
        #expect(crop.width == crop.height && crop.width < 64)
        let presented = try #require(AuthoredSpriteMotion.presentationFrames(from: hazy))
        #expect(presented.count == 4)
        #expect(presented.allSatisfy { $0.width == Int(crop.width) && $0.height == Int(crop.height) })
        for phase in 0..<4 {
            let source = try pixels(hazy[phase])
            let target = try pixels(presented[phase])
            for y in 0..<64 {
                for x in 0..<64 where source[(y * 64 + x) * 4 + 3] > 2 {
                    let targetX = x - Int(crop.minX), targetY = y - Int(crop.minY)
                    #expect(targetX >= 2 && targetY >= 2)
                    #expect(targetX < presented[phase].width - 2 && targetY < presented[phase].height - 2)
                    let original = (y * 64 + x) * 4
                    let cropped = (targetY * presented[phase].width + targetX) * 4
                    #expect(Array(source[original..<original + 4]) == Array(target[cropped..<cropped + 4]))
                }
            }
            // The moving body marker retains its exact per-phase displacement,
            // rather than being independently centered or enlarged each tick.
            let markerX = 27 + phase - Int(crop.minX), markerY = 36 - Int(crop.minY)
            #expect(target[(markerY * presented[phase].width + markerX) * 4 + 2] == 255)
        }
    }

    @Test func presentationPreservesVisibleEdgesAndRejectsMalformedInput() throws {
        let opaque = try solidImage(dimension: 32, alpha: 255)
        let empty = try solidImage(dimension: 32, alpha: 0)
        let differentSize = try solidImage(dimension: 64, alpha: 255)
        #expect(AuthoredSpriteMotion.presentationCrop(for: Array(repeating: opaque, count: 4))
            == CGRect(x: 0, y: 0, width: 32, height: 32))
        #expect(AuthoredSpriteMotion.presentationFrames(from: []) == nil)
        #expect(AuthoredSpriteMotion.presentationFrames(from: [opaque]) == nil)
        #expect(AuthoredSpriteMotion.presentationFrames(from: [opaque, opaque, opaque, differentSize]) == nil)
        #expect(AuthoredSpriteMotion.presentationFrames(from: Array(repeating: empty, count: 4)) == nil)
    }

    @Test func stillPoseIgnoresHazeAndPreservesEveryVisiblePixel() throws {
        let clean = try phaseImage(phase: 0, haze: false)
        let hazy = try phaseImage(phase: 0, haze: true)
        let crop = try #require(SpritePosePresentation.crop(for: hazy))
        #expect(crop == SpritePosePresentation.crop(for: clean))
        #expect(crop.width < 64 && crop.height < 64)
        let fitted = try #require(SpritePosePresentation.image(from: hazy))
        let before = try pixels(hazy), after = try pixels(fitted)
        for y in 0..<hazy.height {
            for x in 0..<hazy.width where before[(y * hazy.width + x) * 4 + 3] > 2 {
                let tx = x - Int(crop.minX), ty = y - Int(crop.minY)
                #expect(tx >= 2 && ty >= 2 && tx < fitted.width - 2 && ty < fitted.height - 2)
                let source = (y * hazy.width + x) * 4, target = (ty * fitted.width + tx) * 4
                #expect(Array(before[source..<source + 4]) == Array(after[target..<target + 4]))
            }
        }
        #expect(try pixels(hazy) == before, "Presentation must not mutate the source")
    }

    @Test func stillPoseHandlesRectanglesEmptyAndEdgeContent() throws {
        let full = try solidImage(dimension: 32, alpha: 255)
        let rectangle = try #require(full.cropping(to: CGRect(x: 0, y: 0, width: 20, height: 32)))
        #expect(SpritePosePresentation.crop(for: rectangle) == CGRect(x: 0, y: 0, width: 20, height: 32))
        #expect(SpritePosePresentation.image(from: try solidImage(dimension: 32, alpha: 0)) == nil)
        #expect(SpritePosePresentation.image(from: try solidImage(dimension: 32, alpha: 2)) == nil)
        #expect(SpritePosePresentation.crop(for: try solidImage(dimension: 401, alpha: 255)) == nil)
    }

    private func phaseImage(phase: Int, haze: Bool) throws -> CGImage {
        var rgba = [UInt8](repeating: 0, count: 64 * 64 * 4)
        func pixel(_ x: Int, _ y: Int, _ colour: [UInt8]) {
            rgba.replaceSubrange(((y * 64 + x) * 4)..<((y * 64 + x) * 4 + 4), with: colour)
        }
        for y in 31...43 { for x in (22 + phase)...(34 + phase) { pixel(x, y, [180, 30, 10, 255]) } }
        pixel(27 + phase, 36, [0, 0, 255, 255])
        // Faint but real antialias detail, which the >2 rule must preserve.
        pixel(44, 27, [1, 1, 1, 3])
        if haze { pixel(1, 1, [0, 0, 0, 1]); pixel(62, 2, [0, 0, 0, 2]) }
        return try rgbaImage(rgba, dimension: 64)
    }

    private func solidImage(dimension: Int, alpha: UInt8) throws -> CGImage {
        var rgba = [UInt8](repeating: 0, count: dimension * dimension * 4)
        for offset in stride(from: 3, to: rgba.count, by: 4) { rgba[offset] = alpha }
        return try rgbaImage(rgba, dimension: dimension)
    }

    private func rgbaImage(_ rgba: [UInt8], dimension: Int) throws -> CGImage {
        let provider = try #require(CGDataProvider(data: Data(rgba) as CFData))
        return try #require(CGImage(width: dimension, height: dimension, bitsPerComponent: 8,
            bitsPerPixel: 32, bytesPerRow: dimension * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }

    private func pixels(_ image: CGImage) throws -> [UInt8] {
        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try rgba.withUnsafeMutableBytes { bytes in
            let context = try #require(CGContext(data: bytes.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return rgba
    }

    private func png(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        for index in 0..<4 {
            context.setFillColor(CGColor(red: CGFloat(index + 1) / 4, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: index * height, y: 0, width: height, height: height))
        }
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
