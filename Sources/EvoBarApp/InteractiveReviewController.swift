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
        let view = AdaptiveCompanionPanel(model: model, layout: layout)
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
        window.setContentSize(layout.size)
        window.center()
        AppWindowLayout.fit(window, layout: layout)
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
