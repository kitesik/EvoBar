import EvoBarCore
import EvoBarEvolution
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
          if model.shinyCount > 0 {
            EvoBadge(title: "\(model.shinyCount)", icon: "sparkles", tint: CareBurstLayer.gold)
              .help(L10n.text("ui.shinyCount", fallback: "Shiny companions"))
          }
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

        if let discovery = model.hatchDiscovery, model.hatchCeremony == nil {
          HatchDiscoveryCard(model: model, instance: discovery)
        }
        if !model.incubator.isEmpty || model.randomEggCount > 0
          || !model.waitingCompanions.isEmpty {
          IncubatorCard(model: model)
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
    let instance = CompanionDisplaySelection.representativeInstance(for: animal.id, in: model.animalInstances)
    let current = animal.id == model.currentAnimalID
    let artwork = BundledAnimalSpriteStore.hasArtwork(for: animal)
    return VStack(spacing: 8) {
      HStack {
        Text(String(format: "%02d", animal.sortOrder)).font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.tertiary)
        if animal.hatchProfile.rarity != .common {
          EvoBadge(
            title: L10n.rarity(animal.hatchProfile.rarity),
            tint: EvoStyle.rarityColor(animal.hatchProfile.rarity))
        }
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
        HStack(spacing: 3) {
          Text(owned ? (instance?.name ?? L10n.animal(animal)) : L10n.animal(animal))
            .font(.system(size: 12, weight: .semibold)).lineLimit(1)
          if owned, instance?.isShiny == true {
            Image(systemName: "sparkles").font(.system(size: 9)).foregroundStyle(CareBurstLayer.gold)
          }
        }
        Text(
          current
            ? L10n.text("Growing companion")
            : instance?.isResting == true
              ? L10n.text("switch.resting", fallback: "Resting")
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
    .accessibilityLabel(CollectionAccessibility.summary(
      animal: animal, instance: instance, owned: owned, current: current, artwork: artwork))
  }
}

enum CollectionAccessibility {
  static func summary(
    animal: AnimalDefinition, instance: AnimalInstance?, owned: Bool, current: Bool, artwork: Bool
  ) -> String {
    let status = current && owned ? L10n.text("Growing companion")
      : owned ? L10n.text("Owned") : L10n.text("ui.discoverInShop", fallback: "Discover in Shop")
    let availability = !artwork ? L10n.text("shop.comingSoon", fallback: "Coming soon")
      : owned && instance == nil ? L10n.text("ui.unhatched", fallback: "Waiting to hatch") : ""
    let progress: String
    if owned, let instance {
      progress = L10n.format("ui.stageOf", fallback: "Stage %lld / %lld",
                            Int64(instance.acknowledgedStageIndex), Int64(animal.stages.count))
    } else {
      progress = ""
    }
    return [L10n.animal(animal), owned ? (instance?.name ?? "") : "", status, availability, progress]
      .filter { !$0.isEmpty }.joined(separator: ", ")
  }
}

struct CompanionDetailView: View {
  @ObservedObject var model: AppModel
  let animal: AnimalDefinition
  @Environment(\.dismiss) private var dismiss
  @Environment(\.companionPanelSize) private var panelSize
  @State private var naming: AnimalInstance?
  @State private var chosenName = ""

  /// Raising one that waits needs a name first; one that only rested keeps its own.
  private func raise(_ instance: AnimalInstance) {
    if instance.isWaitingToBeRaised {
      chosenName = instance.name
      naming = instance
    } else {
      model.raiseCompanion(instanceID: instance.id)
      dismiss()
    }
  }

  private var instances: [AnimalInstance] {
    model.animalInstances.filter { $0.definitionID == animal.id }.sorted {
      $0.createdAt > $1.createdAt
    }
  }
  private var owned: Bool { model.ownedAnimalIDs.contains(animal.id) }
  private var representative: AnimalInstance? {
    CompanionDisplaySelection.representativeInstance(for: animal.id, in: instances)
  }
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
              AnimalSpriteView(animal: animal, stageIndex: discoveredStage,
                               isShiny: representative?.isShiny ?? false, size: 72)
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
              EvolutionJourney(animal: animal, discoveredStage: discoveredStage,
                               isShiny: representative?.isShiny ?? false)
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
            CompanionRecordCard(
              model: model, animal: animal, instance: instance,
              onRaise: { raise(instance) })
          }
        }.padding(14)
      }
    }
    .frame(width: min(EvoStyle.width, panelSize.width), height: min(500, panelSize.height))
    .background(EvoStyle.background)
    .tint(EvoStyle.accent)
    .alert(
      L10n.text("switch.nameTitle", fallback: "Name your new companion"),
      isPresented: Binding(get: { naming != nil }, set: { if !$0 { naming = nil } })
    ) {
      TextField(
        L10n.text("New companion name"),
        text: Binding(get: { chosenName }, set: { chosenName = String($0.prefix(24)) }))
      Button(L10n.text("switch.start", fallback: "Start raising this one")) {
        if let naming {
          model.raiseCompanion(instanceID: naming.id, name: chosenName)
        }
        naming = nil
        dismiss()
      }
      Button(L10n.text("Not yet"), role: .cancel) { naming = nil }
    } message: {
      Text(
        L10n.text(
          "switch.explain",
          fallback:
            "The one growing now steps aside and keeps everything it earned. You can go back to it whenever you like."
        ))
    }
  }
}


