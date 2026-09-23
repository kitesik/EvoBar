import Foundation
import CoreGraphics
import ImageIO

#if !EVOBAR_MOTION_REVIEW_STANDALONE
public enum CompanionVisualState: String, Codable, Sendable {
    case idle
    case working
    case evolutionReady
    case sleeping
}

public struct AnimalAssetReference: Equatable, Sendable {
    public let assetID: String
    public let fallbackEmoji: String
    public let visualState: CompanionVisualState

    public init(assetID: String, fallbackEmoji: String, visualState: CompanionVisualState) {
        self.assetID = assetID
        self.fallbackEmoji = fallbackEmoji
        self.visualState = visualState
    }
}

public protocol AnimalAssetProviding: Sendable {
    func asset(
        for animal: AnimalDefinition,
        stageIndex: Int,
        isShiny: Bool,
        visualState: CompanionVisualState
    ) -> AnimalAssetReference
}

public struct ManifestAnimalAssetProvider: AnimalAssetProviding {
    public init() {}

    public func asset(
        for animal: AnimalDefinition,
        stageIndex: Int,
        isShiny: Bool,
        visualState: CompanionVisualState
    ) -> AnimalAssetReference {
        let stage = animal.stages.first { $0.index == stageIndex } ?? animal.stages.first
        let assetID: String
        if let stage {
            assetID = isShiny ? stage.shinyAssetID : stage.normalAssetID
        } else {
            assetID = animal.lockedSilhouetteAssetID
        }
        return AnimalAssetReference(
            assetID: assetID,
            fallbackEmoji: animal.menuBarEmoji,
            visualState: visualState
        )
    }
}

public enum BundledAnimalSpriteStore {
    /// Whether a line ships with artwork. A line without it would appear as a
    /// bare emoji, so it is never sold, granted or hatched.
    public static func hasArtwork(for animal: AnimalDefinition) -> Bool {
        guard let first = animal.stages.first else { return false }
        return imageData(
            for: AnimalAssetReference(
                assetID: first.normalAssetID,
                fallbackEmoji: animal.menuBarEmoji,
                visualState: .idle
            )
        ) != nil
    }

    /// Whether this stage has its own sprites, rather than borrowing a neighbour's
    /// until its sheet is drawn.
    public static func hasArtwork(for animal: AnimalDefinition, stageIndex: Int) -> Bool {
        guard let stage = animal.stages.first(where: { $0.index == stageIndex }),
              stage.artworkPending != true else { return false }
        return imageData(
            for: AnimalAssetReference(
                assetID: stage.normalAssetID, fallbackEmoji: animal.menuBarEmoji, visualState: .idle)
        ) != nil
    }

    public static func imageData(for reference: AnimalAssetReference) -> Data? {
        for resourceName in resourceNameCandidates(for: reference) {
            let url = Bundle.module.url(
                forResource: resourceName,
                withExtension: "png",
                subdirectory: "Sprites"
            ) ?? Bundle.module.url(forResource: resourceName, withExtension: "png")
            if let url, let data = try? Data(contentsOf: url), !data.isEmpty {
                return data
            }
        }
        return nil
    }

    /// Motion is only loaded for the exact variant. Borrowing a normal-colour
    /// strip for an alternate-colour companion would make it change colour as
    /// soon as it started moving. Missing strips keep the existing pose fallback.
    public static func motionData(for reference: AnimalAssetReference) -> Data? {
        let name = "\(reference.assetID).motion"
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Sprites")
                ?? Bundle.module.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
        return data
    }

    public static func resourceNameCandidates(for reference: AnimalAssetReference) -> [String] {
        let state = reference.visualState.rawValue
        let normalAssetID = reference.assetID.hasSuffix(".shiny")
            ? String(reference.assetID.dropLast(".shiny".count))
            : reference.assetID
        return [
            "\(reference.assetID).\(state)",
            "\(normalAssetID).\(state)",
            "\(reference.assetID).idle",
            "\(normalAssetID).idle",
        ].reduce(into: []) { result, candidate in
            if !result.contains(candidate) { result.append(candidate) }
        }
    }
}
#endif

