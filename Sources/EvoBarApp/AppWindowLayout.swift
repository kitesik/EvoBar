import AppKit
import EvoBarCore

/// Shared by the detached dashboard and the native Settings scene. It accepts
/// screen rectangles so tests can exercise real NSWindows without changing the
/// user's displays or moving another app's windows.
@MainActor
enum AppWindowLayout {
    static func fit(
        _ window: NSWindow, layout: CompanionPanelLayout,
        screens: [CGRect] = NSScreen.screens.map(\.visibleFrame),
        fallback: CGRect = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    ) {
        let screen = WindowPlacement.screen(for: window.frame, among: screens, fallback: fallback)
        let titlebarHeight = max(0, window.frame.height - window.contentRect(forFrameRect: window.frame).height)
        let size = WindowPlacement.contentSize(
            preferred: CGSize(width: EvoStyle.width, height: layout.preferredHeight),
            in: screen, reservedHeight: titlebarHeight)
        let top = window.frame.maxY
        if layout.size != size { layout.size = size }
        let frameSize = window.frameRect(forContentRect: CGRect(origin: .zero, size: size)).size
        let proposed = CGRect(x: window.frame.minX, y: top - frameSize.height, width: frameSize.width, height: frameSize.height)
        let fitted = WindowPlacement.constrained(proposed, to: screen)
        if window.frame != fitted { window.setFrame(fitted, display: true, animate: false) }
    }
}
