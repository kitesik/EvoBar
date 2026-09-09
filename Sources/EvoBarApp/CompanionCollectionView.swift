import EvoBarCore
import SwiftUI

struct CompanionCollectionView: View {
  @ObservedObject var model: AppModel
  @State private var search = ""
  @State private var ownedOnly = false
  @State private var selectedAnimal: AnimalDefinition?
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
          Text("Your companions").font(.system(size: 15, weight: .semibold, design: .rounded))
          Spacer()
          EvoBadge(
            title: "\(model.ownedAnimalIDs.count) / \(model.catalog?.animals.count ?? 10)",
            icon: "pawprint.fill")
          EvoBadge(
            title: "\(model.fieldGuideProgress.discovered) / \(model.fieldGuideProgress.total)",
            icon: "book.closed.fill", tint: .secondary)
            .help(L10n.text("ui.fieldGuide", fallback: "Field guide"))
        }
        HStack(spacing: 8) {
          HStack(spacing: 7) {
            Button { isSearchFocused = true } label: {
              Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("f", modifiers: .command)
            .accessibilityLabel(L10n.text("ui.searchAnimals", fallback: "Find a companion"))
            .help(L10n.text("ui.searchAnimals", fallback: "Find a companion"))
            TextField(L10n.text("ui.searchAnimals", fallback: "Find a companion"), text: $search)
              .textFieldStyle(.plain)
              .focused($isSearchFocused)
              .onExitCommand {
                if search.isEmpty { isSearchFocused = false } else { search = "" }
              }
            if !search.isEmpty {
              Button {
                search = ""
              } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(L10n.text("ui.clearSearch", fallback: "Clear search"))
            }
          }
          .font(.system(size: 12))
          .padding(8)
          .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 8))
          Toggle(L10n.text("Owned"), isOn: $ownedOnly)
            .toggleStyle(.button).font(.system(size: 11))
        }

        if animals.isEmpty {
          ContentUnavailableView.search(text: search).frame(minHeight: 200)
        } else {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(animals) { animal in
              Button {
                selectedAnimal = animal
              } label: {
                tile(animal)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("collection.\(animal.id.rawValue)")
            }
          }
        }
      }
      .padding(.horizontal, EvoStyle.inset)
      .padding(.bottom, 16)
    }
    .scrollIndicators(.hidden)
    .sheet(item: $selectedAnimal) { animal in CompanionDetailView(model: model, animal: animal) }
  }

  private var animals: [AnimalDefinition] {
    (model.catalog?.animals ?? []).filter { animal in
      (!ownedOnly || model.ownedAnimalIDs.contains(animal.id))
        && (search.isEmpty || L10n.animal(animal).localizedCaseInsensitiveContains(search)
          || model.animalInstances.contains {
            $0.definitionID == animal.id && $0.name.localizedCaseInsensitiveContains(search)
          })
    }.sorted { $0.sortOrder < $1.sortOrder }
  }

  private func tile(_ animal: AnimalDefinition) -> some View {
    let owned = model.ownedAnimalIDs.contains(animal.id)
    let instance = model.animalInstances.filter { $0.definitionID == animal.id }
      .max {
        if $0.acknowledgedStageIndex != $1.acknowledgedStageIndex {
          return $0.acknowledgedStageIndex < $1.acknowledgedStageIndex
        }
        if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
        return $0.id.uuidString < $1.id.uuidString
      }
    let current = animal.id == model.currentAnimalID
    let artwork = BundledAnimalSpriteStore.hasArtwork(for: animal)
    return VStack(spacing: 8) {
      HStack {
        Text(String(format: "%02d", animal.sortOrder)).font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.tertiary)
        Spacer()
        if current {
          Circle().fill(EvoStyle.accent).frame(width: 6, height: 6)
        } else if !owned {
          Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(.tertiary)
        }
      }
      ZStack {
        Circle().fill(Color(hex: animal.themeColorHex).opacity(0.12)).frame(width: 64, height: 64)
        if owned && artwork, let instance {
          AnimalSpriteView(
            animal: animal, stageIndex: instance.acknowledgedStageIndex,
            isShiny: instance.isShiny, size: 56)
        } else if owned && artwork {
          EvoEggView(tint: Color(hex: animal.themeColorHex), size: 44)
        } else {
          Image(systemName: "pawprint.fill")
            .font(.system(size: 26)).foregroundStyle(Color.secondary.opacity(0.22))
        }
      }
      VStack(spacing: 3) {
        Text(owned ? (instance?.name ?? L10n.animal(animal)) : L10n.animal(animal))
          .font(.system(size: 12, weight: .semibold)).lineLimit(1)
        Text(
          current
            ? L10n.text("Growing companion")
            : !artwork
              ? L10n.text("shop.comingSoon", fallback: "Coming soon")
              : owned
                ? (instance == nil
                  ? L10n.text("ui.unhatched", fallback: "Waiting to hatch") : L10n.animal(animal))
                : L10n.text("ui.discoverInShop", fallback: "Discover in Shop")
        )
        .font(.system(size: 10)).foregroundStyle(current ? EvoStyle.accent : .secondary)
        .lineLimit(1)
      }
      HStack(spacing: 3) {
        ForEach(animal.stages, id: \.index) { stage in
          Capsule().fill(
            owned && stage.index <= (instance?.acknowledgedStageIndex ?? 0)
              ? EvoStyle.accent : Color.primary.opacity(0.07)
          )
          .frame(maxWidth: 16, minHeight: 3, maxHeight: 3)
        }
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity)
    .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12).strokeBorder(
        current ? EvoStyle.accent.opacity(0.5) : EvoStyle.border)
    )
    .contentShape(RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      [L10n.animal(animal), owned ? (instance?.name ?? "") : "",
       current ? L10n.text("Growing companion") : owned ? L10n.text("Owned") : L10n.text("ui.discoverInShop", fallback: "Discover in Shop"),
       owned ? L10n.format("ui.stageOf", fallback: "Stage %lld / %lld", Int64(instance?.acknowledgedStageIndex ?? 0), Int64(animal.stages.count)) : ""]
        .filter { !$0.isEmpty }.joined(separator: ", "))
  }
}

