import EvoBarCore
import SwiftUI

/// The companion walking or flying through a scrolling scene. All motion is
/// procedural on top of the single sprite per state, so no extra artwork is needed.
struct CompanionSceneView: View {
    let reference: AnimalAssetReference
    let visualState: CompanionVisualState
    let locomotion: AnimalLocomotion
    let quality: AnimationQuality

    /// Taken from the sprite so the scene always matches the stage on screen.
    let themeColor: Color
    /// A backdrop the user bought and is wearing; nil keeps the artwork's colour.
    let sceneTheme: SceneTheme?

    init(
        reference: AnimalAssetReference,
        visualState: CompanionVisualState,
        locomotion: AnimalLocomotion,
        themeColor: Color,
        quality: AnimationQuality,
        sceneTheme: SceneTheme? = nil,
        width: CGFloat = 340,
        height: CGFloat = 136,
        spriteSize: CGFloat = 84
    ) {
        self.reference = reference
        self.visualState = visualState
        self.locomotion = locomotion
        self.quality = quality
        self.sceneTheme = sceneTheme
        self.themeColor = AnimalSpriteImage.sceneTint(for: reference, fallback: themeColor)
        self.width = width
        self.height = height
        self.spriteSize = spriteSize
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let width: CGFloat
    private let height: CGFloat
    private let groundHeight: CGFloat = 22
    private let spriteSize: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: frameInterval, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .bottom) {
                backdrop(time: t)
                sprite(time: t)
                    .padding(.bottom, groundHeight - 6)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(EvoStyle.hairline))
        }
    }

    /// The scene is on screen only while the panel is open, so even Power Saver
    /// keeps close to one gait frame per tick; six frames a second read as a
    /// flip-book, not a walk.
    private var frameInterval: Double {
        switch quality {
        case .smooth: 1 / 30
        case .balanced: 1 / 24
        case .powerSaver: 1 / 15
        }
    }

    /// Points per second the scene moves past the companion. Taken from the
    /// gait's own stride so a planted foot sits still on the ground instead of
    /// skating, and falling back to a drift only when nothing is walking.
    private var scrollSpeed: Double {
        guard visualState != .sleeping else { return 0 }
        guard let gait, let metrics = cycle.metrics else { return locomotion == .fly ? 30 : 0 }
        return metrics.groundSpeed(for: gait) * spriteSize
    }

    private var gait: SpriteGait? {
        guard locomotion == .walk, visualState != .sleeping else { return nil }
        return visualState == .working ? .trot : .walk
    }

    private var cycle: AnimalSpriteImage.GaitCycle {
        guard let gait else { return .init(frames: [], metrics: nil) }
        return AnimalSpriteImage.gaitCycle(reference, gait: gait, frameCount: gaitFrameCount)
    }

    private let gaitFrameCount = 16

    // MARK: Backdrop

    /// The three colours the backdrop is drawn from: a bought theme's, or the
    /// companion's own artwork repeated when nothing is worn, which is exactly
    /// what the scene looked like before backdrops existed.
    private var palette: (sky: Color, hills: Color, ground: Color) {
        guard let sceneTheme else { return (themeColor, themeColor, themeColor) }
        let colours = sceneTheme.palette
        func colour(_ rgb: SceneTheme.RGB) -> Color {
            Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
        }
        return (colour(colours.sky), colour(colours.hills), colour(colours.ground))
    }

    private func backdrop(time: Double) -> some View {
        let palette = palette
        let skyTop = sceneTheme == nil ? 0.28 : 0.45
        let skyBottom = sceneTheme == nil ? 0.06 : 0.10
        return Canvas { canvas, size in
            let groundTop = size.height - groundHeight
            canvas.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [palette.sky.opacity(skyTop), palette.sky.opacity(skyBottom)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Far hills scroll at a third of the speed for parallax.
            let hillSpacing: CGFloat = 150
            let farOffset = CGFloat((time * scrollSpeed / 3).truncatingRemainder(dividingBy: hillSpacing))
            var hills = Path()
            for index in -1...Int(size.width / hillSpacing) + 1 {
                let x = CGFloat(index) * hillSpacing - farOffset
                let bulge: CGFloat = index.isMultiple(of: 2) ? 40 : 26
                hills.addEllipse(in: CGRect(x: x, y: groundTop - bulge + 8, width: 140, height: bulge * 2))
            }
            canvas.fill(hills, with: .color(palette.hills.opacity(0.16)))

            canvas.fill(
                Path(CGRect(x: 0, y: groundTop, width: size.width, height: groundHeight)),
                with: .color(palette.ground.opacity(0.22))
            )

            // Ground ticks scroll at full speed; this is what sells the walk.
            let tickSpacing: CGFloat = 22
            let nearOffset = CGFloat((time * scrollSpeed).truncatingRemainder(dividingBy: tickSpacing))
            var ticks = Path()
            for index in -1...Int(size.width / tickSpacing) + 1 {
                let x = CGFloat(index) * tickSpacing - nearOffset
                let tall: CGFloat = index.isMultiple(of: 3) ? 7 : 4
                ticks.addRoundedRect(in: CGRect(x: x, y: groundTop - tall, width: 3, height: tall), cornerSize: CGSize(width: 1, height: 1))
            }
            canvas.fill(ticks, with: .color(palette.ground.opacity(0.45)))
        }
    }

    // MARK: Companion

    private func sprite(time: Double) -> some View {
        let motion = motion(at: time)
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(locomotion == .fly ? 0.08 : 0.16))
                .frame(width: spriteSize * 0.55 * motion.shadowScale, height: 8)
                .offset(y: 2)

            if visualState == .evolutionReady {
                Circle()
                    .fill(themeColor.opacity(0.35))
                    .frame(width: spriteSize * 0.9, height: spriteSize * 0.9)
                    .blur(radius: 12)
                    .scaleEffect(1 + 0.08 * sin(time * 4))
                    .offset(y: -spriteSize * 0.25)
            }

            companion(time: time)
                .scaleEffect(x: 1, y: motion.breath, anchor: .bottom)
                .rotationEffect(.degrees(motion.tilt))
                .offset(y: motion.lift)

            if visualState == .sleeping {
                Image(systemName: "zzz")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .offset(x: spriteSize * 0.35, y: -spriteSize - 6 + CGFloat(sin(time * 1.5)) * 3)
            }
        }
    }

    /// The gait cycle when the companion walks; the plain state sprite otherwise.
    @ViewBuilder
    private func companion(time: Double) -> some View {
        if let gait {
            let frames = cycle.frames
            if frames.isEmpty {
                AnimalSpriteView(reference: reference, size: spriteSize)
            } else {
                let index = Int(time / gait.cycleDuration * Double(frames.count)) % frames.count
                // The sheet is three times the drawn size: nearest-neighbour
                // drops rows and the walk shimmers, so it is filtered down.
                Image(nsImage: frames[index])
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: spriteSize, height: spriteSize)
            }
        } else {
            AnimalSpriteView(reference: reference, size: spriteSize)
        }
    }

    private struct Motion {
        var lift: CGFloat = 0
        var tilt: Double = 0
        var breath: CGFloat = 1
        var shadowScale: CGFloat = 1
    }

    private func motion(at time: Double) -> Motion {
        var motion = Motion()
        switch (visualState, locomotion) {
        case (.sleeping, _):
            motion.breath = 1 + 0.015 * CGFloat(sin(time * 1.2))
        case (.working, .fly):
            let wave = sin(time * 3)
            motion.lift = -18 + CGFloat(wave) * 7
            motion.tilt = wave * 3
            motion.shadowScale = 0.7
        case (_, .walk):
            break // the gait frames carry the bob
        case (_, .biped):
            // Keep the artist's two legs intact, without inventing a second pair.
            motion.lift = CGFloat(sin(time * (visualState == .working ? 5 : 2))) * 1.5
        case (_, .fly):
            let wave = sin(time * 2)
            motion.lift = -14 + CGFloat(wave) * 4
            motion.shadowScale = 0.75
        }
        return motion
    }
}
