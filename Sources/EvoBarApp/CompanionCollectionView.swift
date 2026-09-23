import EvoBarCore
import EvoBarEvolution
import SwiftUI

private struct CollectionIndividual: Identifiable {
  let animal: AnimalDefinition
  let instance: AnimalInstance
  var id: UUID { instance.id }
}

private struct CollectionSelection: Identifiable {
  let animal: AnimalDefinition
  let instanceID: UUID?
  var id: String { "\(animal.id.rawValue):\(instanceID?.uuidString ?? "line")" }
}

struct CompanionCollectionView: View {
  @ObservedObject var model: AppModel
  @State private var search = ""
  @State private var discoveredOnly = false
  @State private var selectedCompanion: CollectionSelection?
  @State private var selectedShopAnimal: AnimalDefinition?
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.format("collection.metCount", fallback: "%lld / %lld companions met",
                            Int64(model.collectionProgress.discoveredLineIDs.count),
                            Int64(model.collectionProgress.totalLines)))
              .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text(L10n.format("collection.formCount", fallback: "%lld / %lld forms discovered",
                            Int64(model.collectionProgress.discoveredForms),
                            Int64(model.collectionProgress.totalForms)))
              .font(.system(size: 11)).foregroundStyle(.secondary)
          }
          Spacer()
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
          Toggle(L10n.text("collection.metOnly", fallback: "Met"), isOn: $discoveredOnly)
            .toggleStyle(.button).font(.system(size: 11))
        }

        if let discovery = model.hatchDiscovery, model.hatchCeremony == nil {
          HatchDiscoveryCard(model: model, instance: discovery)
        }
        if !model.incubator.isEmpty || model.randomEggCount > 0 {
          IncubatorCard(model: model)
        }

        if animals.isEmpty {
          ContentUnavailableView.search(text: search).frame(minHeight: 200)
        } else {
          // Two kinds of card, so they get two headings rather than one grid
          // the reader has to sort out from the small print.
          if !visibleIndividuals.isEmpty {
            sectionHeading(
              L10n.text("collection.mine", fallback: "Your companions"), count: visibleIndividuals.count)
            individualGrid
          }
          if !ownedWithoutCompanion.isEmpty {
            Divider().padding(.vertical, 8)
            sectionHeading(
              L10n.text("collection.ownedLines", fallback: "Unlocked lines"),
              count: ownedWithoutCompanion.count)
            grid(ownedWithoutCompanion)
          }
          if !locked.isEmpty {
            Divider().padding(.vertical, 8)
            sectionHeading(L10n.text("Shop"), count: locked.count)
            grid(locked)
          }
        }
      }
      .padding(.horizontal, EvoStyle.inset)
      .padding(.bottom, 16)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if let message = model.switchMessage {
        EvoFeedbackBanner(message: message) { model.switchMessage = nil }
          .background(EvoStyle.background)
          .accessibilityIdentifier("collection.switchFeedback")
      }
    }
    .sheet(item: $selectedCompanion) { selection in
      CompanionDetailView(model: model, animal: selection.animal,
                          focusedInstanceID: selection.instanceID)
    }
    .sheet(item: $selectedShopAnimal) { animal in
      ShopView(model: model).animalPreview(animal) { selectedShopAnimal = nil }
    }
  }

  private var animals: [AnimalDefinition] {
    (model.catalog?.animals ?? []).filter { animal in
      (!discoveredOnly || model.collectionProgress.discoveredLineIDs.contains(animal.id))
        && (search.isEmpty || L10n.animal(animal).localizedCaseInsensitiveContains(search)
          || model.animalInstances.contains {
            $0.definitionID == animal.id && $0.name.localizedCaseInsensitiveContains(search)
          })
    }.sorted { $0.sortOrder < $1.sortOrder }
  }

  private var visibleIndividuals: [CollectionIndividual] {
    let visibleAnimals = Dictionary(uniqueKeysWithValues: animals.map { ($0.id, $0) })
    return model.animalInstances.compactMap { instance in
      guard let animal = visibleAnimals[instance.definitionID],
            search.isEmpty || L10n.animal(animal).localizedCaseInsensitiveContains(search)
              || instance.name.localizedCaseInsensitiveContains(search)
      else { return nil }
      return CollectionIndividual(animal: animal, instance: instance)
    }.sorted {
      if $0.instance.isCurrent != $1.instance.isCurrent { return $0.instance.isCurrent }
      if $0.instance.createdAt != $1.instance.createdAt {
        return $0.instance.createdAt > $1.instance.createdAt
      }
      return $0.id.uuidString < $1.id.uuidString
    }
  }

  private var ownedWithoutCompanion: [AnimalDefinition] {
    animals.filter { animal in
      !model.animalInstances.contains { $0.definitionID == animal.id }
        && model.ownedAnimalIDs.contains(animal.id)
    }
  }

  private var locked: [AnimalDefinition] {
    animals.filter { animal in
      !model.animalInstances.contains { $0.definitionID == animal.id }
        && !model.ownedAnimalIDs.contains(animal.id)
    }
  }

  private func sectionHeading(_ title: String, count: Int) -> some View {
    HStack(spacing: 6) {
      Text(title).font(.system(size: 12, weight: .semibold))
      Text("\(count)").font(.system(size: 11, design: .rounded))
        .foregroundStyle(.secondary).monospacedDigit()
      Spacer()
    }
    .padding(.top, 2)
  }

  private var individualGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ForEach(visibleIndividuals) { individual in
        Button {
          selectedCompanion = CollectionSelection(
            animal: individual.animal, instanceID: individual.instance.id)
        } label: {
          tile(individual.animal, instance: individual.instance)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection.individual.\(individual.id.uuidString)")
      }
    }
  }

  private func grid(_ lines: [AnimalDefinition]) -> some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ForEach(lines) { animal in
        Button {
          if model.ownedAnimalIDs.contains(animal.id)
            || model.animalInstances.contains(where: { $0.definitionID == animal.id }) {
            selectedCompanion = CollectionSelection(animal: animal, instanceID: nil)
          } else {
            selectedShopAnimal = animal
          }
        } label: {
          tile(animal, instance: nil)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection.\(animal.id.rawValue)")
      }
    }
  }

  /// One line per card saying what it is and what can be done with it, so a
  /// card never leaves the reader wondering which of the two it is looking at.
  private func tileCaption(_ animal: AnimalDefinition, instance: AnimalInstance?, artwork: Bool)
    -> String
  {
    guard artwork else { return L10n.text("shop.comingSoon", fallback: "Coming soon") }
    guard let instance else {
      return model.ownedAnimalIDs.contains(animal.id)
        ? L10n.text("collection.noCompanionYet", fallback: "No companion raised yet")
        : L10n.text("ui.discoverInShop", fallback: "Discover in Shop")
    }
    if instance.isCurrent { return L10n.text("Growing companion") }
    if instance.graduatedAt != nil {
      return L10n.text("collection.graduatedCaption", fallback: "Its story is kept in Collection")
    }
    if instance.isResting {
      return L10n.text("collection.restingCaption", fallback: "Resting, ready to raise again")
    }
    return L10n.text("incubator.waiting", fallback: "Waiting to be raised")
  }

  private func tile(_ animal: AnimalDefinition, instance: AnimalInstance?) -> some View {
    let owned = model.ownedAnimalIDs.contains(animal.id) || instance != nil
    let current = instance?.isCurrent == true
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
        Circle().fill(instance == nil ? Color.white.opacity(0.16)
                      : Color(hex: animal.themeColorHex).opacity(0.12)).frame(width: 64, height: 64)
        if owned && artwork, let instance {
          if instance.acknowledgedStageIndex == animal.stages.count {
            FinalPortraitView(
              animal: animal, stageIndex: instance.acknowledgedStageIndex,
              isShiny: instance.isShiny, size: 56)
          } else {
            AnimalSpriteView(
              animal: animal, stageIndex: instance.acknowledgedStageIndex,
              isShiny: instance.isShiny, size: 56)
          }
        } else {
          Color.black.frame(width: 64, height: 64)
            .mask(AnimalSpriteView(animal: animal, stageIndex: 1, size: 64))
          Text("?").font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundStyle(.white)
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
        Text(tileCaption(animal, instance: instance, artwork: artwork))
          .font(.system(size: 10)).foregroundStyle(current ? EvoStyle.accent : .secondary)
          .lineLimit(2).multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
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
      animal: animal, instance: instance,
      owned: owned, current: current, artwork: artwork))
  }
}