struct CompanionDetailView: View {
  @ObservedObject var model: AppModel
  let animal: AnimalDefinition
  @Environment(\.dismiss) private var dismiss
  @Environment(\.companionPanelSize) private var panelSize

  private var instances: [AnimalInstance] {
    model.animalInstances.filter { $0.definitionID == animal.id }.sorted {
      $0.createdAt > $1.createdAt
    }
  }
  private var owned: Bool { model.ownedAnimalIDs.contains(animal.id) }
  /// Nothing is revealed before a companion of the line has hatched.
  private var discoveredStage: Int { instances.map(\.acknowledgedStageIndex).max() ?? 0 }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(L10n.animal(animal)).font(.headline)
        Spacer()
        Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
      }.padding(.horizontal, 14).padding(.vertical, 12)
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          HStack(spacing: 14) {
            if owned, BundledAnimalSpriteStore.hasArtwork(for: animal), discoveredStage > 0 {
              AnimalSpriteView(animal: animal, stageIndex: discoveredStage, size: 72)
            } else if owned, BundledAnimalSpriteStore.hasArtwork(for: animal) {
              EvoEggView(tint: Color(hex: animal.themeColorHex), size: 60).frame(width: 72, height: 72)
            } else {
              Image(systemName: "pawprint.fill").font(.system(size: 36))
                .foregroundStyle(.tertiary).frame(width: 72, height: 72)
            }
            VStack(alignment: .leading, spacing: 6) {
              Text(L10n.animal(animal)).font(.system(size: 18, weight: .bold, design: .rounded))
              Text(L10n.text(animal.descriptionKey, fallback: animal.fallbackDescription))
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          EvoCard {
            VStack(alignment: .leading, spacing: 12) {
              Text(L10n.text("ui.evolutionJourney", fallback: "Evolution journey")).font(
                .system(size: 12, weight: .semibold))
              EvolutionJourney(animal: animal, discoveredStage: discoveredStage)
            }
          }
          FieldGuideSection(model: model, animal: animal, reachedStage: discoveredStage)
          if owned, BundledAnimalSpriteStore.hasArtwork(for: animal) {
            Button {
              model.setPinnedAnimalDefinitionID(
                model.pinnedAnimalDefinitionID == animal.id ? nil : animal.id)
            } label: {
              Label(
                model.pinnedAnimalDefinitionID == animal.id
                  ? L10n.text("Use growing companion")
                  : L10n.text("ui.pin", fallback: "Pin to menu bar"),
                systemImage: model.pinnedAnimalDefinitionID == animal.id ? "pin.slash" : "pin"
              ).frame(maxWidth: .infinity)
            }.buttonStyle(EvoActionStyle())
            Text(
              L10n.text(
                "ui.pinHint",
                fallback:
                  "Pinning changes the menu bar companion. Your growing companion keeps its progress."
              )
            )
            .font(.system(size: 10)).foregroundStyle(.secondary)
          } else {
            Button {
              model.selectedSection = .shop
              dismiss()
            } label: {
              Label(L10n.text("ui.exploreShop", fallback: "Explore in Shop"), systemImage: "bag")
                .frame(maxWidth: .infinity)
            }.buttonStyle(EvoActionStyle(prominent: true))
          }
          ForEach(instances) { instance in
            let stage = animal.stages.first { $0.index == instance.acknowledgedStageIndex }
            let togetherDays = max(1, (Calendar.current.dateComponents(
              [.day], from: Calendar.current.startOfDay(for: instance.createdAt),
              to: Calendar.current.startOfDay(for: Date())).day ?? 0) + 1)
            EvoCard {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text(instance.name).font(.headline).lineLimit(2)
                  Spacer()
                  if instance.isCurrent {
                    EvoBadge(title: L10n.text("CURRENT"))
                  } else if instance.graduatedAt != nil {
                    EvoBadge(title: L10n.text("GRADUATED"), tint: .secondary)
                  }
                }
                Text(instance.createdAt.formatted(date: .abbreviated, time: .omitted))
                  .font(.caption).foregroundStyle(.secondary)
                HStack {
                  Text(stage.map(L10n.stage) ?? L10n.animal(animal))
                  Spacer()
                  Text("\(instance.currentXP) XP").monospacedDigit()
                }.font(.system(size: 12, weight: .medium))
                Text("Together \(togetherDays) days, \(AppModel.compactTokens(instance.cumulativeTokens)) tokens")
                  .font(.caption).foregroundStyle(.secondary)
                ForEach(
                  instance.providerTokens.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self
                ) { provider in
                  HStack {
                    Text(EvoStyle.providerName(provider))
                    Spacer()
                    Text(AppModel.compactTokens(instance.providerTokens[provider] ?? 0))
                      .monospacedDigit()
                    Text("\(Int((Double(instance.providerTokens[provider] ?? 0) / Double(max(1, instance.cumulativeTokens)) * 100).rounded()))%")
                      .monospacedDigit().frame(width: 30, alignment: .trailing)
                  }.font(.system(size: 10)).foregroundStyle(.secondary)
                }
                if let final = instance.finalEvolutionAt {
                  Text(
                    L10n.text("Final evolution") + ", "
                      + final.formatted(date: .abbreviated, time: .omitted)
                  )
                  .font(.caption2).foregroundStyle(.secondary)
                }
                if let graduated = instance.graduatedAt {
                  Text("Graduated \(graduated.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2).foregroundStyle(.secondary)
                }
              }
            }
          }
        }.padding(14)
      }
    }
    .frame(width: min(EvoStyle.width, panelSize.width), height: min(500, panelSize.height))
    .background(EvoStyle.background)
    .tint(EvoStyle.accent)
  }
}
