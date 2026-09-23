#if DEBUG
import AppKit
import SwiftUI

/// Verifies the actual Settings hosting root, its AppKit attachment, and its
/// notification bridge. The windows stay hidden and use only isolated data.
@MainActor
enum WindowLayoutReview {
    private final class ScreenFrames {
        var values = [CGRect(x: 0, y: 24, width: 640, height: 450)]
    }

    static func verify(model: AppModel) async throws {
        guard model.isIsolatedRun else { return }
        let frames = ScreenFrames()
        let notifications = NotificationCenter()
        let layout = CompanionPanelLayout()
        let originalPage = model.selectedSettingsPage
        let originalSection = model.selectedSection
        model.openSettings(page: .tracking)
        defer {
            model.selectedSettingsPage = originalPage
            model.selectedSection = originalSection
        }

        let controller = NSHostingController(rootView: StandaloneSettingsView(
            model: model, layout: layout, screenFrames: { frames.values }, notifications: notifications))
        let window = NSWindow(
            contentRect: CGRect(x: 2300, y: 400, width: 420, height: 700),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentViewController = controller
        defer {
            window.contentViewController = nil
            window.close()
        }
        controller.view.layoutSubtreeIfNeeded()
        try await waitUntil {
            layout.size.height < 450 && frames.values[0].insetBy(dx: 16, dy: 16).contains(window.frame)
        }

        // The same root grows back to its preferred height on a larger display.
        frames.values = [CGRect(x: -1280, y: -160, width: 1280, height: 960)]
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        try await waitUntil {
            layout.size.height == EvoStyle.height && frames.values[0].insetBy(dx: 16, dy: 16).contains(window.frame)
        }
        guard model.selectedSettingsPage == .tracking, !window.isVisible else { throw Failure.stateOrVisibility }

        // Transient empty screen inventories must not invent a new placement.
        let fitted = window.frame
        frames.values = []
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        try await Task.sleep(for: .milliseconds(50))
        guard window.frame == fitted else { throw Failure.emptyScreenInventory }

        // Detaching the root must unregister its notification observations.
        window.contentViewController = nil
        frames.values = [CGRect(x: 0, y: 0, width: 640, height: 450)]
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        try await Task.sleep(for: .milliseconds(50))
        guard window.frame == fitted else { throw Failure.detachedRootMoved }

        // Content-driven Home sizing must preserve the top edge, expand again,
        // and still clamp long details to a small display instead of clipping.
        let largeScreen = CGRect(x: -1280, y: -160, width: 1280, height: 960)
        layout.preferredHeight = 310
        AppWindowLayout.fit(window, layout: layout, screens: [largeScreen])
        guard layout.size.height == 310, abs(window.frame.maxY - fitted.maxY) < 1 else {
            print("Home shrink failed: size=\(layout.size), frame=\(window.frame), previous=\(fitted)")
            throw Failure.layoutDidNotFit
        }
        layout.preferredHeight = 570
        AppWindowLayout.fit(window, layout: layout, screens: [largeScreen])
        guard layout.size.height == 570 else {
            print("Home expand failed: \(layout.size)")
            throw Failure.layoutDidNotFit
        }
        layout.preferredHeight = 1200
        AppWindowLayout.fit(window, layout: layout, screens: frames.values, fallback: frames.values[0])
        guard frames.values[0].insetBy(dx: 16, dy: 16).contains(window.frame),
              layout.size.height < 450 else {
            print("Home clamp failed: size=\(layout.size), frame=\(window.frame)")
            throw Failure.layoutDidNotFit
        }

        // Exercise the actual Home measurements, not just a preferred height
        // supplied by the test. A short companion card must shrink its panel.
        model.prepareVisualReview()
        model.selectedSection = .home
        let homeLayout = CompanionPanelLayout()
        let homeController = NSHostingController(rootView: AdaptiveCompanionPanel(
            model: model, layout: homeLayout))
        let homeWindow = NSWindow(
            contentRect: CGRect(x: 200, y: 200, width: EvoStyle.width, height: EvoStyle.height),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        homeWindow.isReleasedWhenClosed = false
        homeWindow.contentViewController = homeController
        defer {
            homeWindow.contentViewController = nil
            homeWindow.close()
        }
        homeController.view.layoutSubtreeIfNeeded()
        try await waitUntil {
            homeLayout.preferredHeight < EvoStyle.height - 80
        }
        let compactHeight = homeLayout.preferredHeight
        AppWindowLayout.fit(homeWindow, layout: homeLayout, screens: [largeScreen])
        guard abs(homeLayout.size.height - compactHeight) < 2 else {
            throw Failure.layoutDidNotFit
        }
    }

    private static func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw Failure.layoutDidNotFit
    }

    private enum Failure: Error {
        case layoutDidNotFit, stateOrVisibility, emptyScreenInventory, detachedRootMoved
    }
}
#endif