enum CollectionAccessibility {
  static func summary(
    animal: AnimalDefinition, instance: AnimalInstance?,
    owned: Bool, current: Bool, artwork: Bool
  ) -> String {
    let status: String
    if current && owned {
      status = L10n.text("Growing companion")
    } else if let instance {
      if instance.graduatedAt != nil {
        status = L10n.text("collection.graduatedCaption", fallback: "Its story is kept in Collection")
      } else if instance.isResting {
        status = L10n.text("collection.restingCaption", fallback: "Resting, ready to raise again")
      } else {
        status = L10n.text("incubator.waiting", fallback: "Waiting to be raised")
      }
    } else {
      status = owned ? L10n.text("collection.lineUnlocked", fallback: "Animal line unlocked")
        : L10n.text("ui.discoverInShop", fallback: "Discover in Shop")
    }
    let availability = !artwork ? L10n.text("shop.comingSoon", fallback: "Coming soon")
      : owned && instance == nil
        ? L10n.text("collection.noCompanionYet", fallback: "No companion raised yet") : ""
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
  let focusedInstanceID: UUID?
  @Environment(\.dismiss) private var dismiss
  @Environment(\.companionPanelSize) private var panelSize
  @State private var naming: AnimalInstance?
  @State private var showingNextCompanion = false
  @State private var lastNamingID: UUID?
  // Native alert fields can retain an empty display on repeat presentation
  // even when the draft binding still has text. Recreate only the input field.
  @State private var namingPresentationID = UUID()
  @State private var chosenName = ""

  init(model: AppModel, animal: AnimalDefinition, focusedInstanceID: UUID? = nil) {
    self.model = model
    self.animal = animal
    self.focusedInstanceID = focusedInstanceID
  }

  /// Raising one that waits needs a name first; one that only rested keeps its own.
  private func raise(_ instance: AnimalInstance) {
    if instance.isWaitingToBeRaised {
      // A failed save must not throw away the name entered for this individual.
      if lastNamingID != instance.id { chosenName = instance.name }
      lastNamingID = instance.id
      namingPresentationID = UUID()
      naming = instance
    } else {
      model.raiseCompanion(instanceID: instance.id) { dismiss() }
    }
  }

  private var instances: [AnimalInstance] {
    model.animalInstances.filter { $0.definitionID == animal.id }.sorted {
      if $0.id == focusedInstanceID { return true }
      if $1.id == focusedInstanceID { return false }
      if $0.isCurrent != $1.isCurrent { return $0.isCurrent }
      if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
      return $0.id.uuidString < $1.id.uuidString
    }
  }
  private var owned: Bool { model.ownedAnimalIDs.contains(animal.id) }
  private var representative: AnimalInstance? {
    CompanionDisplaySelection.representativeInstance(for: animal.id, in: instances)
  }
  /// Nothing is revealed before a companion of the line has hatched.
  private var discoveredStage: Int { model.collectionProgress.reachedStage(for: animal.id) }

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
          if !instances.isEmpty {
            Text(L10n.text("collection.mine", fallback: "Your companions"))
              .font(.system(size: 12, weight: .semibold))
            ForEach(instances) { instance in
              CompanionRecordCard(
                model: model, animal: animal, instance: instance,
                onRaise: { raise(instance) },
                onNext: { showingNextCompanion = true })
            }
          }
          HStack(spacing: 14) {
            if owned, BundledAnimalSpriteStore.hasArtwork(for: animal), discoveredStage > 0 {
              FinalPortraitView(animal: animal, stageIndex: discoveredStage,
                               isShiny: representative?.isShiny ?? false, size: 72)
            } else if owned, BundledAnimalSpriteStore.hasArtwork(for: animal) {
              ZStack {
                Color.black.frame(width: 72, height: 72)
                  .mask(AnimalSpriteView(animal: animal, stageIndex: 1, size: 72))
                Text("?").font(.system(size: 23, weight: .black, design: .rounded))
                  .foregroundStyle(.white)
              }
              .accessibilityLabel(L10n.text("ui.undiscovered", fallback: "Not discovered yet"))
            } else {
              Image(systemName: "pawprint.fill").font(.system(size: 36))
                .foregroundStyle(.tertiary).frame(width: 72, height: 72)
            }
            VStack(alignment: .leading, spacing: 6) {
              Text(L10n.animal(animal)).font(.system(size: 18, weight: .bold, design: .rounded))
              Text(L10n.text(animal.descriptionKey, fallback: animal.fallbackDescription))
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
              if owned && instances.isEmpty {
                Text(L10n.text("collection.noCompanionYet", fallback: "No companion raised yet"))
                  .font(.caption.weight(.medium))
                  .foregroundStyle(.secondary)
              }
            }
          }
          EvoCard {
            VStack(alignment: .leading, spacing: 12) {
              Text(L10n.text("ui.evolutionJourney", fallback: "Evolution journey")).font(
                .system(size: 12, weight: .semibold))
              EvolutionJourney(animal: animal, discoveredStage: discoveredStage,
                               isShiny: representative?.isShiny ?? false)
              if discoveredStage > 0 {
                Text(discoveryHint)
                  .font(.system(size: 11)).foregroundStyle(.secondary)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
          }
          FieldGuideSection(model: model, animal: animal, reachedStage: discoveredStage)
          if owned, discoveredStage > 0, BundledAnimalSpriteStore.hasArtwork(for: animal) {
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
          } else if !owned {
            Button {
              model.selectedSection = .shop
              dismiss()
            } label: {
              Label(L10n.text("ui.exploreShop", fallback: "Explore in Shop"), systemImage: "bag")
                .frame(maxWidth: .infinity)
            }.buttonStyle(EvoActionStyle(prominent: true))
          }
        }.padding(14)
      }
      if let message = model.switchMessage {
        EvoFeedbackBanner(message: message) { model.switchMessage = nil }
          .accessibilityIdentifier("collection.switchFeedback")
      }
    }
    .frame(width: min(EvoStyle.width, panelSize.width), height: min(500, panelSize.height))
    .background(EvoStyle.background)
    .tint(EvoStyle.accent)
    .sheet(isPresented: $showingNextCompanion) { GraduationView(model: model) }
    .alert(
      L10n.text("switch.nameTitle", fallback: "Name your new companion"),
      isPresented: Binding(get: { naming != nil }, set: { if !$0 { naming = nil } })
    ) {
      TextField(
        L10n.text("New companion name"),
        text: $chosenName)
        .id(namingPresentationID)
      Button(L10n.text("switch.start", fallback: "Start raising this one")) {
        if let naming {
          model.raiseCompanion(instanceID: naming.id, name: chosenName) { dismiss() }
        }
        naming = nil
      }
      .disabled(chosenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || model.isSwitchingCompanion)
      Button(L10n.text("Not yet"), role: .cancel) { naming = nil }
    } message: {
      Text(
        L10n.text(
          "switch.explain",
          fallback:
            "The one growing now steps aside and keeps everything it earned. You can go back to it whenever you like."
        ))
    }
    .onChange(of: chosenName) { _, value in
      // Publish the edit, then its correction, so the native field displays
      // the same limited value we submit instead of retaining the raw paste.
      let limited = String(value.prefix(24))
      if value != limited { chosenName = limited }
    }
  }

  private var discoveryHint: String {
    if let next = model.collectionProgress.nextUndiscoveredStage(in: animal) {
      return L10n.format("collection.nextForm", fallback: "Next discovery: stage %lld. Its appearance is still a secret.", Int64(next.index))
    }
    return L10n.text("collection.lineComplete", fallback: "Every form discovered. Each one stays in your collection.")
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
  let onNext: () -> Void

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
        HStack(spacing: 4) {
          Text(L10n.text("record.bornOn", fallback: "Born"))
          Text(instance.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .font(.caption).foregroundStyle(.secondary)
        badges
        Text(L10n.natureFlavor(instance.natureID))
          .font(.caption2).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
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
    HStack(spacing: 12) {
      ZStack {
        Circle().fill(Color(hex: animal.themeColorHex).opacity(0.14))
        if instance.acknowledgedStageIndex == animal.stages.count {
          FinalPortraitView(
            animal: animal, stageIndex: instance.acknowledgedStageIndex,
            isShiny: instance.isShiny, size: 68)
        } else {
          AnimalSpriteView(
            animal: animal, stageIndex: instance.acknowledgedStageIndex,
            isShiny: instance.isShiny, size: 68)
        }
      }
      .frame(width: 72, height: 72)
      .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(instance.name)
          .font(.system(size: 17, weight: .bold, design: .rounded))
          .fixedSize(horizontal: false, vertical: true)
        Text(stage.map(L10n.stage) ?? L10n.animal(animal))
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Spacer(minLength: 2)
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
    if instance.isCurrent && model.isGraduationReady {
      Button(action: onNext) {
        Label(L10n.text("Next companion"), systemImage: "arrow.right")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(EvoActionStyle())
      .accessibilityIdentifier("collection.nextCompanion")
    }
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
          } else if model.randomEggCount > 0, model.incubator.count >= IncubatingEgg.capacity {
            Text(L10n.text("incubator.full", fallback: "The incubator is full."))
              .font(.system(size: 10)).foregroundStyle(.secondary)
          }
        }

        if model.incubator.isEmpty {
          Text(
            L10n.text(
              "incubator.hint",
              fallback: "Work on two different days, then open your surprise. Days off never reset progress.")
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
                value: min(1, Double(egg.activeDays) / Double(IncubatingEgg.activeDaysToHatch)))
            }
            if egg.isReady {
              Button(L10n.text("incubator.open", fallback: "Open egg")) {
                model.openEgg(id: egg.id)
              }
              .buttonStyle(EvoActionStyle(prominent: true))
              .disabled(!model.canOpenEgg)
              .accessibilityIdentifier("incubator.open.\(egg.id)")
            }
          }
          .accessibilityElement(children: .contain)
        }

        if let message = model.incubatorMessage {
          Text(message).font(.caption2).foregroundStyle(.secondary)
        }
      }
    }
  }
}
