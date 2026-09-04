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
        let screens = NSScreen.screens
        if let saved = model.desktopPetPosition,
           screens.contains(where: { $0.visibleFrame.intersects(NSRect(origin: saved, size: size)) }) {
            return saved
        }
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: frame.maxX - size.width - 24, y: frame.minY + 24)
    }
}

private struct DesktopPetView: View {
    @ObservedObject var model: AppModel
    @State private var isHovering = false
    @State private var isBobbing = false

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
                Text(model.desktopPetAsset?.fallbackEmoji ?? "🐾")
                    .font(.system(size: model.desktopPetSize * 0.72))
                    .offset(y: isBobbing ? -4 : 2)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
                    .accessibilityLabel("\(model.desktopPetInstance?.name ?? model.companionName), \(model.desktopPetAsset?.visualState.rawValue ?? "idle")")

                if isHovering {
                    Text("\(model.desktopPetInstance?.name ?? model.companionName) · \(model.todayTokens.formatted(.number.notation(.compactName))) today")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: Capsule())
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .frame(width: model.desktopPetSize + 120, height: model.desktopPetSize + 60)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
        }
        .onAppear { updateAnimation() }
        .onChange(of: model.animationQuality) { _, _ in updateAnimation() }
        .contextMenu {
            Button(L10n.text("Use growing companion")) { model.setPinnedAnimalDefinitionID(nil) }
            Button(L10n.text("Open usage")) { model.selectedSection = .usage }
            Divider()
            Button(L10n.text("Hide desktop pet")) { model.setDesktopPetEnabled(false) }
        }
    }

    private func updateAnimation() {
        isBobbing = false
        let duration: TimeInterval?
        switch model.animationQuality {
        case .powerSaver: duration = nil
        case .balanced: duration = 1.5
        case .smooth: duration = 0.7
        }
        guard let duration else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                isBobbing = true
            }
        }
    }

    private func providerName(_ providerID: ProviderID) -> String {
        providerID == .claudeCode ? "Claude" : "Codex"
    }
}
