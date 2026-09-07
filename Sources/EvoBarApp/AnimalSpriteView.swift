import AppKit
import EvoBarCore
import ImageIO
import SwiftUI

@MainActor enum AnimalSpriteImage {
    private static var cache: [String: NSImage] = [:]

    static func load(_ reference: AnimalAssetReference) -> NSImage? {
        let cacheKey = "\(reference.assetID)|\(reference.visualState.rawValue)"
        if let cached = cache[cacheKey] {
            return cached.copy() as? NSImage
        }
        guard let data = BundledAnimalSpriteStore.imageData(for: reference),
              let image = NSImage(data: data) else { return nil }
        image.isTemplate = false
        cache[cacheKey] = image
        return image.copy() as? NSImage
    }

    private static var gaitCache: [String: [NSImage]] = [:]

    /// One synthesised gait cycle built from the state's own pose, so the running
    /// pose keeps its stretched legs. Falls back to the standing pose when the
    /// state sprite yields no legs, and to the plain sprite when nothing does.
    static func gaitFrames(_ reference: AnimalAssetReference, gait: SpriteGait, frameCount: Int) -> [NSImage] {
        let cacheKey = "\(reference.assetID)|\(reference.visualState.rawValue)|\(gait.rawValue)|\(frameCount)"
        if let cached = gaitCache[cacheKey] { return cached }
        let standing = AnimalAssetReference(
            assetID: reference.assetID,
            fallbackEmoji: reference.fallbackEmoji,
            visualState: .idle
        )
        func render(_ source: AnimalAssetReference) -> [NSImage]? {
            guard let data = BundledAnimalSpriteStore.imageData(for: source),
                  let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
                  let rendered = SpriteGaitRenderer.frames(from: image, gait: gait, frameCount: frameCount)
            else { return nil }
            return rendered.map { NSImage(cgImage: $0, size: NSSize(width: $0.width, height: $0.height)) }
        }
        let frames = render(reference) ?? render(standing) ?? load(reference).map { [$0] } ?? []
        gaitCache[cacheKey] = frames
        return frames
    }
}

struct AnimalSpriteView: View {
    let reference: AnimalAssetReference
    let size: CGFloat

    init(reference: AnimalAssetReference, size: CGFloat) {
        self.reference = reference
        self.size = size
    }

    init(
        animal: AnimalDefinition,
        stageIndex: Int = 1,
        isShiny: Bool = false,
        visualState: CompanionVisualState = .idle,
        size: CGFloat
    ) {
        reference = ManifestAnimalAssetProvider().asset(
            for: animal,
            stageIndex: stageIndex,
            isShiny: isShiny,
            visualState: visualState
        )
        self.size = size
    }

    var body: some View {
        Group {
            if let image = AnimalSpriteImage.load(reference) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Text(reference.fallbackEmoji)
                    .font(.system(size: size * 0.72))
            }
        }
        .frame(width: size, height: size)
    }
}
