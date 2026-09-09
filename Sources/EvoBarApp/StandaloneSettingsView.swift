import AppKit
import Combine
import SwiftUI

struct StandaloneSettingsView: View {
    @ObservedObject var model: AppModel
    @StateObject private var layout: CompanionPanelLayout
    private let screenFrames: @MainActor () -> [CGRect]
    private let notifications: NotificationCenter

    init(
        model: AppModel, layout: CompanionPanelLayout = CompanionPanelLayout(),
        screenFrames: @escaping @MainActor () -> [CGRect] = { NSScreen.screens.map(\.visibleFrame) },
        notifications: NotificationCenter = .default
    ) {
        self.model = model
        _layout = StateObject(wrappedValue: layout)
        self.screenFrames = screenFrames
        self.notifications = notifications
    }

    var body: some View {
        SettingsView(model: model)
            .padding(.top, 16)
            .frame(width: layout.size.width, height: layout.size.height)
            .background(EvoStyle.background)
            .tint(EvoStyle.accent)
            .environment(\.companionPanelSize, layout.size)
            .background {
                SettingsWindowAnchor(layout: layout, screenFrames: screenFrames, notifications: notifications)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
    }
}

private struct SettingsWindowAnchor: NSViewRepresentable {
    let layout: CompanionPanelLayout
    let screenFrames: @MainActor () -> [CGRect]
    let notifications: NotificationCenter

    func makeNSView(context: Context) -> SettingsWindowAnchorView {
        SettingsWindowAnchorView(layout: layout, screenFrames: screenFrames, notifications: notifications)
    }

    func updateNSView(_ nsView: SettingsWindowAnchorView, context: Context) {}

    static func dismantleNSView(_ nsView: SettingsWindowAnchorView, coordinator: ()) {
        nsView.stopObserving()
    }
}

private final class SettingsWindowAnchorView: NSView {
    private let layout: CompanionPanelLayout
    private let screenFrames: @MainActor () -> [CGRect]
    private let notifications: NotificationCenter
    private var observers: Set<AnyCancellable> = []
    private var pendingFit: DispatchWorkItem?

    init(layout: CompanionPanelLayout, screenFrames: @escaping @MainActor () -> [CGRect], notifications: NotificationCenter) {
        self.layout = layout
        self.screenFrames = screenFrames
        self.notifications = notifications
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopObserving()
        guard let window else { return }
        notifications.publisher(for: NSWindow.didChangeScreenNotification, object: window)
            .merge(with: notifications.publisher(for: NSApplication.didChangeScreenParametersNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.scheduleFit() }
            .store(in: &observers)
        scheduleFit()
    }

    func stopObserving() {
        pendingFit?.cancel()
        pendingFit = nil
        observers.removeAll()
    }

    private func scheduleFit() {
        pendingFit?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let window = self.window else { return }
            let frames = self.screenFrames()
            // During display reconfiguration there can briefly be no screens.
            // Wait for the next notification instead of inventing a placement.
            guard let fallback = frames.first else { return }
            AppWindowLayout.fit(window, layout: self.layout, screens: frames, fallback: fallback)
        }
        pendingFit = work
        // A representable may attach while SwiftUI is laying out the root.
        // Apply the new dimensions on the next main-loop pass, not during it.
        DispatchQueue.main.async(execute: work)
    }
}
