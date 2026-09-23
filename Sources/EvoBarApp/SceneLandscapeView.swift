import EvoBarCore
import SwiftUI

/// Shared by the worn scene and shop previews. No timers, random state or I/O:
/// the parent supplies zero time/travel for previews, sleeping and reduced motion.
struct SceneLandscapeView: View {
    let theme: SceneTheme
    let time: Double
    let travel: Double
    let groundHeight: CGFloat

    private var colors: (top: Color, horizon: Color, far: Color, near: Color, ground: Color) {
        switch theme {
        case .dawn:
            (Color(hex: "#655C92"), Color(hex: "#FFD0A5"), Color(hex: "#BC8D9E"), Color(hex: "#777A96"), Color(hex: "#68786F"))
        case .dusk:
            (Color(hex: "#302747"), Color(hex: "#EFAD86"), Color(hex: "#AD7990"), Color(hex: "#515371"), Color(hex: "#3B4D53"))
        case .night:
            (Color(hex: "#0D1738"), Color(hex: "#536A9A"), Color(hex: "#394970"), Color(hex: "#253452"), Color(hex: "#233E49"))
        case .snow:
            (Color(hex: "#9EB8D3"), Color(hex: "#EAF3FD"), Color(hex: "#AEC3D9"), Color(hex: "#7193B4"), Color(hex: "#EAF2F9"))
        }
    }

