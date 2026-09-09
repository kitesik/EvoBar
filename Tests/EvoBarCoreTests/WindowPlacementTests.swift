import EvoBarCore
import Foundation
import Testing

struct WindowPlacementTests {
    private let preferred = CGSize(width: 420, height: 700)
    private let main = CGRect(x: 0, y: 24, width: 1440, height: 876)

    @Test func normalScreenKeepsPreferredSize() {
        #expect(WindowPlacement.contentSize(preferred: preferred, in: main, reservedHeight: 44) == preferred)
    }

    @Test func shortDisplayNeverForcesTheOld480PointMinimum() {
        let screen = CGRect(x: 0, y: 0, width: 640, height: 450)
        let size = WindowPlacement.contentSize(preferred: preferred, in: screen, reservedHeight: 44)
        #expect(size == CGSize(width: 420, height: 374))
        #expect(size.height + 44 + 32 <= screen.height)
    }

    @Test func narrowScreenFitsWidthAndKeepsPositiveSize() {
        #expect(WindowPlacement.contentSize(preferred: preferred, in: CGRect(x: 0, y: 0, width: 360, height: 500)).width == 328)
        #expect(WindowPlacement.contentSize(preferred: preferred, in: .zero) == CGSize(width: 1, height: 1))
    }

    @Test func choosesTheScreenWithLargestIntersection() {
        let left = CGRect(x: -1280, y: -300, width: 1280, height: 800)
        let crossing = CGRect(x: -400, y: 30, width: 420, height: 400)
        #expect(WindowPlacement.screen(for: crossing, among: [main, left], fallback: main) == left)
    }

    @Test func disconnectedScreenFallsBackAndRecoversWholeWindow() {
        let stranded = CGRect(x: 2400, y: 300, width: 420, height: 728)
        let target = WindowPlacement.screen(for: stranded, among: [main], fallback: main)
        let result = WindowPlacement.constrained(stranded, to: target)
        #expect(target == main)
        #expect(main.insetBy(dx: 16, dy: 16).contains(result))
        #expect(result.size == stranded.size)
    }

    @Test func onePixelOverlapStillRecoversTheEntirePet() {
        let partlyVisible = CGRect(x: main.maxX - 1, y: 60, width: 312, height: 252)
        let result = WindowPlacement.constrained(partlyVisible, to: main, margin: 8)
        #expect(main.insetBy(dx: 8, dy: 8).contains(result))
        #expect(result.size == partlyVisible.size)
    }

    @Test func negativeOriginsAndOversizedFramesAreHandled() {
        let below = CGRect(x: -900, y: -700, width: 900, height: 700)
        let oversized = CGRect(x: -2000, y: -2000, width: 1200, height: 1000)
        let fitted = WindowPlacement.constrained(oversized, to: below)
        #expect(fitted == below.insetBy(dx: 16, dy: 16))
        #expect(WindowPlacement.constrained(fitted, to: below) == fitted)
    }

    @Test func safePlacementDoesNotMoveOrResizeAnything() {
        let frame = CGRect(x: 230, y: 90, width: 420, height: 728)
        #expect(WindowPlacement.constrained(frame, to: main) == frame)
    }
}
