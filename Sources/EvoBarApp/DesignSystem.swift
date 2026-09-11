import AppKit
import EvoBarCore
import SwiftUI

/// Shared dimensions and surfaces for the panel. The panel is always dark
/// glass: the popover and the detached HUD panel let the desktop show through,
/// so surfaces are white tints rather than opaque system colors.
enum EvoStyle {
  static let width: CGFloat = 360
  static let height: CGFloat = 540
  static let accent = Color(red: 0.40, green: 0.78, blue: 0.68)
  /// Laid over the HUD material of the popover or the detached panel. The
  /// material does the frosting; this only keeps a bright wallpaper from
  /// washing the text out, so it stays thin enough for the desktop to read
  /// through.
  static let glass = Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.34)
  /// Cards read as a lit pane of glass: brighter toward the light, a hairline edge.
  static var cardFill: LinearGradient {
    LinearGradient(
      colors: [Color.white.opacity(0.13), Color.white.opacity(0.05)],
      startPoint: .topLeading, endPoint: .bottomTrailing)
  }
  static var hairline: LinearGradient {
    LinearGradient(
      colors: [Color.white.opacity(0.32), Color.white.opacity(0.08)],
      startPoint: .topLeading, endPoint: .bottomTrailing)
  }
  /// Opaque stand-in for the glass where there is none: sheets, the standalone
  /// Settings window and review renders.
  static let background = Color(red: 0.13, green: 0.13, blue: 0.14)
  static let surface = Color.white.opacity(0.06)
  static let border = Color.white.opacity(0.08)
  static let inset: CGFloat = 12

  /// One colour per rarity, used for badges and for the light an egg gives off.
  static func rarityColor(_ rarity: AnimalRarity) -> Color {
    switch rarity {
    case .common: Color.secondary
    case .uncommon: Color(red: 0.45, green: 0.80, blue: 0.50)
    case .rare: Color(red: 0.55, green: 0.62, blue: 1.0)
    case .legendary: Color(red: 1.0, green: 0.78, blue: 0.35)
    }
  }

  static func providerColor(_ provider: ProviderID) -> Color {
    provider == .claudeCode ? Color(red: 0.86, green: 0.54, blue: 0.40) : accent
  }
  static func providerName(_ provider: ProviderID) -> String {
    provider == .claudeCode ? "Claude Code" : provider == .codex ? "Codex" : provider.rawValue
  }
}

struct EvoCard<Content: View>: View {
  var tint: Color? = nil
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(EvoStyle.cardFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(tint.map { AnyShapeStyle($0.opacity(0.45)) } ?? AnyShapeStyle(EvoStyle.hairline))
          .allowsHitTesting(false)
      }
      .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
  }
}

struct EvoBadge: View {
  let title: String
  var icon: String? = nil
  var tint: Color = EvoStyle.accent

  var body: some View {
    HStack(spacing: 4) {
      if let icon { Image(systemName: icon) }
      Text(title).lineLimit(1)
    }
    .font(.system(size: 10, weight: .semibold))
    .foregroundStyle(tint)
    .padding(.horizontal, 7)
    .padding(.vertical, 4)
    .background(tint.opacity(0.10), in: Capsule())
    .help(title)
  }
}

struct EvoActionStyle: ButtonStyle {
  var prominent = false
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 12, weight: .semibold))
      .padding(.horizontal, 12)
      .frame(minHeight: 30)
      .foregroundStyle(prominent ? Color.black.opacity(0.82) : Color.primary)
      .background(
        prominent ? EvoStyle.accent : Color.white.opacity(0.08),
        in: RoundedRectangle(cornerRadius: 8)
      )
      .overlay {
        if !prominent {
          RoundedRectangle(cornerRadius: 8).strokeBorder(EvoStyle.hairline).allowsHitTesting(false)
        }
      }
      .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.42)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

struct EvoProgressBar: View {
  let value: Double
  /// Where the bar will stand once the XP that is waiting has arrived, drawn
  /// as a translucent run ahead of the fill so the amount has a size.
  var preview: Double = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var fraction: Double { clamp(value) }
  private var previewFraction: Double { max(fraction, clamp(preview)) }
  private func clamp(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0 }

  var body: some View {
    GeometryReader { geometry in
      Capsule().fill(Color.white.opacity(0.10))
        .overlay(alignment: .leading) {
          Capsule().fill(EvoStyle.accent.opacity(0.42))
            .frame(width: geometry.size.width * previewFraction)
        }
        .overlay(alignment: .leading) {
          Capsule().fill(EvoStyle.accent)
            .frame(width: geometry.size.width * fraction)
        }
    }
    .frame(height: 6)
    .animation(reduceMotion ? nil : .smooth(duration: 0.9), value: fraction)
    .animation(reduceMotion ? nil : .smooth(duration: 0.9), value: previewFraction)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.text("Growth"))
    .accessibilityValue("\(Int(fraction * 100))%")
  }
}

struct EvoIconButton: View {
  let symbol: String
  let label: String
  var isSelected = false
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(isSelected ? EvoStyle.accent : isHovering ? .primary : .secondary)
        .frame(width: 26, height: 26)
        .background(
          isSelected ? EvoStyle.accent.opacity(0.12) : isHovering ? Color.white.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .help(label)
    .accessibilityLabel(label)
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }
}

