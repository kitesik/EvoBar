#if DEBUG
  import AppKit
  import EvoBarCore
  import SwiftUI

  /// Renders the actual SwiftUI screens using isolated fixture data, never the
  /// user's desktop or logs. Absent from release binaries.
  @MainActor
  enum VisualReviewExporter {
    static func export(model: AppModel, directory: URL) async throws {
      guard model.isIsolatedRun else { return }
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try await verifyStartupRecovery(model: model)
      try verifyCompanionPresentation(model: model)
      try verifyFeedbackDismissal(model: model)
      try verifyCollectionAccessibility(model: model)
      // The panel is dark glass in every system appearance, so one pass suffices.
      for (name, scheme) in [("dark", ColorScheme.dark)] {
        model.prepareVisualReview()
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
        try await render(
          content: ShopView(model: model, showingItems: true).padding(.top, 16),
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
        model.prepareVisualReview(shopFeedback: true)
        model.selectedSection = .shop
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("shop-feedback-\(name).png"), height: 520)
        try await render(
          content: ShopView(model: model, showingItems: true).padding(.top, 16),
          scheme: scheme,
          path: directory.appendingPathComponent("shop-items-feedback-\(name).png"), height: 520)
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
        model.prepareVisualReview()
        model.currentXP = 300
        model.companionName = "아주 긴 이름의 나의 소중한 동물 친구"
        try await render(
          model: model, scheme: scheme,
          path: directory.appendingPathComponent("ready-long-name-\(name).png"), height: 520)
      }
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
          model.currentAnimalInstance?.name == "Mochi", model.pendingFoodXP == 28,
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
      let hatched = CollectionAccessibility.summary(animal: animal, instance: instance, owned: true, current: true, artwork: true)
      let unhatched = CollectionAccessibility.summary(animal: animal, instance: nil, owned: true, current: false, artwork: true)
      let unavailable = CollectionAccessibility.summary(animal: animal, instance: nil, owned: true, current: false, artwork: false)
      let locked = CollectionAccessibility.summary(animal: animal, instance: instance, owned: false, current: false, artwork: true)
      guard hatched.contains(stage), hatched.contains(instance.name),
        unhatched.contains(L10n.text("ui.unhatched", fallback: "Waiting to hatch")), !unhatched.contains(stageZero),
        unavailable.contains(L10n.text("shop.comingSoon", fallback: "Coming soon")),
        !unavailable.contains(L10n.text("ui.unhatched", fallback: "Waiting to hatch")),
        !locked.contains(instance.name), !locked.contains(stage), !locked.contains(stageZero)
      else { throw ReviewError.collectionAccessibilityFailed }
    }

    private enum ReviewError: Error { case renderFailed, companionSelectionFailed, startupRecoveryFailed, feedbackDismissalFailed, collectionAccessibilityFailed }
  }
#endif