    var body: some View {
        Canvas { context, size in
            let palette = colors
            let ground = size.height - groundHeight
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [palette.top, palette.horizon]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: ground)))

            let center = CGPoint(x: size.width * 0.79, y: ground * 0.30)
            let radius: CGFloat = theme == .night ? 10 : 15
            let light = theme == .night ? Color(hex: "#FFF0C8") : Color(hex: "#FFE2B0")
            if theme != .snow {
                let glow = CGRect(x: center.x - 46, y: center.y - 46, width: 92, height: 92)
                context.fill(Path(ellipseIn: glow), with: .radialGradient(
                    Gradient(colors: [light.opacity(0.28), light.opacity(0)]),
                    center: center, startRadius: radius, endRadius: 46))
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                   width: radius * 2, height: radius * 2)),
                             with: .color(light.opacity(theme == .night ? 0.94 : 0.80)))
            }

            if theme == .night {
                // Deterministic stars: a quiet sky rather than a flashing reward effect.
                for index in 0..<24 {
                    let x = (CGFloat((index * 47 + 13) % 101) / 101) * size.width
                    let y = (CGFloat((index * 29 + 7) % 71) / 100) * ground
                    guard hypot(x - center.x, y - center.y) > 25 else { continue }
                    let dot: CGFloat = index.isMultiple(of: 5) ? 2 : 1
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                                 with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.8 : 0.4)))
                    if index.isMultiple(of: 7) {
                        var glint = Path()
                        glint.move(to: CGPoint(x: x - 2, y: y + 1))
                        glint.addLine(to: CGPoint(x: x + 4, y: y + 1))
                        glint.move(to: CGPoint(x: x + 1, y: y - 2))
                        glint.addLine(to: CGPoint(x: x + 1, y: y + 4))
                        context.stroke(glint, with: .color(.white.opacity(0.3)), lineWidth: 0.6)
                    }
                }
            }

            let far = ridge(size: size, baseline: ground - 8, amplitude: ground * 0.46,
                            step: 44, travel: travel * 0.06)
            context.fill(far, with: .color(palette.far))
            if theme == .snow {
                // Snow caps sit on the far range, behind the darker tree line.
                var caps = context
                caps.clip(to: far)
                caps.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: ground * 0.69)),
                          with: .linearGradient(Gradient(colors: [.white.opacity(0.85), .white.opacity(0)]),
                                                startPoint: .zero, endPoint: CGPoint(x: 0, y: ground * 0.69)))
            }
            context.fill(ridge(size: size, baseline: ground + 7, amplitude: ground * 0.32,
                               step: 57, travel: travel * 0.13), with: .color(palette.near))

            // A sparse tree line gives scale without competing with the companion.
            let spacing: CGFloat = 62
            let offset = CGFloat((travel * 0.24).truncatingRemainder(dividingBy: spacing * 3))
            for index in -3...Int(size.width / spacing) + 3 {
                let x = CGFloat(index) * spacing - offset
                let treeHeight: CGFloat = index.isMultiple(of: 3) ? 27 : 18
                let base = ground + 3
                var tree = Path()
                for tier in 0..<3 {
                    let top = base - treeHeight + CGFloat(tier) * treeHeight * 0.23
                    let half = treeHeight * (0.18 + CGFloat(tier) * 0.055)
                    tree.move(to: CGPoint(x: x, y: top))
                    tree.addLine(to: CGPoint(x: x + half, y: top + treeHeight * 0.43))
                    tree.addLine(to: CGPoint(x: x - half, y: top + treeHeight * 0.43))
                    tree.closeSubpath()
                }
                context.fill(tree, with: .color(theme == .snow ? Color(hex: "#527893") : palette.ground))
                if theme == .snow {
                    context.fill(Path(ellipseIn: CGRect(x: x - 5, y: base - treeHeight + 6, width: 10, height: 2)),
                                 with: .color(.white.opacity(0.75)))
                }
            }

            // Keep the original ground line/stride speed so paws do not skate.
            context.fill(Path(CGRect(x: 0, y: ground, width: size.width, height: groundHeight)),
                         with: .linearGradient(Gradient(colors: [palette.ground, palette.ground.opacity(0.88)]),
                                               startPoint: CGPoint(x: 0, y: ground), endPoint: CGPoint(x: 0, y: size.height)))
            var edge = Path()
            edge.move(to: CGPoint(x: 0, y: ground))
            edge.addLine(to: CGPoint(x: size.width, y: ground))
            context.stroke(edge, with: .color(theme == .snow ? .white.opacity(0.9) : palette.horizon.opacity(0.35)), lineWidth: 1)
            let tickOffset = CGFloat(travel.truncatingRemainder(dividingBy: 66))
            for index in -3...Int(size.width / 22) + 3 {
                let x = CGFloat(index) * 22 - tickOffset
                let y = ground + (index.isMultiple(of: 3) ? 9 : 15)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: index.isMultiple(of: 3) ? 5 : 2, height: 1)),
                             with: .color(theme == .snow ? palette.near.opacity(0.3) : palette.horizon.opacity(0.3)))
            }

            if theme == .snow {
                for index in 0..<22 {
                    let drift = time * (index.isMultiple(of: 2) ? 3 : 5)
                    let x = (Double((index * 43 + 17) % 101) / 101 * size.width + drift)
                        .truncatingRemainder(dividingBy: max(1, size.width))
                    let y = (Double((index * 31 + 11) % 97) / 97 * size.height + time * 10)
                        .truncatingRemainder(dividingBy: max(1, size.height))
                    let dot: CGFloat = index.isMultiple(of: 4) ? 2.5 : 1.5
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                                 with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.85 : 0.5)))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func ridge(size: CGSize, baseline: CGFloat, amplitude: CGFloat, step: CGFloat, travel: Double) -> Path {
        let peaks: [CGFloat] = [0.20, 0.72, 0.36, 1.0, 0.28, 0.64]
        let offset = CGFloat(travel.truncatingRemainder(dividingBy: Double(step) * Double(peaks.count)))
        var path = Path()
        path.move(to: CGPoint(x: -step * 7, y: size.height))
        for index in -7...Int(size.width / step) + 7 {
            let peak = peaks[(index % peaks.count + peaks.count) % peaks.count]
            path.addLine(to: CGPoint(x: CGFloat(index) * step - offset, y: baseline - amplitude * peak))
        }
        path.addLine(to: CGPoint(x: size.width + step * 7, y: size.height))
        path.closeSubpath()
        return path
    }
}
