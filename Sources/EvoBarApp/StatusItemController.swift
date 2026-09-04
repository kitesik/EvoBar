import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let model: AppModel
    private var cancellables: Set<AnyCancellable> = []
    private var didAutoPresentOnboarding = false

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 540)
        popover.contentViewController = NSHostingController(rootView: RootPopoverView(model: model))

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "EvoBar"
        }

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.updateButton() }
            }
            .store(in: &cancellables)
        model.$loadState
            .combineLatest(model.$onboardingCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] loadState, onboardingCompleted in
                guard loadState == .ready, !onboardingCompleted else { return }
                self?.presentOnboardingIfNeeded()
            }
            .store(in: &cancellables)
        updateButton()
    }

    private func presentOnboardingIfNeeded() {
        guard !didAutoPresentOnboarding, let button = statusItem.button else { return }
        didAutoPresentOnboarding = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateButton() {
        statusItem.button?.title = model.menuBarTitle
        statusItem.button?.setAccessibilityLabel(
            "\(model.companionName), \(model.currentStage.map(L10n.stage) ?? L10n.text("Growing companion"))"
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: L10n.text("Open EvoBar"), action: #selector(openPopoverFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.text("Quit EvoBar"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openPopoverFromMenu() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
