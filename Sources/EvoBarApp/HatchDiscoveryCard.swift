import EvoBarCore
import SwiftUI

/// No countdown: the player decides when to leave the discovery moment.
struct HatchDiscoveryCard: View {
  @ObservedObject var model: AppModel
  let instance: AnimalInstance

  var body: some View {
    if let animal = model.catalog?.animals.first(where: { $0.id == instance.definitionID }) {
      EvoCard(tint: EvoStyle.rarityColor(instance.rarity)) {
        VStack(alignment: .leading, spacing: 10) {
          Label(
            model.hatchIsNewDiscovery
              ? L10n.text("hatch.newDiscovery", fallback: "A new discovery!")
              : L10n.text("hatch.newFriend", fallback: "A new individual, a new story"),
            systemImage: model.hatchIsNewDiscovery ? "sparkles" : "heart.fill")
            .font(.system(size: 13, weight: .semibold))
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
