import AppKit
import EvoBarCore
import ImageIO
import SwiftUI

@MainActor enum AnimalSpriteImage {
    private struct CachedImage { let image: NSImage? }
    private static var cache: [String: CachedImage] = [:]

    static func load(_ reference: AnimalAssetReference) -> NSImage? {
        let cacheKey = "\(reference.assetID)|\(reference.visualState.rawValue)"
        if let cached = cache[cacheKey] {
            return cached.image?.copy() as? NSImage
        }
        let image = BundledAnimalSpriteStore.imageData(for: reference).flatMap { data -> NSImage? in
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let raw = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            let fitted = SpritePosePresentation.image(from: raw) ?? raw
            return NSImage(cgImage: fitted, size: NSSize(width: fitted.width, height: fitted.height))
        }
        image?.isTemplate = false
        if cache.count >= 256, let oldest = cache.keys.first { cache.removeValue(forKey: oldest) }
        // Cache missing resources too: an absent pose must not hit disk per tick.
        cache[cacheKey] = CachedImage(image: image)
        return image?.copy() as? NSImage
    }

    /// Authored frames and what they say about how fast the ground should move.
    struct AuthoredMotion {
        let frames: [NSImage]
        /// Feet travel across the cycle, as a fraction of the frame's side.
        let strideFraction: Double
        let bottomInsetFraction: Double
    }

    private static var motionCache: [String: AuthoredMotion] = [:]
    private static var motionOrder: [String] = []

    /// Decode once per resident strip, including negative results. A small LRU
    /// keeps recently displayed companions warm without retaining the full set
    /// of every stage and colour in memory (at most 12 MiB of RGBA pixels for
    /// twelve four-frame 256px strips). Cropped frames are never re-rigged.
    static func authoredMotion(_ reference: AnimalAssetReference) -> AuthoredMotion {
        if let motion = motionCache[reference.assetID] {
            motionOrder.removeAll { $0 == reference.assetID }
            motionOrder.append(reference.assetID)
            return motion
        }
        let cropped = BundledAnimalSpriteStore.motionData(for: reference)
            .flatMap(AuthoredSpriteMotion.decodeFrames(from:))
            .flatMap(AuthoredSpriteMotion.presentationFrames(from:)) ?? []
        let motion = AuthoredMotion(
            frames: cropped.map { NSImage(cgImage: $0, size: NSSize(width: $0.width, height: $0.height)) },
            strideFraction: AuthoredSpriteMotion.strideFraction(of: cropped),
            bottomInsetFraction: AuthoredSpriteMotion.bottomInsetFraction(of: cropped)
        )
        if motionOrder.count >= 12 { motionCache.removeValue(forKey: motionOrder.removeFirst()) }
        motionCache[reference.assetID] = motion
        motionOrder.append(reference.assetID)
        return motion
    }

    static func authoredFrames(_ reference: AnimalAssetReference) -> [NSImage] {
        authoredMotion(reference).frames
    }

    static func motionFrames(_ reference: AnimalAssetReference, profile: CompanionMotionProfile) -> [NSImage] {
        if profile.usesAuthoredFrames { return authoredFrames(reference) }
        if let gait = profile.gait {
            return gaitCycle(reference, gait: gait, frameCount: profile.frameCount).frames
        }
        return load(reference).map { [$0] } ?? []
    }

    private static var tintCache: [String: Color?] = [:]

    /// The colour this sprite reads as, for scenery that has to sit behind it.
    /// Falls back to the line's manifest colour when the art gives no clear hue.
    static func sceneTint(for reference: AnimalAssetReference, fallback: Color) -> Color {
        if let cached = tintCache[reference.assetID] { return cached ?? fallback }
        var tint: Color?
        if let data = BundledAnimalSpriteStore.imageData(for: reference),
           let source = CGImageSourceCreateWithData(data as CFData, nil),
           let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
           let colour = SpritePalette.dominantColor(of: image) {
            tint = Color(
                hue: colour.hue,
                saturation: min(0.75, max(0.35, colour.saturation)),
                brightness: min(0.9, max(0.5, colour.brightness))
            )
        }
        if tintCache.count >= 256, let oldest = tintCache.keys.first { tintCache.removeValue(forKey: oldest) }
        tintCache.updateValue(tint, forKey: reference.assetID)
        return tint ?? fallback
    }

