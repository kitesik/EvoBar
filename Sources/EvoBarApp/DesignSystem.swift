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
  /// Laid over the popover or HUD material: the desktop still shows through,
  /// but a bright wallpaper cannot wash the panel out.
  static let glass = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.66)
  /// Cards read as a lit pane of glass: brighter toward the light, a hairline edge.
  static var cardFill: LinearGradient {
    LinearGradient(
      colors: [Color.white.opacity(0.11), Color.white.opacity(0.045)],
      startPoint: .topLeading, endPoint: .bottomTrailing)
  }
  static var hairline: LinearGradient {
    LinearGradient(
      colors: [Color.white.opacity(0.26), Color.white.opacity(0.06)],
      startPoint: .topLeading, endPoint: .bottomTrailing)
  }
  /// Opaque stand-in for the glass where there is none: sheets, the standalone
  /// Settings window and review renders.
  static let background = Color(red: 0.13, green: 0.13, blue: 0.14)
  static let surface = Color.white.opacity(0.06)
  static let border = Color.white.opacity(0.08)
  static let inset: CGFloat = 12

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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var fraction: Double { value.isFinite ? min(1, max(0, value)) : 0 }

  var body: some View {
    GeometryReader { geometry in
      Capsule().fill(Color.white.opacity(0.10))
        .overlay(alignment: .leading) {
          Capsule().fill(EvoStyle.accent)
            .frame(width: geometry.size.width * fraction)
        }
    }
    .frame(height: 6)
    .animation(reduceMotion ? nil : .smooth(duration: 0.5), value: fraction)
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

/// Every stage keeps its own label; undiscovered final forms never reveal artwork.
struct EvolutionJourney: View {
  let animal: AnimalDefinition
  let discoveredStage: Int
  var preview = false

  var body: some View {
    HStack(spacing: 4) {
      ForEach(animal.stages, id: \.index) { stage in
        let revealed = stage.index <= discoveredStage || (preview && stage.index < 5)
        VStack(spacing: 5) {
          ZStack {
            RoundedRectangle(cornerRadius: 10)
              .fill(
                stage.index == discoveredStage
                  ? EvoStyle.accent.opacity(0.10) : Color.primary.opacity(0.035))
            if revealed, BundledAnimalSpriteStore.hasArtwork(for: animal) {
              AnimalSpriteView(animal: animal, stageIndex: stage.index, size: 36)
            } else {
              Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            }
          }
          .frame(height: 44)
          .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(
              stage.index == discoveredStage ? EvoStyle.accent.opacity(0.45) : .clear))
          Text(String(stage.index))
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(stage.index == discoveredStage ? EvoStyle.accent : .secondary)
        }
        .frame(maxWidth: .infinity)
        .help(
          revealed
            ? L10n.stage(stage) : L10n.text("ui.undiscovered", fallback: "Not discovered yet")
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          L10n.format("ui.stage", fallback: "Stage %lld / 5", Int64(stage.index)) + ", "
            + (revealed ? L10n.stage(stage) : L10n.text("ui.undiscovered", fallback: "Not discovered yet")))
      }
    }
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
