import AppKit
import Combine
import EvoBarCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem
    private let popover = NSPopover()
    private var detachedWindow: NSWindow?
    private let popoverLayout = CompanionPanelLayout()
    private let windowLayout = CompanionPanelLayout()
    private let model: AppModel
    private var cancellables: Set<AnyCancellable> = []
    private var didAutoPresentOnboarding = false
    private var animationTimer: Timer?
    private var animationFrame = 0
    private var animationSignature = ""

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: AdaptiveCompanionPanel(model: model, layout: popoverLayout))
        updatePopoverLayout()

        configureButton()

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshPresentation() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .evoBarOpenWindow)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.popover.performClose(nil)
                self?.presentForActivation()
            }
            .store(in: &cancellables)

        // Unplugging the display that held the item can leave it parked off every
        // screen. Rebuild it when the screen set changes so it lands somewhere visible.
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.screensDidChange() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didChangeScreenNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow,
                      window === self.detachedWindow else { return }
                self.fitDetachedWindow(window)
            }
            .store(in: &cancellables)

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.refreshPresentation() }
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
        refreshPresentation()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "EvoBar"
        button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    }

    private func rebuildStatusItemIfStranded() {
        guard let window = statusItem.button?.window else { return }
        let onScreen = NSScreen.screens.contains { $0.frame.intersects(window.frame) }
        guard !onScreen else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        animationSignature = ""
        refreshPresentation()
    }

    private func presentOnboardingIfNeeded() {
        guard !model.isIsolatedRun, !didAutoPresentOnboarding, let button = statusItem.button else { return }
        didAutoPresentOnboarding = true
        updatePopoverLayout()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateButton() {
        guard let button = statusItem.button else { return }
        if let reference = model.menuBarAsset,
           let image = statusFrame(for: reference) {
            button.image = renderedStatusImage(image)
            button.imagePosition = .imageLeading
            button.title = model.menuBarMetricsTitle
        } else {
            button.image = nil
            button.title = model.menuBarTitle
        }
        button.setAccessibilityLabel(
            "\(model.displayedCompanionName), \(model.displayedCompanionStageName)"
        )
        button.setAccessibilityValue(model.menuBarMetricsTitle)
        button.toolTip = "\(model.displayedCompanionName), \(model.displayedCompanionStageName)"
    }

    private func statusFrame(for reference: AnimalAssetReference) -> NSImage? {
        let profile = currentMotionProfile
        guard let gait = profile.gait else { return AnimalSpriteImage.load(reference) }
        let frames = AnimalSpriteImage.gaitCycle(reference, gait: gait, frameCount: profile.frameCount).frames
        guard !frames.isEmpty else { return nil }
        return frames[animationFrame % frames.count]
    }

    private var currentMotionProfile: CompanionMotionProfile {
        CompanionMotionProfile.resolve(
            qualityID: model.animationQuality.rawValue,
            visualState: model.companionVisualState,
            locomotion: model.desktopPetAnimal?.locomotion ?? .walk,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
    }

    private func refreshPresentation() {
        configureAnimationTimer()
        updateButton()
    }

    private func configureAnimationTimer() {
        let profile = currentMotionProfile
        let signature = [
            model.animationQuality.rawValue,
            model.companionVisualState.rawValue,
            model.menuBarAsset?.assetID ?? "none",
            profile.gait?.rawValue ?? "still",
            String(profile.frameCount),
        ].joined(separator: "|")
        guard signature != animationSignature else { return }

        animationSignature = signature
        animationTimer?.invalidate()
        animationTimer = nil
        animationFrame = 0
        guard let interval = profile.frameInterval else { return }

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.animationFrame = (self.animationFrame + 1) % profile.frameCount
                self.updateButton()
            }
        }
        timer.tolerance = interval * 0.15
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func renderedStatusImage(_ source: NSImage) -> NSImage {
        let sourceAspect = source.size.width / max(1, source.size.height)
        let targetHeight: CGFloat = 20
        let targetWidth = min(24, max(14, targetHeight * sourceAspect))
        let canvas = NSImage(size: NSSize(width: targetWidth, height: 22), flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .none
            let x = (rect.width - targetWidth) / 2
            let y = (rect.height - targetHeight) / 2
            source.draw(
                in: NSRect(x: x, y: y, width: targetWidth, height: targetHeight),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
            return true
        }
        canvas.isTemplate = false
        return canvas
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            updatePopoverLayout()
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
        updatePopoverLayout()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    // Activation without a click (Cmd+Tab, Finder relaunch) cannot trust the status
    // button's position: a crowded menu bar hides the item behind the notch while
    // still reporting a frame under the app menu. Show a plain window instead.
    func presentForActivation() {
        guard !popover.isShown else { return }
        let window = detachedWindow ?? makeDetachedWindow()
        detachedWindow = window
        if !window.isVisible, let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = window.frame.size
            window.setFrameOrigin(NSPoint(x: frame.maxX - size.width - 16, y: frame.maxY - size.height - 16))
        }
        fitDetachedWindow(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeDetachedWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: AdaptiveCompanionPanel(model: model, layout: windowLayout)
        ))
        window.title = "EvoBar"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.setContentSize(windowLayout.size)
        return window
    }

    private var fallbackScreenFrame: CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func updatePopoverLayout() {
        let screen = statusItem.button?.window?.screen?.visibleFrame ?? fallbackScreenFrame
        let size = WindowPlacement.contentSize(
            preferred: CGSize(width: EvoStyle.width, height: EvoStyle.height),
            in: screen, reservedHeight: 44)
        if popoverLayout.size != size { popoverLayout.size = size }
        if popover.contentSize != size { popover.contentSize = size }
    }

    private func fitDetachedWindow(_ window: NSWindow) {
        let screen = WindowPlacement.screen(
            for: window.frame, among: NSScreen.screens.map(\.visibleFrame), fallback: fallbackScreenFrame)
        let titlebarHeight = max(0, window.frame.height - window.contentRect(forFrameRect: window.frame).height)
        let size = WindowPlacement.contentSize(
            preferred: CGSize(width: EvoStyle.width, height: EvoStyle.height),
            in: screen, reservedHeight: titlebarHeight)
        let top = window.frame.maxY
        if windowLayout.size != size { windowLayout.size = size }
        let frameSize = window.frameRect(forContentRect: CGRect(origin: .zero, size: size)).size
        let proposed = CGRect(x: window.frame.minX, y: top - frameSize.height, width: frameSize.width, height: frameSize.height)
        let fitted = WindowPlacement.constrained(proposed, to: screen)
        if window.frame != fitted { window.setFrame(fitted, display: true, animate: false) }
    }

    private func screensDidChange() {
        // Close a transient panel before its anchor is potentially rebuilt. The
        // same hosting root is retained for the next opening.
        popover.performClose(nil)
        rebuildStatusItemIfStranded()
        updatePopoverLayout()
        if let window = detachedWindow { fitDetachedWindow(window) }
    }
}
