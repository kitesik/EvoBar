import AppKit
import EvoBarCore
import EvoBarEvolution
import SwiftUI

/// One companion's life on a single card, for keeping or showing. It is not a
/// panel surface: it is drawn once at a fixed size, written to a PNG, and never
/// scrolled, so everything on it has to fit and nothing on it can be tapped.
struct CompanionCardView: View {
  let animal: AnimalDefinition
  let instance: AnimalInstance
  let stage: EvolutionStageDefinition?
  /// Only companion milestones may leave the app on this card. In particular,
  /// never accept arbitrary journal text that could include work statistics.
  private var journal: [JournalEntry] {
    CompanionJournal.cardEntries(for: instance, animal: animal)
  }

  /// Tall enough for the journal lines below the figures without clipping
  /// the dates that close the card.
  static let size = CGSize(width: 420, height: 620)

  private var togetherDays: Int {
    let end = instance.graduatedAt ?? Date()
    let days = Calendar.current.dateComponents(
      [.day], from: Calendar.current.startOfDay(for: instance.createdAt),
      to: Calendar.current.startOfDay(for: end)).day ?? 0
    return max(1, days + 1)
  }

  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        LinearGradient(
          colors: [
            Color(hex: animal.themeColorHex).opacity(0.42),
            Color(hex: animal.themeColorHex).opacity(0.10),
          ],
          startPoint: .top, endPoint: .bottom)
        VStack(spacing: 10) {
          FinalPortraitView(
            animal: animal, stageIndex: instance.acknowledgedStageIndex,
            isShiny: instance.isShiny, size: 150)
          HStack(spacing: 6) {
            Text(instance.name)
              .font(.system(size: 27, weight: .bold, design: .rounded))
              .lineLimit(2).minimumScaleFactor(0.7)
              .multilineTextAlignment(.center)
              .frame(maxWidth: 220)
              .fixedSize(horizontal: false, vertical: true)
            if instance.isShiny {
              Image(systemName: "sparkles").font(.system(size: 17))
                .foregroundStyle(CareBurstLayer.gold)
            }
          }
          Text(stage.map(L10n.stage) ?? L10n.animal(animal))
            .font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
      }
      .frame(height: 300)

      VStack(spacing: 14) {
        HStack(spacing: 7) {
          EvoBadge(title: L10n.animal(animal), tint: Color(hex: animal.themeColorHex))
          EvoBadge(title: L10n.nature(instance.natureID), tint: .secondary)
          if instance.rarity != .common {
            EvoBadge(title: L10n.rarity(instance.rarity), tint: EvoStyle.rarityColor(instance.rarity))
          }
        }

        figure(
          L10n.format("card.days", fallback: "%lld days", Int64(togetherDays)),
          L10n.text("card.together", fallback: "Together"))
        Text(L10n.natureFlavor(instance.natureID))
          .font(.system(size: 12)).foregroundStyle(.secondary)
          .multilineTextAlignment(.center).lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)

        if !journal.isEmpty {
          Divider().overlay(EvoStyle.border)
          VStack(alignment: .leading, spacing: 5) {
            // Five milestones keep birth and the latest chapters visible.
            ForEach(journal) { entry in
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: entry.symbol).font(.system(size: 9))
                  .foregroundStyle(EvoStyle.accent).frame(width: 13)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                  .font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary)
                  .monospacedDigit().frame(width: 84, alignment: .leading)
                Text(entry.text).font(.system(size: 10)).lineLimit(1)
                Spacer(minLength: 0)
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer(minLength: 0)

        HStack {
          Text(verbatim: "EvoBar")
          Spacer()
          Text(instance.createdAt.formatted(date: .abbreviated, time: .omitted))
          Spacer()
          if let graduated = instance.graduatedAt {
            Text(L10n.text("GRADUATED"))
            Spacer()
            Text(graduated.formatted(date: .abbreviated, time: .omitted))
          }
        }
        .font(.system(size: 10)).foregroundStyle(.tertiary).monospacedDigit()
      }
      .padding(18)
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .background(EvoStyle.background)
  }

  private func figure(_ value: String, _ label: String) -> some View {
    VStack(spacing: 3) {
      Text(value).font(.system(size: 19, weight: .semibold, design: .rounded)).monospacedDigit()
      Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

enum CompanionCardExporter {
  enum ExportError: Error { case renderFailed }

  /// Draws the card once, off screen, and returns it as PNG data. The same
  /// approach the review renderer uses, at the card's own fixed size.
  @MainActor
  static func png(for card: CompanionCardView) throws -> Data {
    let size = CompanionCardView.size
    let host = NSHostingView(
      rootView: card
        .tint(EvoStyle.accent)
        .environment(\.colorScheme, .dark)
        .transaction { $0.disablesAnimations = true })
    host.appearance = NSAppearance(named: .darkAqua)
    host.frame = NSRect(origin: .zero, size: size)
    let window = NSWindow(
      contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = host
    window.appearance = host.appearance
    host.layoutSubtreeIfNeeded()
    defer { window.contentView = nil }
    guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
      throw ExportError.renderFailed
    }
    host.cacheDisplay(in: host.bounds, to: bitmap)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
      throw ExportError.renderFailed
    }
    return data
  }

  /// A file name that says whose card it is without carrying anything else.
  static func fileName(for instance: AnimalInstance) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let name = instance.name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
    let trimmed = String(name).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return "EvoBar-\(trimmed.isEmpty ? "companion" : trimmed).png"
  }
}
