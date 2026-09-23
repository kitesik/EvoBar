import EvoBarCore
import SwiftUI

/// No countdown: the player decides when to leave the discovery moment.
struct HatchDiscoveryCard: View {
  @ObservedObject var model: AppModel
  let instance: AnimalInstance
  @State private var fieldNoteExpanded: Bool

  init(model: AppModel, instance: AnimalInstance, fieldNoteExpanded: Bool = false) {
    self.model = model
    self.instance = instance
    _fieldNoteExpanded = State(initialValue: fieldNoteExpanded)
  }

  var body: some View {
    if let animal = model.catalog?.animals.first(where: { $0.id == instance.definitionID }) {
      EvoCard(tint: EvoStyle.rarityColor(instance.rarity)) {
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 12) {
            AnimalSpriteView(animal: animal, stageIndex: 1, isShiny: instance.isShiny, size: 64)
            VStack(alignment: .leading, spacing: 5) {
              Text(L10n.animal(animal)).font(.headline)
              Text(L10n.nature(instance.natureID)).font(.caption).foregroundStyle(.secondary)
              HStack {
                EvoBadge(title: L10n.rarity(instance.rarity), tint: EvoStyle.rarityColor(instance.rarity))
                if instance.isShiny {
                  EvoBadge(title: L10n.text("hatch.shiny", fallback: "Shiny"), icon: "sparkles", tint: CareBurstLayer.gold)
                }
              }
            }
          }
          Text(L10n.natureFlavor(instance.natureID))
            .font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          if let entry = model.lore?.line(for: animal.id)?.entries.first(where: {
            $0.kind == .stage && $0.stageIndex == 1
          }), let fact = entry.facts.first {
            DisclosureGroup(isExpanded: $fieldNoteExpanded) {
              Text(fact.localized)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            } label: {
              Label(L10n.text("ui.fieldNote", fallback: "Field note"), systemImage: "book.closed")
                .font(.caption)
            }
            .accessibilityIdentifier("hatch.fieldNote")
          }
          Text(L10n.text("hatch.saved", fallback: "Saved to your collection. Your current companion keeps growing; choose when to raise this one."))
            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          HStack {
            Button(L10n.text("hatch.viewCollection", fallback: "View collection")) {
              model.acknowledgeHatch(viewCollection: true)
            }.buttonStyle(EvoActionStyle(prominent: true))
            Button(L10n.text("hatch.continue", fallback: "Keep going")) {
              model.acknowledgeHatch()
            }.buttonStyle(EvoActionStyle())
          }
        }
      }
      .accessibilityIdentifier("hatch.discovery")
    }
  }
}
