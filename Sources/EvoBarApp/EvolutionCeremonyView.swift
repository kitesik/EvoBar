import EvoBarCore
import SwiftUI

/// Everything the ceremony needs, captured before the stage actually changes.
struct EvolutionCeremony: Equatable {
    let from: AnimalAssetReference
    let to: AnimalAssetReference
    let stageName: String
    let companionName: String
    let themeColorHex: String
}

/// The four beats of an evolution: the companion notices something, the forms
/// trade places faster and faster inside a white silhouette, everything blows
/// out to white, and the new form lands.
struct EvolutionCeremonyView: View {
    let ceremony: EvolutionCeremony
    /// Seconds since the ceremony began, driven by the view that owns it.
    let elapsed: Double

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    /// Isolated renders can opt in, but never override the user's preference off.
    var forceReducedMotion = false
    private var reduceMotion: Bool { systemReduceMotion || forceReducedMotion }

    static let pauseEnd = 0.9
    static let swapEnd = 3.0
    static let flashEnd = 3.35
    static let total = 4.6

    private var tint: Color { Color(hex: ceremony.themeColorHex) }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(backdropOpacity))
                .ignoresSafeArea()

            if !reduceMotion, elapsed < Self.flashEnd {
                buildUpStage
            } else {
                revealStage
            }

            // The blow-out that hides the swap.
            Rectangle()
                .fill(.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: elapsed < Self.flashEnd)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ceremony.companionName + ", " + L10n.format("evolution.became", fallback: "Evolved into %@!", ceremony.stageName))
    }

    // MARK: Beats

    private var buildUpStage: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(tint.opacity(0.55), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(ringScale(ring))
                        .opacity(ringOpacity(ring))
                }

                AnimalSpriteView(reference: showingTargetForm ? ceremony.to : ceremony.from, size: 104)
                    // The white silhouette: the shape reads, the identity does not.
                    .overlay {
                        if silhouetteStrength > 0 {
                            AnimalSpriteView(reference: showingTargetForm ? ceremony.to : ceremony.from, size: 104)
                                .colorMultiply(.white)
                                .brightness(1)
                                .opacity(silhouetteStrength)
                        }
                    }
                    .scaleEffect(x: squashX, y: stretchY, anchor: .bottom)
                    .offset(x: jitterX)
                    .shadow(color: tint.opacity(0.7), radius: glowRadius)
            }
            .frame(height: 150)

            if elapsed < Self.pauseEnd {
                Text("!")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(tint)
                    .opacity(elapsed > 0.25 ? 1 : 0)
                    .scaleEffect(elapsed > 0.25 ? 1 : 0.4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: elapsed > 0.25)
            } else {
                Text(L10n.text("evolution.inProgress", fallback: "Something is happening…"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var revealStage: some View {
        VStack(spacing: 12) {
            Text(verbatim: ceremony.companionName)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 13))
                        .foregroundStyle(tint)
                        .offset(sparkleOffset(index))
                        .opacity(sparkleOpacity)
                }
                HStack(spacing: 14) {
                    AnimalSpriteView(reference: ceremony.from, size: 48)
                        .opacity(0.7)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    FinalPortraitView(reference: ceremony.to, size: 112)
                        .scaleEffect(revealScale)
                        .shadow(color: tint.opacity(0.6), radius: 14)
                }
            }
            .frame(height: 150)

            Text(L10n.format("evolution.became", fallback: "Evolved into %@!", ceremony.stageName))
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(revealTextOpacity)
                .scaleEffect(revealTextOpacity)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Timing

    private var backdropOpacity: Double {
        reduceMotion ? 0.72 : (elapsed < 0.3 ? elapsed / 0.3 * 0.72 : 0.72)
    }

    /// Alternation accelerates from roughly 3 Hz to 12 Hz across the swap beat.
    /// Which form the alternation is on. The new one is never shown until the
    /// white silhouette is opaque: the shape has to read while the identity
    /// does not, or the reveal is over before the white-out arrives.
    private var showingTargetForm: Bool {
        guard elapsed >= Self.pauseEnd, elapsed < Self.flashEnd, silhouetteStrength >= 1
        else { return false }
        if reduceMotion { return elapsed > (Self.pauseEnd + Self.swapEnd) / 2 }
        let progress = (elapsed - Self.pauseEnd) / (Self.swapEnd - Self.pauseEnd)
        let rate = 3 + progress * 9
        return Int(elapsed * rate) % 2 == 1
    }

    private var silhouetteStrength: Double {
        guard elapsed >= Self.pauseEnd else { return 0 }
        return min(1, (elapsed - Self.pauseEnd) / 0.5)
    }

    private var stretchY: CGFloat {
        guard !reduceMotion else { return 1 }
        if elapsed < Self.pauseEnd {
            // The flinch: a small crouch before anything else.
            return 1 - 0.06 * sin(elapsed / Self.pauseEnd * .pi)
        }
        let progress = min(1, (elapsed - Self.pauseEnd) / (Self.swapEnd - Self.pauseEnd))
        return 1 + 0.35 * progress + 0.05 * sin(elapsed * 18)
    }

    private var squashX: CGFloat {
        guard !reduceMotion, elapsed >= Self.pauseEnd else { return 1 }
        let progress = min(1, (elapsed - Self.pauseEnd) / (Self.swapEnd - Self.pauseEnd))
        return 1 - 0.18 * progress
    }

    private var jitterX: CGFloat {
        guard !reduceMotion, elapsed < Self.pauseEnd else { return 0 }
        return CGFloat(sin(elapsed * 34)) * 3
    }

    private var glowRadius: CGFloat {
        guard elapsed >= Self.pauseEnd else { return 0 }
        return 6 + 18 * min(1, (elapsed - Self.pauseEnd) / (Self.swapEnd - Self.pauseEnd))
    }

    private func ringScale(_ ring: Int) -> CGFloat {
        guard elapsed >= Self.pauseEnd else { return 0.2 }
        let offset = Double(ring) * 0.33
        let phase = ((elapsed - Self.pauseEnd) / 1.1 + offset).truncatingRemainder(dividingBy: 1)
        return 0.4 + CGFloat(phase) * 1.5
    }

    private func ringOpacity(_ ring: Int) -> Double {
        guard elapsed >= Self.pauseEnd else { return 0 }
        let offset = Double(ring) * 0.33
        let phase = ((elapsed - Self.pauseEnd) / 1.1 + offset).truncatingRemainder(dividingBy: 1)
        return (1 - phase) * 0.7
    }

    private var flashOpacity: Double {
        guard !reduceMotion else { return 0 }
        guard elapsed >= Self.swapEnd, elapsed < Self.flashEnd + 0.5 else { return 0 }
        if elapsed < Self.flashEnd {
            return min(1, (elapsed - Self.swapEnd) / (Self.flashEnd - Self.swapEnd))
        }
        return max(0, 1 - (elapsed - Self.flashEnd) / 0.5)
    }

    private var revealScale: CGFloat {
        guard !reduceMotion else { return 1 }
        let since = elapsed - Self.flashEnd
        guard since > 0 else { return 0.6 }
        // One overshoot, then settle.
        return 1 + 0.28 * CGFloat(exp(-since * 4) * cos(since * 11))
    }

    private var revealTextOpacity: Double {
        reduceMotion ? 1 : min(1, max(0, (elapsed - Self.flashEnd - 0.25) / 0.4))
    }

    private var sparkleOpacity: Double {
        guard !reduceMotion else { return 0 }
        let since = elapsed - Self.flashEnd
        guard since > 0 else { return 0 }
        return max(0, 1 - since / 1.0)
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let since = max(0, elapsed - Self.flashEnd)
        let angle = Double(index) / 10 * 2 * .pi
        let distance = 24 + since * 70
        return CGSize(width: cos(angle) * distance, height: sin(angle) * distance)
    }
}
