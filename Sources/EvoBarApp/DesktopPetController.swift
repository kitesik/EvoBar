import AppKit
import Combine
import EvoBarCore
import SwiftUI

@MainActor
final class DesktopPetController: NSObject, NSWindowDelegate {
    private let model: AppModel
    private let panel: NSPanel
    private var cancellables: Set<AnyCancellable> = []
    private var isUpdatingFrame = false
    private var savePositionWorkItem: DispatchWorkItem?

    init(model: AppModel) {
        self.model = model
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.delegate = self
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentViewController = NSHostingController(rootView: DesktopPetView(model: model))

        model.$desktopPetEnabled
            .combineLatest(model.$onboardingCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled, onboarded in
                self?.updateVisibility(enabled: enabled && onboarded)
            }
            .store(in: &cancellables)

        model.$desktopPetSize
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] size in self?.updateSize(size) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Cancel a drag save queued against a display that disappeared.
                self.savePositionWorkItem?.cancel()
                self.updateSize(self.model.desktopPetSize)
            }
            .store(in: &cancellables)
    }

    func windowDidMove(_ notification: Notification) {
        guard !isUpdatingFrame else { return }
        savePositionWorkItem?.cancel()
        let origin = panel.frame.origin
        let work = DispatchWorkItem { [weak self] in
            self?.model.setDesktopPetPosition(origin)
        }
        savePositionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func updateVisibility(enabled: Bool) {
        if enabled {
            updateSize(model.desktopPetSize)
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    private func updateSize(_ petSize: Double) {
        let windowSize = NSSize(width: petSize + 120, height: petSize + 60)
        let origin = resolvedOrigin(for: windowSize)
        isUpdatingFrame = true
        panel.setFrame(NSRect(origin: origin, size: windowSize), display: true, animate: false)
        isUpdatingFrame = false
    }

    private func resolvedOrigin(for size: NSSize) -> NSPoint {
        let fallback = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = panel.isVisible ? panel.frame.origin : model.desktopPetPosition
        let proposed = CGRect(
            origin: origin ?? CGPoint(x: fallback.maxX - size.width - 24, y: fallback.minY + 24), size: size)
        let screen = WindowPlacement.screen(
            for: proposed, among: NSScreen.screens.map(\.visibleFrame), fallback: fallback)
        return WindowPlacement.constrained(proposed, to: screen, margin: 8).origin
    }
}

private struct DesktopPetView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())

            if let quota = model.quotaWarningWindow {
                Text("\(providerName(quota.providerID)) \(quota.name) \(Int((quota.utilization * 100).rounded()))%")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(quota.utilization >= 0.95 ? Color.red : .orange, lineWidth: 1))
            }

            VStack(spacing: 2) {
                Spacer()
                if let asset = model.desktopPetAsset {
                    TimelineView(.animation(
                        minimumInterval: model.animationQuality == .smooth ? 1 / 30 : 1 / 12,
                        paused: !motionEnabled || !model.desktopPetEnabled
                    )) { context in
                        AnimalSpriteView(reference: asset, size: model.desktopPetSize)
                            .offset(y: bobOffset(at: context.date))
                            .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
                    }
                    .accessibilityLabel("\(model.displayedCompanionName), \(model.displayedCompanionStageName)")
                }

                if isHovering {
                    Text(L10n.format("pet.hover", fallback: "%@, %@ today", model.displayedCompanionName, AppModel.compactTokens(model.todayTokens)))
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: Capsule())
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale))
                }
            }
        }
        .frame(width: model.desktopPetSize + 120, height: model.desktopPetSize + 60)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { isHovering = hovering }
        }
        .contextMenu {
            Button(L10n.text("Use growing companion")) { model.setPinnedAnimalDefinitionID(nil) }
            Button(L10n.text("Open usage")) {
                model.selectedSection = .usage
                NotificationCenter.default.post(name: .evoBarOpenWindow, object: nil)
            }
            Divider()
            Button(L10n.text("Hide desktop pet")) { model.setDesktopPetEnabled(false) }
        }
    }

    private var motionEnabled: Bool {
        !reduceMotion && model.animationQuality != .powerSaver
    }

    private func bobOffset(at date: Date) -> CGFloat {
        guard motionEnabled else { return 0 }
        let period = model.animationQuality == .smooth ? 1.4 : 3.0
        return -1 + 3 * sin(date.timeIntervalSinceReferenceDate * 2 * .pi / period)
    }

    private func providerName(_ providerID: ProviderID) -> String {
        providerID == .claudeCode ? "Claude" : "Codex"
    }
}
