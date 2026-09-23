import EvoBarCore
import SwiftUI

extension LoreText {
  /// Korean when the app runs in Korean, English for every other language.
  var localized: String { resolved(languageCode: Bundle.module.preferredLocalizations.first ?? "en") }
}

extension AppModel {
  var fieldGuideProgress: (discovered: Int, total: Int) {
    guard let lore else { return (0, 0) }
    return FieldGuide.progress(in: lore, instances: animalInstances)
  }
}

/// The field guide for one line: every stage and the prehistoric relatives met
/// on the way up, uncovered by raising a companion that far. A locked page
/// shows only its era, as a hint of what is still to come.
struct FieldGuideSection: View {
  @ObservedObject var model: AppModel
  let animal: AnimalDefinition
  let reachedStage: Int
  @State private var expandedID: String?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  init(model: AppModel, animal: AnimalDefinition, reachedStage: Int, initialExpandedID: String? = nil) {
    self.model = model
    self.animal = animal
    self.reachedStage = reachedStage
    _expandedID = State(initialValue: initialExpandedID)
  }

  private var entries: [LoreEntry] { model.lore?.line(for: animal.id)?.entries ?? [] }
  private var discovered: Int {
    entries.filter { FieldGuide.isDiscovered($0, reachedStage: reachedStage) }.count
  }

  var body: some View {
    if !entries.isEmpty {
      EvoCard {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
              Text(L10n.text("ui.fieldGuide", fallback: "Field guide"))
                .font(.system(size: 12, weight: .semibold))
              Text(L10n.text("ui.fieldGuideHint", fallback: "Discover animals as you grow. Game forms are not a scientific family tree."))
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            EvoBadge(
              title: L10n.format(
                "ui.fieldGuideProgress", fallback: "%lld / %lld discovered",
                Int64(discovered), Int64(entries.count)),
              icon: "book.closed.fill")
          }
          ForEach(entries) { entry in
            FieldGuideRow(
              entry: entry, animal: animal,
              discovered: FieldGuide.isDiscovered(entry, reachedStage: reachedStage),
              isExpanded: expandedID == entry.id
            ) {
              withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) {
                expandedID = expandedID == entry.id ? nil : entry.id
              }
            }
          }
        }
      }
    }
  }
}

private struct FieldGuideRow: View {
  let entry: LoreEntry
  let animal: AnimalDefinition
  let discovered: Bool
  let isExpanded: Bool
  let toggle: () -> Void

  private var tint: Color { Color(hex: animal.themeColorHex) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button(action: toggle) {
        HStack(spacing: 10) {
          thumbnail
          VStack(alignment: .leading, spacing: 2) {
            if discovered {
              Text(entry.name.localized).font(.system(size: 12, weight: .semibold))
              Text(entry.scientificName ?? entry.era.localized)
                .font(.system(size: 10)).italic(entry.scientificName != nil)
                .foregroundStyle(.secondary)
            } else {
              Text(verbatim: "???").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
              Text(entry.era.localized).font(.system(size: 10)).foregroundStyle(.tertiary)
            }
          }
          .lineLimit(1)
          Spacer(minLength: 4)
          if discovered {
            Image(systemName: "chevron.down")
              .font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
              .rotationEffect(.degrees(isExpanded ? 180 : 0))
          } else {
            Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(.tertiary)
          }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(!discovered)
      .accessibilityLabel(accessibilityTitle)
      .accessibilityHint(
        discovered
          ? "" : L10n.format("ui.discoverAtStage", fallback: "Discovered at stage %lld", Int64(entry.stageIndex)))

      if discovered && isExpanded {
        detail.padding(.leading, 50).padding(.bottom, 8)
      }
    }
    .overlay(alignment: .bottom) { Divider().opacity(0.6) }
  }

  private var thumbnail: some View {
    ZStack {
      Circle().fill(tint.opacity(discovered ? 0.12 : 0.05)).frame(width: 40, height: 40)
      if !discovered {
        Image(systemName: "questionmark").font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.tertiary)
      } else if entry.kind == .relative {
        Image(systemName: "fossil.shell.fill").font(.system(size: 17)).foregroundStyle(tint)
      } else if BundledAnimalSpriteStore.hasArtwork(for: animal) {
        AnimalSpriteView(animal: animal, stageIndex: entry.stageIndex, size: 36)
      } else {
        Image(systemName: "pawprint.fill").font(.system(size: 15)).foregroundStyle(tint.opacity(0.6))
      }
    }
  }