/// Action results stay outside scrolling content and can be dismissed without
/// touching the operation or any persisted usage, ownership, or companion data.
struct EvoFeedbackBanner: View {
  let message: String
  let dismiss: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Label(message, systemImage: "info.circle")
        .font(.system(size: 11))
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
      EvoIconButton(
        symbol: "xmark", label: L10n.text("ui.dismissMessage", fallback: "Dismiss message"),
        action: dismiss)
        .accessibilityIdentifier("feedback.dismiss")
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(EvoStyle.surface)
    .overlay(alignment: .top) { Divider() }
  }
}

/// Every stage keeps its own label; undiscovered forms never reveal artwork, and
/// a stage still borrowing a neighbour's sprite is drawn with a dashed edge.
struct EvolutionJourney: View {
  let animal: AnimalDefinition
  let discoveredStage: Int
  var preview = false
  var isShiny = false

  private var compact: Bool { animal.stages.count > 6 }

  var body: some View {
    HStack(spacing: compact ? 3 : 4) {
      ForEach(animal.stages, id: \.index) { stage in
        let revealed = stage.index <= discoveredStage || (preview && stage.index < animal.stages.count)
        let ownArt = BundledAnimalSpriteStore.hasArtwork(for: animal, stageIndex: stage.index)
        VStack(spacing: 4) {
          ZStack {
            RoundedRectangle(cornerRadius: 9)
              .fill(
                stage.index == discoveredStage
                  ? EvoStyle.accent.opacity(0.12) : Color.white.opacity(0.05))
            if revealed, BundledAnimalSpriteStore.hasArtwork(for: animal) {
              AnimalSpriteView(animal: animal, stageIndex: stage.index,
                               isShiny: isShiny, size: compact ? 28 : 36)
                .opacity(ownArt ? 1 : 0.6)
            } else {
              Image(systemName: "lock.fill")
                .font(.system(size: compact ? 10 : 12))
                .foregroundStyle(.tertiary)
            }
          }
          .frame(height: compact ? 36 : 44)
          .overlay {
            if stage.index == discoveredStage {
              RoundedRectangle(cornerRadius: 9).strokeBorder(EvoStyle.accent.opacity(0.5))
            } else if revealed, !ownArt {
              RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
          }
          Text(String(stage.index))
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(stage.index == discoveredStage ? EvoStyle.accent : .secondary)
        }
        .frame(maxWidth: .infinity)
        .help(helpText(for: stage, revealed: revealed, ownArt: ownArt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          L10n.format("ui.stageOf", fallback: "Stage %lld / %lld", Int64(stage.index), Int64(animal.stages.count))
            + ", " + helpText(for: stage, revealed: revealed, ownArt: ownArt))
      }
    }
  }

  private func helpText(for stage: EvolutionStageDefinition, revealed: Bool, ownArt: Bool) -> String {
    guard revealed else { return L10n.text("ui.undiscovered", fallback: "Not discovered yet") }
    let name = L10n.stage(stage)
    return ownArt || !BundledAnimalSpriteStore.hasArtwork(for: animal)
      ? name : name + ", " + L10n.text("ui.artPending", fallback: "New look coming")
  }
}

/// An egg stands in for every form a line has not shown yet: the shop and the
/// collection never reveal a companion before it hatches.
struct EvoEggView: View {
  let tint: Color
  let size: CGFloat

  var body: some View {
    ZStack {
      EggShape()
        .fill(
          LinearGradient(
            colors: [tint.opacity(0.85), tint.opacity(0.45)], startPoint: .topLeading,
            endPoint: .bottomTrailing))
      EggShape().stroke(Color.white.opacity(0.35), lineWidth: 1)
      ForEach(Array(speckles.enumerated()), id: \.offset) { _, speckle in
        Circle().fill(Color.white.opacity(0.28))
          .frame(width: size * speckle.scale, height: size * speckle.scale)
          .offset(x: size * speckle.x, y: size * speckle.y)
      }
    }
    .frame(width: size * 0.78, height: size)
    .accessibilityHidden(true)
  }

  private var speckles: [(x: CGFloat, y: CGFloat, scale: CGFloat)] {
    [(-0.14, -0.18, 0.11), (0.12, -0.02, 0.08), (-0.04, 0.2, 0.09)]
  }
}

struct EggShape: Shape {
  func path(in rect: CGRect) -> Path {
    let w = rect.width
    let h = rect.height
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addCurve(
      to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.62),
      control1: CGPoint(x: rect.minX + w * 0.86, y: rect.minY),
      control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.30))
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY),
      control1: CGPoint(x: rect.maxX, y: rect.maxY),
      control2: CGPoint(x: rect.minX + w * 0.72, y: rect.maxY))
    path.addCurve(
      to: CGPoint(x: rect.minX, y: rect.minY + h * 0.62),
      control1: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY),
      control2: CGPoint(x: rect.minX, y: rect.maxY))
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.minY),
      control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.30),
      control2: CGPoint(x: rect.minX + w * 0.14, y: rect.minY))
    path.closeSubpath()
    return path
  }
}

extension Notification.Name {
  static let evoBarOpenWindow = Notification.Name("EvoBar.openWindow")
}
