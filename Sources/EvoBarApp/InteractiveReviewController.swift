#if DEBUG
import AppKit
import SwiftUI

/// An opt-in, separately bundled app for out-of-process UI inspection. This
/// window hosts the real dashboard with fixtures and an opaque backdrop so a
/// screenshot cannot reveal another app through the production glass effect.
@MainActor
final class InteractiveReviewController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let layout = CompanionPanelLayout()

    init(model: AppModel) {
        precondition(model.isIsolatedRun)
        let screen = ProcessInfo.processInfo.environment["EVOBAR_INTERACTIVE_REVIEW_SCREEN"]
        let compact = screen == "compact-hatch-error" || screen == "compact-placement-error"
        let reviewSize = compact ? CGSize(width: 328, height: 374) : layout.size
        let content: AnyView
        switch screen {
        case "motion":
            // Presentation-only animal; no pending growth may reach the store.
            model.prepareArtworkReview(animalID: "cat", stageIndex: 2)
            model.animationQuality = .balanced
            model.isPanelVisible = true
            model.selectedSection = .home
            content = AnyView(AdaptiveCompanionPanel(model: model, layout: layout))
        case "compact-placement-error":
            model.prepareIncubatorPromptReview(activeDays: nil, held: true)
            model.incubatorMessage = L10n.text("incubator.failed", fallback: "The egg could not be placed.")
            content = AnyView(RootPopoverView(model: model, panelHeight: 374, panelWidth: 328))
        case "compact-hatch-error":
            model.selectedSection = .home
            model.incubatorMessage = L10n.text("incubator.openFailed", fallback: "Could not open the egg. Your egg is safe; try again.")
            content = AnyView(RootPopoverView(model: model, panelHeight: 374, panelWidth: 328))
        case "onboarding": content = AnyView(OnboardingView(model: model, initialPage: 2))
        case "graduation": content = AnyView(GraduationView(model: model))
        default: content = AnyView(AdaptiveCompanionPanel(model: model, layout: layout))
        }
        let view = content
            .environment(\.companionPanelSize, reviewSize)
            .background(Color(white: 0.10))
        window = NSWindow(contentViewController: NSHostingController(rootView: view))
        super.init()
        window.title = "EvoBar UI Review, fixture data"
        window.styleMask = [.titled, .closable]
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(white: 0.10, alpha: 1)
        window.isOpaque = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setContentSize(reviewSize)
        window.center()
        if !compact { AppWindowLayout.fit(window, layout: layout) }
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}
#endif
