import AppKit
import EvoBarCore
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
