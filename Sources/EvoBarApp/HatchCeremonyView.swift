import EvoBarCore
import SwiftUI

/// Everything the hatch needs, captured when the new companion is created.
struct HatchCeremony: Equatable {
    let to: AnimalAssetReference
    let companionName: String
    let animalName: String
    let rarity: AnimalRarity
    let isShiny: Bool
    let themeColorHex: String
}

/// The four beats of a hatch: the egg stirs, cracks run across it while it
/// shakes, light in the line's rarity colour pours out and blows out to white,
/// and the new companion lands with its name, species and rarity. A chosen line
/// hatches the same way: in the story every companion begins as an egg.
struct HatchCeremonyView: View {
    let ceremony: HatchCeremony
    /// Seconds since the hatch began, driven by the view that owns it.
    let elapsed: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let stirEnd = 1.3
    static let crackEnd = 2.4
    static let flashEnd = 2.75
    static let total = 5.0

    private var tint: Color { Color(hex: ceremony.themeColorHex) }
    /// A shiny glows gold whatever its line; anything else glows its rarity.
    private var glow: Color {
        ceremony.isShiny ? CareBurstLayer.gold : EvoStyle.rarityColor(ceremony.rarity)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(backdropOpacity))
                .ignoresSafeArea()

            if elapsed < Self.flashEnd {
                eggStage
            } else {
                revealStage
            }

            Rectangle()
                .fill(.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.25), value: elapsed < Self.flashEnd)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("hatch.arrived", fallback: "%@ has arrived", ceremony.companionName))
    }

    // MARK: Beats

    private var eggStage: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(glow.opacity(glowStrength * 0.55))
                    .frame(width: 130, height: 130)
                    .blur(radius: 26)
                EvoEggView(tint: tint, size: 96)
                    .rotationEffect(.degrees(wobble), anchor: .bottom)
                    .offset(x: shake)
                    .overlay { cracks }
                    .shadow(color: glow.opacity(glowStrength), radius: 10 + 14 * glowStrength)
            }
            .frame(height: 150)

            Text(L10n.text("hatch.stirring", fallback: "Something is stirring…"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .opacity(elapsed > 0.4 ? 1 : 0)
        }
    }

    /// Cracks appear one after another once the egg shakes in earnest.
    private var cracks: some View {
        Canvas { context, size in
            let lines: [[CGPoint]] = [
                [CGPoint(x: 0.42, y: 0.28), CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.44, y: 0.50)],
                [CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.62, y: 0.46), CGPoint(x: 0.68, y: 0.58)],
                [CGPoint(x: 0.44, y: 0.50), CGPoint(x: 0.36, y: 0.62), CGPoint(x: 0.40, y: 0.72)],
                [CGPoint(x: 0.62, y: 0.46), CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.64, y: 0.20)],
            ]
            for line in lines.prefix(crackCount) {
                var path = Path()
                for (index, point) in line.enumerated() {
                    let scaled = CGPoint(x: point.x * size.width, y: point.y * size.height)
                    if index == 0 { path.move(to: scaled) } else { path.addLine(to: scaled) }
                }
                context.stroke(path, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
    }

    private var revealStage: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Image(systemName: ceremony.isShiny ? "sparkle" : "circle.fill")
                        .font(.system(size: ceremony.isShiny ? 13 : 5))
                        .foregroundStyle(glow)
                        .offset(sparkleOffset(index))
                        .opacity(sparkleOpacity)
                }
                AnimalSpriteView(reference: ceremony.to, size: 112)
                    .scaleEffect(revealScale)
                    .shadow(color: glow.opacity(0.7), radius: 16)
            }
            .frame(height: 150)

            Text(L10n.format("hatch.arrived", fallback: "%@ has arrived", ceremony.companionName))
                .font(.headline)
                .foregroundStyle(.white)
                .opacity(revealTextOpacity)
            Text(lineage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(glow)
                .opacity(revealTextOpacity)
        }
    }

    private var lineage: String {
        let parts = [
            ceremony.animalName,
            L10n.rarity(ceremony.rarity),
            ceremony.isShiny ? L10n.text("hatch.shiny", fallback: "Shiny") : "",
        ]
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    // MARK: Timing

    private var backdropOpacity: Double {
        elapsed < 0.3 ? elapsed / 0.3 * 0.72 : 0.72
    }

    private var stirProgress: Double {
        min(1, max(0, (elapsed - Self.stirEnd) / (Self.crackEnd - Self.stirEnd)))
    }

    /// The egg rocks on its base, wider and faster as the hatch nears.
    private var wobble: Double {
        guard !reduceMotion, elapsed < Self.crackEnd else { return 0 }
        let progress = min(1, elapsed / Self.crackEnd)
        return sin(elapsed * (6 + 10 * progress)) * (3 + 9 * progress)
    }

    private var shake: CGFloat {
        guard !reduceMotion, elapsed >= Self.stirEnd, elapsed < Self.crackEnd else { return 0 }
        return CGFloat(sin(elapsed * 40)) * 3
    }

    private var crackCount: Int {
        guard elapsed >= Self.stirEnd else { return 0 }
        return min(4, Int(stirProgress * 4.99))
    }

    private var glowStrength: Double { stirProgress }

    private var flashOpacity: Double {
        guard elapsed >= Self.crackEnd, elapsed < Self.flashEnd + 0.5 else { return 0 }
        if elapsed < Self.flashEnd {
            return min(1, (elapsed - Self.crackEnd) / (Self.flashEnd - Self.crackEnd))
        }
        return max(0, 1 - (elapsed - Self.flashEnd) / 0.5)
    }

    private var revealScale: CGFloat {
        let since = elapsed - Self.flashEnd
        guard since > 0, !reduceMotion else { return 1 }
        return 1 + 0.28 * CGFloat(exp(-since * 4) * cos(since * 11))
    }

    private var revealTextOpacity: Double {
        min(1, max(0, (elapsed - Self.flashEnd - 0.25) / 0.4))
    }

    private var sparkleOpacity: Double {
        let since = elapsed - Self.flashEnd
        guard since > 0 else { return 0 }
        return max(0, 1 - since / 1.1)
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let since = max(0, elapsed - Self.flashEnd)
        let angle = Double(index) / 12 * 2 * .pi
        let distance = 26 + since * 80
        return CGSize(width: cos(angle) * distance, height: sin(angle) * distance)
    }
}