  private var detail: some View {
    VStack(alignment: .leading, spacing: 8) {
      EvoBadge(
        title: entry.kind == .relative
          ? L10n.text("ui.relativeKind", fallback: "Real prehistoric relative")
          : L10n.text("ui.stageKind", fallback: "Evolution stage"),
        icon: entry.kind == .relative ? "fossil.shell.fill" : "sparkles",
        tint: entry.kind == .relative ? .secondary : EvoStyle.accent)
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
        GridRow {
          Text(L10n.text("ui.era", fallback: "Era")).foregroundStyle(.tertiary)
          Text(entry.era.localized)
        }
        GridRow {
          Text(L10n.text("ui.region", fallback: "Range")).foregroundStyle(.tertiary)
          Text(entry.region.localized)
        }
        if let size = entry.size {
          GridRow {
            Text(L10n.text("ui.size", fallback: "Size")).foregroundStyle(.tertiary)
            Text(size.label.localized)
          }
        }
      }
      .font(.system(size: 11))
      if let size = entry.size {
        SizeComparison(size: size, tint: tint)
      }
      ForEach(Array(entry.facts.enumerated()), id: \.offset) { _, fact in
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Circle().fill(tint).frame(width: 4, height: 4).offset(y: -2)
          Text(fact.localized).font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
        }
      }
      VStack(alignment: .leading, spacing: 3) {
        Text(L10n.text("ui.fieldNote", fallback: "Field note"))
          .font(.system(size: 9, weight: .semibold)).foregroundStyle(tint)
          .textCase(.uppercase)
        Text(entry.note.localized).font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
    }
    .accessibilityElement(children: .combine)
  }

  private var accessibilityTitle: String {
    if discovered {
      return [entry.name.localized, entry.scientificName ?? "", entry.era.localized]
        .filter { !$0.isEmpty }.joined(separator: ", ")
    }
    return L10n.text("ui.undiscovered", fallback: "Not discovered yet") + ", " + entry.era.localized
  }
}

/// The animal drawn to scale beside a 1.7 m person: a horizontal bar for a
/// length or wingspan, a vertical one for shoulder height, so a mammoth
/// towers and a kitten barely registers, which is the point.
private struct SizeComparison: View {
  let size: LoreSize
  let tint: Color
  private let human = 1.7
  private let pointsPerMeter: Double = 20
  private let maxHeight: Double = 70

  private var scale: Double {
    size.measure == .shoulder ? min(pointsPerMeter, maxHeight / max(size.meters, human)) : pointsPerMeter
  }
  private var rowHeight: CGFloat {
    CGFloat(max(human, size.measure == .shoulder ? size.meters : 0) * scale) + 16
  }

  var body: some View {
    GeometryReader { geometry in
      let available = Double(geometry.size.width) - 48
      let horizontal = size.measure == .shoulder ? 0 : min(available, size.meters * scale)
      HStack(alignment: .bottom, spacing: 10) {
        VStack(spacing: 2) {
          Image(systemName: "figure.stand").resizable().scaledToFit()
            .frame(height: CGFloat(human * scale)).foregroundStyle(.secondary)
          Text(verbatim: "1.7 m").font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
        }
        if size.measure == .shoulder {
          VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3).fill(tint.opacity(0.75))
              .frame(width: 22, height: CGFloat(size.meters * scale))
            Text(verbatim: formatted(size.meters)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
          }
        } else {
          VStack(alignment: .leading, spacing: 2) {
            Capsule().fill(tint.opacity(0.75)).frame(width: CGFloat(max(4, horizontal)), height: 8)
            Text(verbatim: formatted(size.meters)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
          }
          .padding(.bottom, 10)
        }
      }
    }
    .frame(height: rowHeight)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.text("ui.humanScale", fallback: "Beside a 1.7 m person") + ", " + size.label.localized)
  }

  private func formatted(_ meters: Double) -> String {
    meters < 1 ? "\(Int((meters * 100).rounded())) cm" : "\(meters.formatted(.number.precision(.fractionLength(0...1)))) m"
  }
}