/// Presentation fitting for a static pose, independent of animation geometry.
public enum SpritePosePresentation {
    /// Display-only fitting. Keep the PNG and every visible pixel unchanged;
    /// alpha 1–2 export haze must not shrink a still companion on screen.
    public static func crop(for image: CGImage) -> CGRect? {
        let width = image.width, height = image.height
        guard (1...400).contains(width), (1...400).contains(height) else { return nil }
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let read = rgba.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard read else { return nil }
        var left = width, top = height, right = -1, bottom = -1
        for y in 0..<height {
            for x in 0..<width where rgba[(y * width + x) * 4 + 3] > 2 {
                left = min(left, x); right = max(right, x)
                top = min(top, y); bottom = max(bottom, y)
            }
        }
        guard right >= left, bottom >= top else { return nil }
        let padding = max(2, Int(ceil(Double(max(right - left + 1, bottom - top + 1)) * 0.045)))
        let x = max(0, left - padding), y = max(0, top - padding)
        return CGRect(x: x, y: y, width: min(width, right + padding + 1) - x,
                      height: min(height, bottom + padding + 1) - y)
    }

    public static func image(from image: CGImage) -> CGImage? {
        crop(for: image).flatMap { image.cropping(to: $0) }
    }
}

/// Four distinct equally sized square frames, left to right in a PNG strip.
public enum AuthoredSpriteMotion {
    public static let frameCount = 4
    public static let maximumFrameDimension = 256
    public static let maximumDataBytes = 32 * 1_024 * 1_024

    public static func frameRects(width: Int, height: Int) -> [CGRect]? {
        guard (16...maximumFrameDimension).contains(height),
              width == height * frameCount else { return nil }
        return (0..<frameCount).map {
            CGRect(x: $0 * height, y: 0, width: height, height: height)
        }
    }

    /// Validate metadata before image allocation, and reject malformed strips
    /// rather than stretching a pose into four apparent animation frames.
    public static func decodeFrames(from data: Data) -> [CGImage]? {
        guard !data.isEmpty, data.count <= maximumDataBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              let rects = frameRects(width: width, height: height),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == width, image.height == height else { return nil }
        let frames = rects.compactMap { image.cropping(to: $0) }
        return frames.count == frameCount ? frames : nil
    }

