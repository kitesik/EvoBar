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
  static let glass = Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.78)
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
      .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(tint?.opacity(0.35) ?? EvoStyle.border)
          .allowsHitTesting(false)
      }
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

extension Notification.Name {
  static let evoBarOpenWindow = Notification.Name("EvoBar.openWindow")
}
