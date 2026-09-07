import EvoBarCore
import SwiftUI

/// The companion walking or flying through a scrolling scene. All motion is
/// procedural on top of the single sprite per state, so no extra artwork is needed.
struct CompanionSceneView: View {
    let reference: AnimalAssetReference
    let visualState: CompanionVisualState
    let locomotion: AnimalLocomotion
    let themeColor: Color
    let quality: AnimationQuality

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let width: CGFloat = 320
    private let height: CGFloat = 128
    private let groundHeight: CGFloat = 26
    private let spriteSize: CGFloat = 84

    var body: some View {
        TimelineView(.animation(minimumInterval: frameInterval, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .bottom) {
                backdrop(time: t)
                sprite(time: t)
                    .padding(.bottom, groundHeight - 6)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.quaternary))
        }
    }

    private var frameInterval: Double {
        switch quality {
        case .smooth: 1 / 30
        case .balanced: 1 / 15
        case .powerSaver: 1 / 6
        }
    }

    /// Points per second the scene moves past the companion. Matched to the
    /// synthesised stride so the feet do not slide on the ground.
    private var scrollSpeed: Double {
        switch visualState {
        case .working: 36
        case .evolutionReady, .idle: 10
        case .sleeping: 0
        }
    }

    private var gait: SpriteGait? {
        guard locomotion == .walk, visualState != .sleeping else { return nil }
        return visualState == .working ? .trot : .walk
    }

    private let gaitFrameCount = 12

    // MARK: Backdrop

    private func backdrop(time: Double) -> some View {
        Canvas { canvas, size in
            let groundTop = size.height - groundHeight
            canvas.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [themeColor.opacity(0.28), themeColor.opacity(0.06)]),
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
            canvas.fill(hills, with: .color(themeColor.opacity(0.16)))

            canvas.fill(
                Path(CGRect(x: 0, y: groundTop, width: size.width, height: groundHeight)),
                with: .color(themeColor.opacity(0.22))
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
            canvas.fill(ticks, with: .color(themeColor.opacity(0.45)))
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
            let frames = AnimalSpriteImage.gaitFrames(reference, gait: gait, frameCount: gaitFrameCount)
            if frames.isEmpty {
                AnimalSpriteView(reference: reference, size: spriteSize)
            } else {
                let index = Int(time / gait.cycleDuration * Double(frames.count)) % frames.count
                Image(nsImage: frames[index])
                    .resizable()
                    .interpolation(.none)
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
        case (_, .fly):
            let wave = sin(time * 2)
            motion.lift = -14 + CGFloat(wave) * 4
            motion.shadowScale = 0.75
        }
        return motion
    }
}
