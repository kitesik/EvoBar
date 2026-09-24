#if DEBUG
  import AppKit
  import EvoBarCore
  import EvoBarUsage
import EvoBarEvolution
  import SwiftUI

  /// Renders the actual SwiftUI screens using isolated fixture data, never the
  /// user's desktop or logs. Absent from release binaries.
  @MainActor
  enum VisualReviewExporter {
    static func export(model: AppModel, directory: URL) async throws {
      guard model.isIsolatedRun else { return }
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try await verifyStartupRecovery(model: model)
      try await HatchRecoveryReview.verify(renderFirstSession: { firstModel in
        try await render(
          content: CompanionHomeView(model: firstModel, detailsExpanded: true), scheme: .dark,
          path: directory.appendingPathComponent("first-session-growth-egg-dark.png"), height: 1000, width: 328)
      }) { failedModel in
        try await render(
          model: failedModel, scheme: .dark,
          path: directory.appendingPathComponent("hatch-failed-home-dark.png"), height: 374, width: 328)
        try await render(
          model: failedModel, scheme: .dark,
          path: directory.appendingPathComponent("hatch-failed-full-home-dark.png"), height: 600, width: 328)
        try await render(
          content: IncubatorPrompt(model: failedModel).padding(12), scheme: .dark,
          path: directory.appendingPathComponent("hatch-failed-prompt-dark.png"), height: 160, width: 328)
      }
      try await CompanionSwitchReview.verify { failedModel, animal in
        try await render(
          content: CompanionDetailView(model: failedModel, animal: animal), scheme: .dark,
          path: directory.appendingPathComponent("switch-failed-detail-dark.png"), height: 374, width: 328)
        try await render(
          model: failedModel, scheme: .dark,
          path: directory.appendingPathComponent("switch-failed-collection-dark.png"), height: 374, width: 328)
      }
      try verifyCompanionPresentation(model: model)
      // Home shows the final portrait for every active line, including Shiny;
      // a missing file must not quietly fall back to a side-view walk sprite.
      for animal in model.catalog?.animals ?? [] where BundledAnimalSpriteStore.hasArtwork(for: animal) {
        for isShiny in [false, true] {
          let reference = ManifestAnimalAssetProvider().asset(
            for: animal, stageIndex: animal.stages.count,
            isShiny: isShiny, visualState: .idle)
          let name = "\(reference.assetID).front"
          let url = Bundle.module.url(
            forResource: name, withExtension: "png", subdirectory: "FinalPortraits")
            ?? Bundle.module.url(forResource: name, withExtension: "png")
          guard let url, NSImage(contentsOf: url) != nil
          else { throw ReviewError.renderFailed }
        }
      }
      try verifyFeedbackDismissal(model: model)
      try verifyHatchAcknowledgement(model: model)
      try verifyCollectionAccessibility(model: model)
      model.prepareVisualReview()
      let shopItems = model.shopEssentials + model.shopScenery + model.shopExtras
      guard model.shopEssentials.map(\.kind) == [.randomEgg, .treat],
            shopItems.count == model.economy?.items.count,
            Set(shopItems.map(\.id)) == Set(model.economy?.items.map(\.id) ?? []),
            model.shopExtras.allSatisfy({ $0.kind != .randomEgg && $0.kind != .treat && $0.kind != .sceneTheme }),
            Set(model.shopScenery.map(\.id)) == Set(SceneTheme.allCases.map(\.itemID))
      else { throw ReviewError.companionSelectionFailed }
      guard model.collectionProgress.discoveredLineIDs == ["cat", "dog"],
        model.collectionProgress.discoveredForms == 6 else { throw ReviewError.collectionAccessibilityFailed }
      // The panel is dark glass in every system appearance, so one pass suffices.
      for (name, scheme) in [("dark", ColorScheme.dark)] {
        model.prepareVisualReview()
        let previewCoins = model.tokenCoins
        let previewInventory = model.itemInventory
        let previewTheme = model.sceneThemeID
        var previewImages = Set<Data>()
        for theme in SceneTheme.allCases {
          let path = directory.appendingPathComponent("scene-preview-\(theme.rawValue)-\(name).png")
          try await render(content: ShopView(model: model).sceneryPreview(theme, height: 190),
                           scheme: scheme, path: path, height: 190, width: 360)
          guard previewImages.insert(try Data(contentsOf: path)).inserted else { throw ReviewError.renderFailed }
        }
        guard model.tokenCoins == previewCoins, model.itemInventory == previewInventory,
              model.sceneThemeID == previewTheme else { throw ReviewError.companionSelectionFailed }
        for section in AppSection.allCases {
          model.selectedSection = section
          try await render(
            model: model, scheme: scheme,
            path: directory.appendingPathComponent("\(section.rawValue.lowercased())-\(name).png"))
          try await render(
            model: model, scheme: scheme,
            path: directory.appendingPathComponent("compact-\(section.rawValue.lowercased())-\(name).png"),
            height: 374, width: 328)
        }
        for page in SettingsPage.allCases where page != .general {
          model.selectedSettingsPage = page
          try await render(
            content: SettingsView(model: model).padding(.top, 16),
            scheme: scheme,
            path: directory.appendingPathComponent("settings-\(page.rawValue)-\(name).png")
          )
        }
        model.openSettings(page: .tracking)
        try await render(
          content: SettingsView(model: model, advancedTrackingExpanded: true).padding(.top, 16),
          scheme: scheme, path: directory.appendingPathComponent("settings-tracking-expanded-\(name).png"), height: 1500)
        try await render(
          content: ShopView(model: model, optionsExpanded: true).padding(.top, 16),
          scheme: scheme, path: directory.appendingPathComponent("shop-expanded-\(name).png"), height: 2200)
        try await render(
          content: ShopView(model: model).padding(.top, 16),
          scheme: scheme, path: directory.appendingPathComponent("shop-items-\(name).png")
        )
        if let animal = model.currentAnimal {
          try await render(
            content: CompanionDetailView(model: model, animal: animal),
            scheme: scheme, path: directory.appendingPathComponent("collection-detail-\(name).png"))
          try await render(
            content: CompanionDetailView(model: model, animal: animal),
            scheme: scheme, path: directory.appendingPathComponent("compact-detail-\(name).png"),
            height: 374, width: 328)
          model.prepareVisualReview(finalCompanion: true)
          guard model.isGraduationReady, let final = model.currentAnimalInstance else {
            throw ReviewError.renderFailed
          }
          try await render(content: CompanionCollectionView(model: model), scheme: scheme,
                           path: directory.appendingPathComponent("collection-final-\(name).png"),
                           height: 700, width: 360)
          model.selectedSection = .home
          // The production Home panel fits its content; a full default-height
          // fixture would introduce an empty footer that players never see.
          try await render(model: model, scheme: scheme,
                           path: directory.appendingPathComponent("final-record-home-\(name).png"),
                           height: 374)
          try await render(model: model, scheme: scheme,
                           path: directory.appendingPathComponent("compact-final-record-home-\(name).png"),
                           height: 374, width: 328)
          try await render(
            content: CompanionRecordCard(
              model: model, animal: animal, instance: final, onRaise: {}, onNext: {}),
            scheme: scheme, path: directory.appendingPathComponent("final-record-action-\(name).png"),
            height: 670, width: 360)
          var longNamedFinal = final
          longNamedFinal.name = "A very long companion name"
          try await render(
            content: CompanionRecordCard(
              model: model, animal: animal, instance: longNamedFinal, onRaise: {}, onNext: {}),
            scheme: scheme, path: directory.appendingPathComponent("record-long-name-\(name).png"),
            height: 670, width: 328)
          longNamedFinal.name = String(repeating: "모찌", count: 12)
          try await render(
            content: CompanionRecordCard(
              model: model, animal: animal, instance: longNamedFinal, onRaise: {}, onNext: {}),
            scheme: scheme, path: directory.appendingPathComponent("record-long-korean-name-\(name).png"),
            height: 670, width: 328)
          model.prepareVisualReview()
          model.prepareVisualReview(collectionDuplicate: true)
          try await render(content: CompanionCollectionView(model: model), scheme: scheme,
            path: directory.appendingPathComponent("collection-duplicates-\(name).png"))
          try await render(content: CompanionDetailView(model: model, animal: animal), scheme: scheme,
            path: directory.appendingPathComponent("collection-duplicate-detail-\(name).png"))
          model.prepareVisualReview()
          try await render(
            content: ScrollView {
              FieldGuideSection(
                model: model, animal: animal, reachedStage: 2,
                initialExpandedID: "\(animal.id.rawValue).relative.proailurus"
              ).padding(16)
            }.frame(width: EvoStyle.width),
            scheme: scheme, path: directory.appendingPathComponent("field-guide-\(name).png"),
            height: 640)
        }
        model.prepareVisualReview(shiny: true)
        model.selectedSection = .home
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-home-\(name).png"))
        model.selectedSection = .collection
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-collection-\(name).png"))
        model.prepareArtworkReview(animalID: "capybara", stageIndex: 4)
        guard model.currentAnimalID == "capybara", model.acknowledgedStageIndex == 4,
              model.currentAnimalInstance?.isShiny == true else { throw ReviewError.companionSelectionFailed }
        model.selectedSection = .home
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-capybara-home-\(name).png"))
        model.prepareArtworkReview(animalID: "capybara", stageIndex: 7)
        guard model.currentAnimalID == "capybara", model.acknowledgedStageIndex == 7,
              model.currentAnimalInstance?.isShiny == true else { throw ReviewError.companionSelectionFailed }
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-capybara-final-\(name).png"))
        if let animal = model.currentAnimal {
          try await render(content: CompanionDetailView(model: model, animal: animal),
                           scheme: scheme,
                           path: directory.appendingPathComponent("shiny-capybara-detail-\(name).png"))
        }
        model.prepareArtworkReview(animalID: "mammoth", stageIndex: 4)
        guard model.currentAnimalID == "mammoth", model.acknowledgedStageIndex == 4,
              model.currentAnimalInstance?.isShiny == true else { throw ReviewError.companionSelectionFailed }
        model.selectedSection = .home
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-mammoth-home-\(name).png"))
        model.prepareArtworkReview(animalID: "mammoth", stageIndex: 7)
        guard model.currentAnimalID == "mammoth", model.acknowledgedStageIndex == 7,
              model.currentAnimalInstance?.isShiny == true else { throw ReviewError.companionSelectionFailed }
        try await render(model: model, scheme: scheme,
                         path: directory.appendingPathComponent("shiny-mammoth-final-\(name).png"))
        if let animal = model.currentAnimal {
          try await render(content: CompanionDetailView(model: model, animal: animal),
                           scheme: scheme,
                           path: directory.appendingPathComponent("shiny-mammoth-detail-\(name).png"))
        }
        // New alternate lines, with actual animated Home rendering enabled.
        // Fixture-only instances never touch the user's companion or save.
        for (animalID, stageIndex) in [("fox", 7), ("raptor", 7), ("pterosaur", 1)] {
          model.prepareArtworkReview(animalID: AnimalDefinitionID(rawValue: animalID), stageIndex: stageIndex)
          guard model.currentAnimalID == AnimalDefinitionID(rawValue: animalID),
                model.acknowledgedStageIndex == stageIndex,
                model.currentAnimalInstance?.isShiny == true else { throw ReviewError.companionSelectionFailed }
          model.animationQuality = .balanced
          model.isPanelVisible = true
          model.selectedSection = .home
          try await render(model: model, scheme: scheme,
                           path: directory.appendingPathComponent("shiny-\(animalID)-animated-home-\(name).png"))
          if animalID == "pterosaur", let next = model.currentAnimal?.stages.first(where: { $0.index == stageIndex + 1 }) {
            model.currentXP = next.xpThreshold
            guard model.companionVisualState == .evolutionReady else { throw ReviewError.companionSelectionFailed }
            try await render(model: model, scheme: scheme,
                             path: directory.appendingPathComponent("shiny-pterosaur-ready-home-\(name).png"))
          }
          model.isPanelVisible = false
        }
        model.prepareVisualReview()
        for page in 0...2 {
          try await render(
            content: OnboardingView(model: model, initialPage: page),
            scheme: scheme, path: directory.appendingPathComponent("onboarding-\(page)-\(name).png")
          )
        }
        try await render(
          content: GraduationView(model: model), scheme: scheme,
          path: directory.appendingPathComponent("compact-graduation-\(name).png"), height: 374, width: 328)
        try await render(
          content: PrivacyDetailsView(), scheme: scheme,
          path: directory.appendingPathComponent("compact-privacy-\(name).png"), height: 374, width: 328)
        model.prepareStartupFailureReview()
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("startup-failure-\(name).png"), height: 374, width: 328)
        // The incubator, with an egg warming, one ready, and one waiting.
        model.prepareVisualReview(incubating: true)
        model.selectedSection = .home
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("home-incubator-\(name).png"), height: 600, width: 328)
        model.selectedSection = .collection
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("collection-incubator-\(name).png"))
        for (state, days, held) in [("warming", Optional(1), false), ("held", nil, true)] {
          model.prepareIncubatorPromptReview(activeDays: days, held: held)
          model.incubatorMessage = nil
          guard !model.incubatorNeedsAttention else { throw ReviewError.incubatorAttentionFailed }
          try await render(model: model, scheme: scheme,
            path: directory.appendingPathComponent("home-egg-\(state)-\(name).png"), height: 600, width: 328)
          model.incubatorMessage = L10n.text("incubator.failed", fallback: "The egg could not be placed.")
          guard model.incubatorNeedsAttention else { throw ReviewError.incubatorAttentionFailed }
          try await render(model: model, scheme: scheme,
            path: directory.appendingPathComponent("home-egg-\(state)-failed-\(name).png"), height: 600, width: 328)
          model.incubatorMessage = nil
          guard !model.incubatorNeedsAttention else { throw ReviewError.incubatorAttentionFailed }
        }
        model.prepareIncubatorPromptReview(activeDays: IncubatingEgg.activeDaysToHatch, held: false)
        guard model.incubatorNeedsAttention else { throw ReviewError.incubatorAttentionFailed }
        model.prepareVisualReview(discovery: true)
        model.selectedSection = .home
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("hatch-discovery-\(name).png"), height: 600, width: 328)
        if let discovery = model.hatchDiscovery {
          try await render(content: HatchDiscoveryCard(model: model, instance: discovery, fieldNoteExpanded: true),
            scheme: scheme, path: directory.appendingPathComponent("hatch-field-note-\(name).png"),
            height: 440, width: 328)
        } else { throw ReviewError.renderFailed }
        model.prepareVisualReview(duplicateDiscovery: true)
        guard let duplicate = model.hatchDiscovery, !model.hatchIsNewDiscovery else {
          throw ReviewError.renderFailed
        }
        try await render(content: HatchDiscoveryCard(model: model, instance: duplicate), scheme: scheme,
          path: directory.appendingPathComponent("hatch-duplicate-\(name).png"), height: 420, width: 328)
        model.prepareVisualReview(discovery: true)
        if let animal = model.currentAnimal, let stage = animal.stages.first {
          let asset = ManifestAnimalAssetProvider().asset(for: animal, stageIndex: stage.index, isShiny: false, visualState: .idle)
          try await render(content: HatchCeremonyView(ceremony: HatchCeremony(
            to: asset, companionName: "Mochi", animalName: L10n.animal(animal), rarity: .common,
            isShiny: false, themeColorHex: animal.themeColorHex), elapsed: 0, forceReducedMotion: true), scheme: scheme,
            path: directory.appendingPathComponent("hatch-reduced-motion-\(name).png"), height: 374, width: 328)
          try await render(content: EvolutionCeremonyView(ceremony: EvolutionCeremony(
            from: asset,
            to: ManifestAnimalAssetProvider().asset(for: animal, stageIndex: 2, isShiny: false, visualState: .idle),
            stageName: L10n.stage(animal.stages[1]), companionName: "모찌 Mochi — My little companion",
            themeColorHex: animal.themeColorHex, isFinal: false), elapsed: 0, forceReducedMotion: true), scheme: scheme,
            path: directory.appendingPathComponent("evolution-reduced-motion-\(name).png"), height: 374, width: 328)
        }
        guard let mammoth = model.catalog?.animals.first(where: { $0.id == "mammoth" }),
              let final = mammoth.stages.last,
              mammoth.stages.count >= 2 else { throw ReviewError.renderFailed }
        let finalCeremony = EvolutionCeremony(
          from: ManifestAnimalAssetProvider().asset(
            for: mammoth, stageIndex: final.index - 1, isShiny: true, visualState: .evolutionReady),
          to: ManifestAnimalAssetProvider().asset(
            for: mammoth, stageIndex: final.index, isShiny: true, visualState: .idle),
          stageName: L10n.stage(final), companionName: "Peach",
          themeColorHex: mammoth.themeColorHex, isFinal: true)
        try await render(content: EvolutionCeremonyView(
          ceremony: finalCeremony, elapsed: 4.05), scheme: scheme,
          path: directory.appendingPathComponent("evolution-final-reveal-\(name).png"), height: 374, width: 328)
        try await render(content: EvolutionCeremonyView(
          ceremony: finalCeremony, elapsed: 0, forceReducedMotion: true), scheme: scheme,
          path: directory.appendingPathComponent("evolution-final-reduced-motion-\(name).png"), height: 374, width: 328)
        model.prepareVisualReview()
        // The card an individual can be saved as is reviewed like any surface,
        // and rendering it here is also the check that the exporter works.
        model.prepareVisualReview()
        if let animal = model.currentAnimal, let instance = model.currentAnimalInstance {
          try await render(
            content: CompanionCardView(
              animal: animal, instance: instance,
              stage: animal.stages.first { $0.index == instance.acknowledgedStageIndex }),
            scheme: scheme,
            path: directory.appendingPathComponent("companion-card-\(name).png"),
            height: CompanionCardView.size.height, width: CompanionCardView.size.width)
          // Actual exported PNG must not vary with private work statistics.
          var privateVariant = instance
          privateVariant.cumulativeTokens = 987_654_321
          privateVariant.providerTokens = [.claudeCode: 987_654_321]
          privateVariant.currentXP = 123_456
          privateVariant.firstGrowthAt = Date(timeIntervalSince1970: 1)
          privateVariant.firstGoldenAt = Date(timeIntervalSince1970: 2)
          let stage = animal.stages.first { $0.index == instance.acknowledgedStageIndex }
          let original = try CompanionCardExporter.png(for: CompanionCardView(animal: animal, instance: instance, stage: stage))
          let altered = try CompanionCardExporter.png(for: CompanionCardView(animal: animal, instance: privateVariant, stage: stage))
          guard original == altered else { throw ReviewError.renderFailed }
          // A lifetime with every stage must keep its ending on the keepsake.
          var graduate = privateVariant
          graduate.name = String(repeating: "모찌", count: 12)
          graduate.acknowledgedStageIndex = animal.stages.count
          graduate.evolutionDates = Dictionary(uniqueKeysWithValues: animal.stages.dropFirst().map {
            ($0.index, instance.createdAt.addingTimeInterval(Double($0.index) * 86_400))
          })
          graduate.finalEvolutionAt = graduate.evolutionDates[animal.stages.count]
          graduate.graduatedAt = instance.createdAt.addingTimeInterval(Double(animal.stages.count + 1) * 86_400)
          let memories = CompanionJournal.cardEntries(for: graduate, animal: animal)
          guard memories.count == 5, memories.first?.id == "born",
            memories.suffix(2).map(\.id) == ["final", "graduated"],
            !memories.contains(where: { $0.id == "stage-\(animal.stages.count)" }),
            CompanionJournal.cardEntries(for: instance, animal: animal)
              == CompanionJournal.cardEntries(for: privateVariant, animal: animal)
          else { throw ReviewError.renderFailed }
          try await render(content: CompanionCardView(
            animal: animal, instance: graduate, stage: animal.stages.last), scheme: scheme,
            path: directory.appendingPathComponent("companion-card-graduated-\(name).png"),
            height: CompanionCardView.size.height, width: CompanionCardView.size.width)
          var shinyGraduate = graduate
          shinyGraduate.isShiny = true
          try await render(content: CompanionCardView(
            animal: animal, instance: shinyGraduate, stage: animal.stages.last), scheme: scheme,
            path: directory.appendingPathComponent("companion-card-shiny-final-\(name).png"),
            height: CompanionCardView.size.height, width: CompanionCardView.size.width)
        }
        // A bought backdrop is reviewed like any other surface.
        model.prepareVisualReview(sceneThemeID: SceneTheme.night.itemID)
        model.selectedSection = .home
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("home-scene-theme-\(name).png"))
        model.prepareVisualReview(sceneThemeID: SceneTheme.night.itemID, finalCompanion: true)
        model.selectedSection = .home
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("final-home-scene-theme-\(name).png"))
        model.prepareVisualReview(shopFeedback: true)
        model.selectedSection = .shop
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("shop-feedback-\(name).png"), height: 520)
        try await render(
          content: ShopView(model: model).padding(.top, 16),
          scheme: scheme,
          path: directory.appendingPathComponent("shop-items-feedback-\(name).png"), height: 520)
        model.prepareVisualReview(previewLockedAnimals: true)
        if let ownedWithoutCompanion = model.catalog?.animals.first(where: { $0.id == "fox" }) {
          guard model.ownedAnimalIDs.contains(ownedWithoutCompanion.id),
                !model.animalInstances.contains(where: { $0.definitionID == ownedWithoutCompanion.id })
          else { throw ReviewError.collectionAccessibilityFailed }
          model.selectedSection = .collection
          try await render(model: model, scheme: scheme,
            path: directory.appendingPathComponent("collection-ownership-\(name).png"),
            height: 700, width: 360)
          try await render(content: CompanionDetailView(model: model, animal: ownedWithoutCompanion),
            scheme: scheme,
            path: directory.appendingPathComponent("collection-owned-unhatched-detail-\(name).png"),
            height: 500, width: 360)
        }
        if let locked = model.catalog?.animals.first(where: { $0.id == "mammoth" }) {
          guard !model.ownedAnimalIDs.contains(locked.id) else { throw ReviewError.renderFailed }
          try await render(content: ShopView(model: model).animalLineTile(locked), scheme: scheme,
            path: directory.appendingPathComponent("shop-locked-line-tile-\(name).png"),
            height: 108, width: 88)
          try await render(content: ShopView(model: model), scheme: scheme,
            path: directory.appendingPathComponent("shop-locked-animal-gallery-\(name).png"),
            height: 520, width: 360)
          try await render(
            content: ShopView(model: model).animalPreview(locked), scheme: scheme,
            path: directory.appendingPathComponent("shop-animal-preview-\(name).png"),
            height: 470, width: 360)
        }
        model.prepareVisualReview(settingsFeedback: true)
        model.openSettings(page: .data)
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("settings-feedback-\(name).png"), height: 520)
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("compact-settings-feedback-\(name).png"), height: 374, width: 328)
        model.prepareVisualReview(empty: true)
        model.selectedSection = .home
        try await render(
          model: model, scheme: scheme, path: directory.appendingPathComponent("empty-\(name).png"))
        try await render(
          content: CompanionHomeView(model: model, detailsExpanded: true), scheme: scheme,
          path: directory.appendingPathComponent("first-session-expanded-\(name).png"),
          height: 800, width: 328)
        model.companionName = "아주 긴 이름의 나의 소중한 동물 친구"
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("compact-first-long-name-\(name).png"), height: 600, width: 328)
        for scenario in ["connected", "permission", "partial", "paused", "manual"] {
          model.prepareTrackingReview(
            issues: scenario == "permission" ? [.permissionRequired] : scenario == "partial" ? [.readFailed] : [],
            connected: scenario == "connected" || scenario == "partial",
            paused: scenario == "paused", manual: scenario == "manual")
          try await render(model: model, scheme: scheme,
                           path: directory.appendingPathComponent("tracking-\(scenario)-\(name).png"))
          if scenario == "permission" {
            model.openSettings(page: .tracking)
            try await render(model: model, scheme: scheme,
                             path: directory.appendingPathComponent("tracking-recovery-\(name).png"), height: 374, width: 328)
          }
        }
        model.prepareVisualReview()
        model.currentXP = 300
        model.companionName = "아주 긴 이름의 나의 소중한 동물 친구"
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("ready-long-name-\(name).png"), height: 520)
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("compact-ready-long-name-\(name).png"), height: 600, width: 328)
        model.prepareIncubatorPromptReview(activeDays: nil, held: true)
        try await render(
          content: CompanionHomeView(model: model, detailsExpanded: true), scheme: scheme,
          path: directory.appendingPathComponent("home-details-expanded-\(name).png"), height: 800, width: 328)
      }
    }

    private static func verifyHatchAcknowledgement(model: AppModel) throws {
      model.prepareVisualReview(discovery: true)
      let individuals = model.animalInstances
      guard model.hatchDiscovery != nil, model.hatchIsNewDiscovery else {
        throw ReviewError.hatchAcknowledgementFailed
      }
      model.acknowledgeHatch(viewCollection: true)
      guard model.hatchDiscovery == nil, model.selectedSection == .collection,
        model.animalInstances == individuals, model.currentXP == 218 else {
        throw ReviewError.hatchAcknowledgementFailed
      }
      model.acknowledgeHatch()
      guard model.animalInstances == individuals else { throw ReviewError.hatchAcknowledgementFailed }
      model.prepareVisualReview()
    }

    private static func verifyFeedbackDismissal(model: AppModel) throws {
      model.prepareVisualReview(shopFeedback: true, settingsFeedback: true)
      let individuals = model.animalInstances
      let entitlements = model.activeProductIDs
      model.dismissPurchaseFeedback()
      guard model.purchaseMessage == nil, model.itemPurchaseMessage != nil, model.settingsMessage != nil else {
        throw ReviewError.feedbackDismissalFailed
      }
      model.dismissItemFeedback()
      model.dismissSettingsFeedback()
      guard model.itemPurchaseMessage == nil, model.settingsMessage == nil,
        model.animalInstances == individuals, model.activeProductIDs == entitlements,
        model.currentXP == 218, model.tokenCoins == 246, model.todayTokens == 15_400_000
      else { throw ReviewError.feedbackDismissalFailed }
      model.prepareVisualReview()
    }

    private static func verifyStartupRecovery(model: AppModel) async throws {
      model.prepareStartupFailureReview()
      model.retryLoading()
      guard model.loadState == .loading else { throw ReviewError.startupRecoveryFailed }
      for _ in 0..<100 {
        if model.loadState == .ready { break }
        try await Task.sleep(for: .milliseconds(10))
      }
      guard model.loadState == .ready else { throw ReviewError.startupRecoveryFailed }
      model.openSettings(page: .tracking)
      guard model.selectedSection == .settings, model.selectedSettingsPage == .tracking else {
        throw ReviewError.startupRecoveryFailed
      }
      model.retryLoading()
      guard model.loadState == .ready else { throw ReviewError.startupRecoveryFailed }
    }

    /// Exercise the actual AppModel-to-menu-bar wiring, not only the pure selector.
    /// Pinned previews must never replace the individual receiving food and XP.
    private static func verifyCompanionPresentation(model: AppModel) throws {
      let selections: [(AnimalDefinitionID?, AnimalDefinitionID, Int)] = [
        (nil, "cat", 2), ("dog", "dog", 4),
        ("fox", "fox", 1), ("not-owned", "cat", 2),
      ]
      for (pin, definitionID, stageIndex) in selections {
        model.prepareVisualReview(pinnedID: pin)
        guard let animal = model.catalog?.animals.first(where: { $0.id == definitionID }),
          let stage = animal.stages.first(where: { $0.index == stageIndex }),
          model.menuBarAsset?.assetID == stage.normalAssetID,
          model.desktopPetAnimal?.id == definitionID,
          model.displayedCompanionStageName == L10n.stage(stage),
          model.currentAnimalID == "cat", model.currentXP == 218,
          model.currentAnimalInstance?.name == "Mochi", model.pendingXP == 28,
          model.animalInstances.count == 2
        else { throw ReviewError.companionSelectionFailed }
        if definitionID == "dog", model.displayedCompanionName != "Biscuit" {
          throw ReviewError.companionSelectionFailed
        }
        if definitionID == "fox",
          model.desktopPetInstance != nil || model.displayedCompanionName != L10n.animal(animal)
        { throw ReviewError.companionSelectionFailed }
      }
      model.prepareVisualReview()
    }

    private static func render(
      model: AppModel, scheme: ColorScheme, path: URL, height: CGFloat = EvoStyle.height,
      width: CGFloat = EvoStyle.width
    ) async throws {
      try await render(
        content: RootPopoverView(model: model, panelHeight: height, panelWidth: width), scheme: scheme, path: path,
        height: height, width: width)
    }

    private static func render<Content: View>(
      content: Content, scheme: ColorScheme, path: URL, height: CGFloat = EvoStyle.height,
      width: CGFloat = EvoStyle.width
    ) async throws {
      let view =
        content
        .frame(width: width, height: height)
        .background(EvoStyle.background)
        .tint(EvoStyle.accent)
        .environment(\.colorScheme, scheme)
        .environment(\.companionPanelSize, CGSize(width: width, height: height))
        .transaction { $0.disablesAnimations = true }
      let host = NSHostingView(rootView: view)
      host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
      host.frame = NSRect(x: 0, y: 0, width: width, height: height)
      let window = NSWindow(
        contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
      window.contentView = host
      window.appearance = host.appearance
      host.layoutSubtreeIfNeeded()
      // Let SwiftUI lay out native scroll/form controls before reading its backing.
      try await Task.sleep(for: .milliseconds(150))
      host.layoutSubtreeIfNeeded()
      guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
        throw ReviewError.renderFailed
      }
      host.cacheDisplay(in: host.bounds, to: bitmap)
      guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw ReviewError.renderFailed
      }
      try data.write(to: path, options: .atomic)
      window.contentView = nil
    }
    private static func verifyCollectionAccessibility(model: AppModel) throws {
      model.prepareVisualReview()
      guard let animal = model.currentAnimal, let instance = model.currentAnimalInstance else {
        throw ReviewError.collectionAccessibilityFailed
      }
      let stage = L10n.format("ui.stageOf", fallback: "Stage %lld / %lld",
                             Int64(instance.acknowledgedStageIndex), Int64(animal.stages.count))
      let stageZero = L10n.format("ui.stageOf", fallback: "Stage %lld / %lld", 0, Int64(animal.stages.count))
      var waitingInstance = instance
      waitingInstance.isCurrent = false
      waitingInstance.currentXP = 0
      waitingInstance.acknowledgedStageIndex = 1
      let hatched = CollectionAccessibility.summary(animal: animal, instance: instance, owned: true, current: true, artwork: true)
      let waiting = CollectionAccessibility.summary(animal: animal, instance: waitingInstance, owned: true, current: false, artwork: true)
      let ownedWithoutCompanion = CollectionAccessibility.summary(animal: animal, instance: nil, owned: true, current: false, artwork: true)
      let unavailable = CollectionAccessibility.summary(animal: animal, instance: nil, owned: true, current: false, artwork: false)
      let locked = CollectionAccessibility.summary(animal: animal, instance: instance, owned: false, current: false, artwork: true)
      guard hatched.contains(stage), hatched.contains(instance.name),
        waiting.contains(L10n.text("incubator.waiting", fallback: "Waiting to be raised")),
        ownedWithoutCompanion.contains(L10n.text("collection.lineUnlocked", fallback: "Animal line unlocked")),
        ownedWithoutCompanion.contains(L10n.text("collection.noCompanionYet", fallback: "No companion raised yet")),
        !ownedWithoutCompanion.contains(L10n.text("ui.undiscovered", fallback: "Not discovered yet")),
        !ownedWithoutCompanion.contains(stageZero),
        unavailable.contains(L10n.text("shop.comingSoon", fallback: "Coming soon")),
        !unavailable.contains(L10n.text("collection.noCompanionYet", fallback: "No companion raised yet")),
        !locked.contains(instance.name), !locked.contains(stage), !locked.contains(stageZero)
      else { throw ReviewError.collectionAccessibilityFailed }
    }

    private enum ReviewError: Error { case renderFailed, companionSelectionFailed, startupRecoveryFailed, feedbackDismissalFailed, collectionAccessibilityFailed, hatchAcknowledgementFailed, incubatorAttentionFailed }
  }
#endif
