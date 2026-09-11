import EvoBarCore
import SwiftUI

struct JournalEntry: Identifiable, Equatable {
  let id: String
  let date: Date
  let symbol: String
  let text: String
}

/// An individual's life in dated lines: hatched, first growth, each stage, the
/// busiest day, the day the bond reached its top, the first golden roll, the
/// final form, graduation. Read off the record, nothing is stored for it that
/// the store does not already keep.
@MainActor enum CompanionJournal {
  static func entries(
    for instance: AnimalInstance, animal: AnimalDefinition, busiestDay: UsageRecordDay?
  ) -> [JournalEntry] {
    var entries: [JournalEntry] = []
    let firstForm = animal.stages.first.map(L10n.stage) ?? L10n.animal(animal)
    entries.append(
      JournalEntry(
        id: "born", date: instance.createdAt, symbol: instance.isShiny ? "sparkles" : "circle.dotted",
        text: instance.isShiny
          ? L10n.format("journal.bornShiny", fallback: "Hatched shiny, as %@", firstForm)
          : L10n.format("journal.born", fallback: "Hatched as %@", firstForm)))
    if let date = instance.firstGrowthAt {
      entries.append(
        JournalEntry(
          id: "growth", date: date, symbol: "leaf",
          text: L10n.text("journal.firstGrowth", fallback: "First growth arrived")))
    }
    for (stage, date) in instance.evolutionDates.sorted(by: { $0.key < $1.key }) {
      let name = animal.stages.first { $0.index == stage }.map(L10n.stage) ?? "\(stage)"
      entries.append(
        JournalEntry(
          id: "stage-\(stage)", date: date, symbol: "arrow.up.circle",
          text: L10n.format("journal.evolved", fallback: "Became %@", name)))
    }
    if let busiestDay, busiestDay.tokens > 0 {
      entries.append(
        JournalEntry(
          id: "busiest", date: busiestDay.date, symbol: "flame",
          text: L10n.format(
            "journal.busiest", fallback: "Busiest day, %@ tokens", AppModel.compactTokens(busiestDay.tokens))))
    }
    if let date = instance.adoringAt {
      entries.append(
        JournalEntry(
          id: "adoring", date: date, symbol: "heart.fill",
          text: L10n.text("journal.adoring", fallback: "Became inseparable")))
    }
    if let date = instance.firstGoldenAt {
      entries.append(
        JournalEntry(
          id: "golden", date: date, symbol: "star.fill",
          text: L10n.text("journal.golden", fallback: "First golden growth")))
    }
    if let date = instance.finalEvolutionAt {
      entries.append(
        JournalEntry(
          id: "final", date: date, symbol: "crown",
          text: L10n.text("journal.finalForm", fallback: "Reached the final form")))
    }
    if let date = instance.graduatedAt {
      entries.append(
        JournalEntry(
          id: "graduated", date: date, symbol: "graduationcap",
          text: L10n.text("journal.graduated", fallback: "Graduated into the collection")))
    }
    return entries.sorted { $0.date < $1.date }
  }
}

struct CompanionJournalView: View {
  let entries: [JournalEntry]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(L10n.text("journal.title", fallback: "Journal"))
        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
      ForEach(entries) { entry in
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Image(systemName: entry.symbol).font(.system(size: 10))
            .foregroundStyle(EvoStyle.accent).frame(width: 14)
          Text(entry.date.formatted(date: .abbreviated, time: .omitted))
            .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
            .monospacedDigit().frame(width: 78, alignment: .leading)
          Text(entry.text).font(.system(size: 11)).lineLimit(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.date.formatted(date: .abbreviated, time: .omitted)), \(entry.text)")
      }
    }
    .padding(.top, 4)
  }
}
