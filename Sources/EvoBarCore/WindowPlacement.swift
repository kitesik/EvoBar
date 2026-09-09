import Foundation

/// Screen-independent layout arithmetic. Coordinates are macOS global points,
/// so monitors to the left or below the primary display may be negative.
public enum WindowPlacement {
    public static func contentSize(
        preferred: CGSize, in visibleFrame: CGRect,
        margin: CGFloat = 16, reservedHeight: CGFloat = 0
    ) -> CGSize {
        CGSize(
            width: max(1, min(preferred.width, visibleFrame.width - 2 * max(0, margin))),
            height: max(1, min(preferred.height, visibleFrame.height - 2 * max(0, margin) - max(0, reservedHeight)))
        )
    }

    /// Prefer the display containing most of the window; a one-pixel overlap
    /// must not defeat recovery when its old display has been disconnected.
    public static func screen(for frame: CGRect, among screens: [CGRect], fallback: CGRect) -> CGRect {
        var best = fallback
        var largestArea: CGFloat = 0
        for screen in screens {
            let intersection = frame.intersection(screen)
            let area = intersection.isNull ? 0 : intersection.width * intersection.height
            if area > largestArea {
                best = screen
                largestArea = area
            }
        }
        return best
    }

    /// Fully contain the frame, shrinking only if it cannot fit on this screen.
    public static func constrained(_ frame: CGRect, to screen: CGRect, margin: CGFloat = 16) -> CGRect {
        let inset = max(0, min(margin, (min(screen.width, screen.height) - 1) / 2))
        let bounds = screen.insetBy(dx: inset, dy: inset)
        let size = contentSize(preferred: frame.size, in: bounds, margin: 0)
        return CGRect(
            x: max(bounds.minX, min(frame.minX, bounds.maxX - size.width)),
            y: max(bounds.minY, min(frame.minY, bounds.maxY - size.height)),
            width: size.width, height: size.height
        )
    }
}