    struct GaitCycle {
        let frames: [NSImage]
        /// `nil` when the cycle is a single unposed sprite, so nothing should
        /// scroll in step with it.
        let metrics: SpriteGaitMetrics?
    }

    private static var gaitCache: [String: GaitCycle] = [:]

    /// One synthesised gait cycle built from the state's own pose, so the running
    /// pose keeps its stretched legs. Falls back to the standing pose when the
    /// state sprite yields no legs, and to the plain sprite when nothing does.
    static func gaitCycle(_ reference: AnimalAssetReference, gait: SpriteGait, frameCount: Int) -> GaitCycle {
        let cacheKey = "\(reference.assetID)|\(reference.visualState.rawValue)|\(gait.rawValue)|\(frameCount)"
        if let cached = gaitCache[cacheKey] { return cached }
        let standing = AnimalAssetReference(
            assetID: reference.assetID,
            fallbackEmoji: reference.fallbackEmoji,
            visualState: .idle
        )
        func render(_ source: AnimalAssetReference) -> GaitCycle? {
            guard let data = BundledAnimalSpriteStore.imageData(for: source),
                  let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
                  let rendered = SpriteGaitRenderer.frames(
                      from: image,
                      gait: gait,
                      pose: source.visualState == .working ? .running : .standing,
                      frameCount: frameCount
                  )
            else { return nil }
            return GaitCycle(
                frames: rendered.frames.map {
                    NSImage(cgImage: $0, size: NSSize(width: $0.width, height: $0.height))
                },
                metrics: rendered.metrics
            )
        }
        let cycle = render(reference)
            ?? render(standing)
            ?? GaitCycle(frames: load(reference).map { [$0] } ?? [], metrics: nil)
        if gaitCache.count >= 8, let oldest = gaitCache.keys.first { gaitCache.removeValue(forKey: oldest) }
        gaitCache[cacheKey] = cycle
        return cycle
    }
}

/// A frame-only renderer. Scene drift and old fallback body motion belong to
/// their surfaces, never to an authored frame's anatomy.
struct AnimalMotionView: View {
    let reference: AnimalAssetReference
    let size: CGFloat
    let profile: CompanionMotionProfile
    let time: TimeInterval

    var body: some View {
        let frames = AnimalSpriteImage.motionFrames(reference, profile: profile)
        Group {
            if !frames.isEmpty {
                Image(nsImage: frames[profile.frameIndex(at: time) % frames.count])
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                AnimalSpriteView(reference: reference, size: size)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Authored loops have no painted ready-state spark. Keep the
            // readiness cue on Home and the desktop without editing the art.
            if reference.visualState == .evolutionReady && profile.usesAuthoredFrames {
                Image(systemName: "sparkle")
                    .font(.system(size: max(8, size * 0.13), weight: .semibold))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
            }
        }
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
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Text(reference.fallbackEmoji)
                    .font(.system(size: size * 0.72))
            }
        }
        .frame(width: size, height: size)
    }
}

/// Static reward art for final forms; all other stages keep their walking sprite.
@MainActor private enum FinalPortraitImage {
    private struct Cached { let image: NSImage? }
    private static var cache: [String: Cached] = [:]

    static func load(_ reference: AnimalAssetReference) -> NSImage? {
        if let cached = cache[reference.assetID] { return cached.image }
        let name = "\(reference.assetID).front"
        let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "FinalPortraits")
            ?? Bundle.module.url(forResource: name, withExtension: "png")
        let image = url.flatMap(NSImage.init(contentsOf:))
        cache[reference.assetID] = Cached(image: image)
        return image
    }
}

struct FinalPortraitView: View {
    let reference: AnimalAssetReference
    let size: CGFloat

    init(reference: AnimalAssetReference, size: CGFloat) {
        self.reference = reference
        self.size = size
    }

    init(animal: AnimalDefinition, stageIndex: Int, isShiny: Bool, size: CGFloat) {
        reference = ManifestAnimalAssetProvider().asset(
            for: animal, stageIndex: stageIndex, isShiny: isShiny, visualState: .idle)
        self.size = size
    }

    var body: some View {
        Group {
            if let image = FinalPortraitImage.load(reference) {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                AnimalSpriteView(reference: reference, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
