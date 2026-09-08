import AppKit
import EvoBarCore
import SwiftUI

/// Shared dimensions and semantic surfaces for the popover and detached window.
enum EvoStyle {
  static let width: CGFloat = 420
  static let height: CGFloat = 700
  static let accent = Color(
    nsColor: NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        ? NSColor(srgbRed: 0.36, green: 0.76, blue: 0.67, alpha: 1)
        : NSColor(srgbRed: 0.14, green: 0.46, blue: 0.39, alpha: 1)
    })
  static let actionFill = Color(red: 0.14, green: 0.46, blue: 0.39)
  static let background = Color(nsColor: .windowBackgroundColor)
  static let surface = Color(nsColor: .controlBackgroundColor)
  static let border = Color.primary.opacity(0.075)
  static let inset: CGFloat = 16

  static func providerColor(_ provider: ProviderID) -> Color {
    provider == .claudeCode ? Color(red: 0.76, green: 0.44, blue: 0.30) : accent
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
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(tint?.opacity(0.24) ?? EvoStyle.border)
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
      .frame(minHeight: 32)
      .foregroundStyle(prominent ? Color.white : Color.primary)
      .background(
        prominent ? EvoStyle.actionFill : Color.primary.opacity(0.055),
        in: RoundedRectangle(cornerRadius: 9)
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
      Capsule().fill(Color.primary.opacity(0.07))
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
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isSelected ? EvoStyle.accent : isHovering ? .primary : .secondary)
        .frame(width: 28, height: 28)
        .background(
          isSelected ? EvoStyle.accent.opacity(0.10) : isHovering ? Color.primary.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 7))
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .help(label)
    .accessibilityLabel(label)
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
          revealed
            ? L10n.stage(stage) : L10n.text("ui.undiscovered", fallback: "Not discovered yet"))
      }
    }
  }
}

extension Notification.Name {
  static let evoBarOpenWindow = Notification.Name("EvoBar.openWindow")
}