    /// One shared presentation square for the complete cycle. Alpha 1–2 is
    /// imperceptible export haze, not body anatomy; counting it can make a tiny
    /// companion occupy a large empty canvas. All alpha >2 from every phase is
    /// preserved, with padding for antialiasing. Never fit phases separately:
    /// doing that changes the animal's size and position four times per cycle.
    public static func presentationCrop(for frames: [CGImage]) -> CGRect? {
        guard frames.count == frameCount, let first = frames.first,
              (16...maximumFrameDimension).contains(first.width), first.width == first.height,
              frames.allSatisfy({ $0.width == first.width && $0.height == first.height }) else { return nil }
        let dimension = first.width
        var left = dimension, top = dimension, right = -1, bottom = -1
        for image in frames {
            var rgba = [UInt8](repeating: 0, count: dimension * dimension * 4)
            let read = rgba.withUnsafeMutableBytes { bytes -> Bool in
                guard let context = CGContext(data: bytes.baseAddress, width: dimension, height: dimension,
                    bitsPerComponent: 8, bytesPerRow: dimension * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(image, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
                return true
            }
            guard read else { return nil }
            for y in 0..<dimension {
                for x in 0..<dimension where rgba[(y * dimension + x) * 4 + 3] > 2 {
                    left = min(left, x); right = max(right, x)
                    top = min(top, y); bottom = max(bottom, y)
                }
            }
        }
        guard right >= left, bottom >= top else { return nil }
        let contentSide = max(right - left + 1, bottom - top + 1)
        let padding = max(2, Int(ceil(Double(contentSide) * 0.045)))
        let side = min(dimension, contentSide + padding * 2)
        let centerX = Double(left + right + 1) / 2
        let centerY = Double(top + bottom + 1) / 2
        let x = max(0, min(dimension - side, Int(floor(centerX - Double(side) / 2))))
        let y = max(0, min(dimension - side, Int(floor(centerY - Double(side) / 2))))
        return CGRect(x: x, y: y, width: side, height: side)
    }

    /// How far the feet travel across the cycle, as a fraction of the frame's
    /// side. The scene has to scroll the ground at the rate the drawing walks
    /// or the feet skate, and no single rate can serve every line: measured
    /// across the bundled strips this runs from about 0.01 to 0.19, twentyfold.
    ///
    /// The feet are the lowest band of the animal, so their average horizontal
    /// position swings back and forth once a cycle; the distance between its
    /// extremes is the stride. A strip that does not walk, a hover or a breath,
    /// measures near zero, which correctly leaves the ground still.
    public static func strideFraction(of frames: [CGImage]) -> Double {
        guard let first = frames.first, first.width == first.height, frames.count > 1 else { return 0 }
        let dimension = first.width
        var centres: [Double] = []
        for image in frames {
            var rgba = [UInt8](repeating: 0, count: dimension * dimension * 4)
            let read = rgba.withUnsafeMutableBytes { bytes -> Bool in
                guard let context = CGContext(
                    data: bytes.baseAddress, width: dimension, height: dimension,
                    bitsPerComponent: 8, bytesPerRow: dimension * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(image, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
                return true
            }
            guard read else { return 0 }
            // The buffer holds rows top to bottom, so the last row with any
            // pixel in it is the ground the animal stands on, and the band
            // just above it is the feet. Taking the first row instead tracks
            // the head, which hardly moves, and every line measures alike.
            var top = -1, bottom = -1
            for y in 0..<dimension {
                for x in 0..<dimension where rgba[(y * dimension + x) * 4 + 3] > 2 {
                    if top < 0 { top = y }
                    bottom = y
                    break
                }
            }
            guard top >= 0, bottom > top else { continue }
            let band = max(1, Int(Double(bottom - top) * 0.12))
            var sum = 0.0, count = 0.0
            for y in max(top, bottom - band)...bottom {
                for x in 0..<dimension where rgba[(y * dimension + x) * 4 + 3] > 2 {
                    sum += Double(x)
                    count += 1
                }
            }
            if count > 0 { centres.append(sum / count) }
        }
        guard let low = centres.min(), let high = centres.max(), dimension > 0 else { return 0 }
        return (high - low) / Double(dimension)
    }

    /// Only a CGImage crop: source pixels, colours, relative positions and PNGs
    /// remain unchanged. Call once on load, not from an animation tick.
    public static func presentationFrames(from frames: [CGImage]) -> [CGImage]? {
        guard let crop = presentationCrop(for: frames) else { return nil }
        let presented = frames.compactMap { $0.cropping(to: crop) }
        return presented.count == frameCount ? presented : nil
    }

    /// Shared ground baseline across a cycle; never reposition each phase.
    /// Ignores the same export haze as presentationCrop. Measure only on load.
    public static func bottomInsetFraction(of frames: [CGImage]) -> Double {
        guard frames.count == frameCount, let first = frames.first,
              (1...maximumFrameDimension).contains(first.width), first.width == first.height,
              frames.allSatisfy({ $0.width == first.width && $0.height == first.height }) else { return 0 }
        let side = first.width
        var bottom = -1
        for frame in frames {
            var rgba = [UInt8](repeating: 0, count: side * side * 4)
            let read = rgba.withUnsafeMutableBytes { bytes -> Bool in
                guard let context = CGContext(data: bytes.baseAddress, width: side, height: side,
                    bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(frame, in: CGRect(x: 0, y: 0, width: side, height: side))
                return true
            }
            guard read else { return 0 }
            for y in stride(from: side - 1, through: 0, by: -1) {
                if (0..<side).contains(where: { rgba[(y * side + $0) * 4 + 3] > 2 }) {
                    bottom = max(bottom, y)
                    break
                }
            }
        }
        return bottom < 0 ? 0 : Double(side - bottom - 1) / Double(side)
    }
}
