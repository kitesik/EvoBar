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

/// The authored-motion resource contract: four distinct, equally sized square
/// frames, left to right in a single PNG strip. It is not an eight-frame rig.
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

    /// Only a CGImage crop: source pixels, colours, relative positions and PNGs
    /// remain unchanged. Call once on load, not from an animation tick.
    public static func presentationFrames(from frames: [CGImage]) -> [CGImage]? {
        guard let crop = presentationCrop(for: frames) else { return nil }
        let presented = frames.compactMap { $0.cropping(to: crop) }
        return presented.count == frameCount ? presented : nil
    }
}
