#if DEBUG
  import AppKit
  import SwiftUI

  /// Renders the actual SwiftUI screens using isolated fixture data, never the
  /// user's desktop or logs. Absent from release binaries.
  @MainActor
  enum VisualReviewExporter {
    static func export(model: AppModel, directory: URL) async throws {
      guard model.isIsolatedRun else { return }
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      for (name, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
        model.prepareVisualReview()
        for section in AppSection.allCases {
          model.selectedSection = section
          try await render(
            model: model, scheme: scheme,
            path: directory.appendingPathComponent("\(section.rawValue.lowercased())-\(name).png"))
        }
        for page in SettingsPage.allCases where page != .general {
          try await render(
            content: SettingsView(model: model, initialPage: page).padding(.top, 16),
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
        }
        for page in 0...2 {
          try await render(
            content: OnboardingView(model: model, initialPage: page),
            scheme: scheme, path: directory.appendingPathComponent("onboarding-\(page)-\(name).png")
          )
        }
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

    private static func render(
      model: AppModel, scheme: ColorScheme, path: URL, height: CGFloat = EvoStyle.height
    ) async throws {
      try await render(
        content: RootPopoverView(model: model, panelHeight: height), scheme: scheme, path: path,
        height: height)
    }

    private static func render<Content: View>(
      content: Content, scheme: ColorScheme, path: URL, height: CGFloat = EvoStyle.height
    ) async throws {
      let view =
        content
        .frame(width: EvoStyle.width, height: height)
        .background(EvoStyle.background)
        .tint(EvoStyle.accent)
        .environment(\.colorScheme, scheme)
        .transaction { $0.disablesAnimations = true }
      let host = NSHostingView(rootView: view)
      host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
      host.frame = NSRect(x: 0, y: 0, width: EvoStyle.width, height: height)
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
    private enum ReviewError: Error { case renderFailed }
  }
#endif