/// One individual's record: who it is, what it has done, and what can be done
/// with it. Its own view because the detail sheet that holds a list of these
/// had grown past what the type checker will finish in one expression.
struct CompanionRecordCard: View {
  @ObservedObject var model: AppModel
  let animal: AnimalDefinition
  let instance: AnimalInstance
  let onRaise: () -> Void

  private var stage: EvolutionStageDefinition? {
    animal.stages.first { $0.index == instance.acknowledgedStageIndex }
  }

  private var togetherDays: Int {
    let calendar = Calendar.current
    let days = calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: instance.createdAt),
      to: calendar.startOfDay(for: Date())).day ?? 0
    return max(1, days + 1)
  }

  var body: some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 8) {
        header
        Text(instance.createdAt.formatted(date: .abbreviated, time: .omitted))
          .font(.caption).foregroundStyle(.secondary)
        badges
        Text(L10n.natureFlavor(instance.natureID))
          .font(.caption2).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        HStack {
          Text(stage.map(L10n.stage) ?? L10n.animal(animal))
          Spacer()
          Text("\(instance.currentXP) XP").monospacedDigit()
        }.font(.system(size: 12, weight: .medium))
        Text(
          L10n.format(
            "record.together", fallback: "Together %lld days, %@ tokens",
            Int64(togetherDays), AppModel.compactTokens(instance.cumulativeTokens))
        )
        .font(.caption).foregroundStyle(.secondary)
        providers
        CompanionJournalView(
          entries: CompanionJournal.entries(
            for: instance, animal: animal, busiestDay: model.busiestDays[instance.id]))
        actions
      }
    }
  }

  @ViewBuilder private var header: some View {
    HStack {
      Text(instance.name).font(.headline).lineLimit(2)
      Spacer()
      if instance.isCurrent {
        EvoBadge(title: L10n.text("CURRENT"))
      } else if instance.graduatedAt != nil {
        EvoBadge(title: L10n.text("GRADUATED"), tint: .secondary)
      } else if instance.isResting {
        EvoBadge(
          title: L10n.text("switch.resting", fallback: "Resting"), icon: "moon.zzz",
          tint: .secondary)
      } else {
        EvoBadge(
          title: L10n.text("incubator.waiting", fallback: "Waiting to be raised"),
          icon: "oval.portrait", tint: .secondary)
      }
    }
  }

  @ViewBuilder private var badges: some View {
    HStack(spacing: 6) {
      EvoBadge(title: L10n.nature(instance.natureID), tint: .secondary)
      if instance.rarity != .common {
        EvoBadge(title: L10n.rarity(instance.rarity), tint: EvoStyle.rarityColor(instance.rarity))
      }
      if instance.isShiny {
        EvoBadge(
          title: L10n.text("hatch.shiny", fallback: "Shiny"), icon: "sparkles",
          tint: CareBurstLayer.gold)
      }
    }
  }

  @ViewBuilder private var providers: some View {
    ForEach(instance.providerTokens.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { provider in
      HStack {
        Text(EvoStyle.providerName(provider))
        Spacer()
        Text(AppModel.compactTokens(instance.providerTokens[provider] ?? 0)).monospacedDigit()
        Text(Self.sharePercent(instance.providerTokens[provider] ?? 0, of: instance.cumulativeTokens))
          .monospacedDigit().frame(width: 30, alignment: .trailing)
      }.font(.system(size: 10)).foregroundStyle(.secondary)
    }
  }

  @ViewBuilder private var actions: some View {
    if instance.canBeRaisedNext {
      Button(action: onRaise) {
        Label(
          instance.isWaitingToBeRaised
            ? L10n.text("switch.start", fallback: "Start raising this one")
            : L10n.text("switch.resume", fallback: "Raise this one again"),
          systemImage: "arrow.triangle.2.circlepath"
        ).frame(maxWidth: .infinity)
      }
      .buttonStyle(EvoActionStyle(prominent: true))
      .disabled(model.isSwitchingCompanion)
    }
    Button {
      model.exportCompanionCard(instance)
    } label: {
      Label(L10n.text("card.export", fallback: "Save card…"), systemImage: "square.and.arrow.down")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(EvoActionStyle())
    if let message = model.cardExportMessage {
      Text(message).font(.caption2).foregroundStyle(.secondary)
    }
  }

  /// One provider's share of a companion's lifetime tokens, as a whole percent.
  private static func sharePercent(_ value: Int64, of total: Int64) -> String {
    let share = Double(value) / Double(max(1, total)) * 100
    return "\(Int(share.rounded()))%"
  }
}

/// The incubator and whatever it has already hatched. It lives in Collection
/// because that is where the loop it feeds lives: an egg warms on the days you
/// work, opens when chosen, and waits here until the companion being raised
/// finishes and you pick who is next.
struct IncubatorCard: View {
  @ObservedObject var model: AppModel
  var compact = false

  var body: some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Label(
            L10n.text("incubator.title", fallback: "Incubator"), systemImage: "oval.portrait")
            .font(.system(size: 12, weight: .semibold))
          Spacer()
          if model.canPlaceEgg {
            Button(L10n.text("incubator.place", fallback: "Place an egg")) {
              model.placeEggInIncubator()
            }
            .buttonStyle(EvoActionStyle())
          } else if model.randomEggCount > 0 {
            Text(L10n.text("incubator.full", fallback: "The incubator is full."))
              .font(.system(size: 10)).foregroundStyle(.secondary)
          }
        }

        if model.incubator.isEmpty {
          Text(
            L10n.text(
              "incubator.hint",
              fallback: "Work on three different days, then open your surprise. Days off never reset progress.")
          )
          .font(.system(size: 11)).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }

        ForEach(model.incubator) { egg in
          HStack(spacing: 10) {
            EvoEggView(tint: EvoStyle.accent, size: 30).frame(width: 26, height: 30)
            VStack(alignment: .leading, spacing: 4) {
              Text(
                egg.isReady
                  ? L10n.text("incubator.ready", fallback: "Ready to open")
                  : L10n.format(
                    "incubator.remaining", fallback: "%lld more working days",
                    Int64(egg.daysRemaining))
              )
              .font(.system(size: 11, weight: .medium))
              EvoProgressBar(
                value: Double(egg.activeDays) / Double(IncubatingEgg.activeDaysToHatch))
            }
            if egg.isReady {
              Button(L10n.text("incubator.open", fallback: "Open egg")) {
                model.openEgg(id: egg.id)
              }
              .buttonStyle(EvoActionStyle(prominent: true))
              .disabled(model.isHatchingEgg || model.isAbsorbing || model.isEvolving || model.isGraduating || model.hatchDiscovery != nil)
              .accessibilityIdentifier("incubator.open.\(egg.id)")
            }
          }
          .accessibilityElement(children: .contain)
        }

        if !compact, !model.waitingCompanions.isEmpty {
          Divider().overlay(EvoStyle.border)
          Text(L10n.text("incubator.waiting", fallback: "Waiting to be raised"))
            .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
          ForEach(model.waitingCompanions) { instance in
            if let animal = model.catalog?.animals.first(where: { $0.id == instance.definitionID }) {
              HStack(spacing: 10) {
                AnimalSpriteView(animal: animal, stageIndex: 1, isShiny: instance.isShiny, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                  HStack(spacing: 4) {
                    Text(L10n.animal(animal)).font(.system(size: 12, weight: .semibold))
                    if instance.isShiny {
                      Image(systemName: "sparkles").font(.system(size: 9))
                        .foregroundStyle(CareBurstLayer.gold)
                    }
                  }
                  Text(L10n.nature(instance.natureID))
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                if instance.rarity != .common {
                  EvoBadge(
                    title: L10n.rarity(instance.rarity),
                    tint: EvoStyle.rarityColor(instance.rarity))
                }
              }
              .accessibilityElement(children: .combine)
            }
          }
        }

        if let message = model.incubatorMessage {
          Text(message).font(.caption2).foregroundStyle(.secondary)
        }
      }
    }
  }
}
