import CoreGraphics
import Foundation

/// A quadruped gait, expressed as phase offsets for the four legs.
///
/// Each sprite is a single side-view pose, so the cycle is synthesised: the
/// lower legs below the hip line are sheared forward and back and lifted
/// during their swing phase, while the body bobs twice per stride.
public enum SpriteGait: String, Sendable, CaseIterable {
    /// Four-beat lateral sequence (hind, same-side front, other hind, other front).
    case walk
    /// Two-beat diagonal pairs (near front with far hind, then the other pair).
    case trot

    public var cycleDuration: TimeInterval {
        switch self {
        case .walk: 1.0
        case .trot: 0.5
        }
    }

    /// Horizontal foot travel from centre, as a fraction of leg height.
    var stride: Double { self == .trot ? 0.55 : 0.32 }
    /// Peak foot lift during swing, as a fraction of leg height.
    var lift: Double { self == .trot ? 0.30 : 0.18 }
    /// Body bob amplitude in source pixels.
    var bob: Double { self == .trot ? 2 : 1 }
    /// Phase offsets in cycle fractions for legs ordered left to right:
    /// hind A, hind B, front A, front B.
    public var phases: [Double] { self == .trot ? [0, 0.5, 0.5, 0] : [0, 0.5, 0.25, 0.75] }
}

/// Where the legs are in a side-view sprite. Derived from the alpha channel only.
public struct SpriteGaitAnalysis: Equatable, Sendable {
    public struct Leg: Equatable, Sendable {
        public let columns: ClosedRange<Int>
        public let phase: Double
        /// Drawn darkened behind the body; used when a leg pair is a single blob.
        public let isFar: Bool
    }

    /// Row where the lower legs begin (the belly line between the legs).
    public let hipY: Int
    /// Lowest opaque row; the feet stand here.
    public let groundY: Int
    public let legs: [Leg]

    public var legHeight: Int { groundY - hipY }
}

public enum SpriteGaitRenderer {
    private static let alphaThreshold: UInt8 = 8

    /// Renders one full gait cycle. Returns `nil` when no legs can be found.
    public static func frames(from image: CGImage, gait: SpriteGait, frameCount: Int = 8) -> [CGImage]? {
        guard let bitmap = Bitmap(image), let analysis = analyze(bitmap, gait: gait) else { return nil }
        return (0..<frameCount).map { frame in
            render(bitmap, analysis: analysis, gait: gait, phase: Double(frame) / Double(frameCount))
        }.compactMap { $0 }
    }

    public static func analyze(_ image: CGImage, gait: SpriteGait) -> SpriteGaitAnalysis? {
        Bitmap(image).flatMap { analyze($0, gait: gait) }
    }

    // MARK: Analysis

    private static func analyze(_ bitmap: Bitmap, gait: SpriteGait) -> SpriteGaitAnalysis? {
        let width = bitmap.width
        var bottom = [Int](repeating: -1, count: width)
        var top = bitmap.height
        for x in 0..<width {
            for y in stride(from: bitmap.height - 1, through: 0, by: -1) where bitmap.alpha(x, y) > alphaThreshold {
                bottom[x] = max(bottom[x], y)
                break
            }
            for y in 0..<bitmap.height where bitmap.alpha(x, y) > alphaThreshold {
                top = min(top, y)
                break
            }
        }
        guard let groundY = bottom.max(), groundY >= 0 else { return nil }

        // Columns whose lowest pixel touches the ground are feet.
        let touchesGround = bottom.map { $0 >= groundY - 2 }
        var runs: [ClosedRange<Int>] = []
        var x = 0
        while x < width {
            guard touchesGround[x] else { x += 1; continue }
            var end = x
            while end + 1 < width, touchesGround[end + 1] || (end + 2 < width && touchesGround[end + 2]) {
                end += 1
            }
            if end - x + 1 >= 2 { runs.append(x...end) }
            x = end + 1
        }
        guard let first = runs.first, let last = runs.last else { return nil }

        // The belly between the legs sets the hip line.
        let gapBottoms = (first.lowerBound...last.upperBound)
            .filter { !touchesGround[$0] && bottom[$0] >= 0 }
            .map { bottom[$0] }
            .sorted()
        let bodyHeight = groundY - top
        var hipY = gapBottoms.count >= 2 ? gapBottoms[gapBottoms.count / 2] : groundY - bodyHeight / 4
        hipY = min(max(hipY, groundY - Int(Double(bodyHeight) * 0.45)), groundY - max(3, bodyHeight / 10))

        // Normalise to four legs, cloning a far leg when a pair is one blob.
        while runs.count > 4 {
            var closest = 0
            for index in 1..<runs.count - 1
            where runs[index + 1].lowerBound - runs[index].upperBound
                < runs[closest + 1].lowerBound - runs[closest].upperBound {
                closest = index
            }
            runs[closest] = runs[closest].lowerBound...runs[closest + 1].upperBound
            runs.remove(at: closest + 1)
        }
        if runs.count == 1 || runs.count == 3 {
            let widest = runs.indices.max { runs[$0].count < runs[$1].count }!
            let run = runs[widest]
            if run.count >= 6 {
                let middle = run.lowerBound + run.count / 2
                runs.replaceSubrange(widest...widest, with: [run.lowerBound...(middle - 1), middle...run.upperBound])
            }
        }

        let phases = gait.phases
        let legs: [SpriteGaitAnalysis.Leg]
        switch runs.count {
        case 4:
            legs = zip(runs, phases).map { .init(columns: $0, phase: $1, isFar: false) }
        case 2:
            legs = [
                .init(columns: runs[0], phase: phases[0], isFar: false),
                .init(columns: runs[0], phase: phases[1], isFar: true),
                .init(columns: runs[1], phase: phases[2], isFar: false),
                .init(columns: runs[1], phase: phases[3], isFar: true),
            ]
        default:
            // ponytail: a single narrow blob (biped or merged legs) gets near/far clones only.
            legs = [
                .init(columns: runs[0], phase: phases[0], isFar: false),
                .init(columns: runs[0], phase: phases[2], isFar: true),
            ]
        }
        return SpriteGaitAnalysis(hipY: hipY, groundY: groundY, legs: legs)
    }

    // MARK: Rendering

    private static func render(_ source: Bitmap, analysis: SpriteGaitAnalysis, gait: SpriteGait, phase: Double) -> CGImage? {
        var output = Bitmap(width: source.width, height: source.height)
        let legHeight = Double(analysis.legHeight)
        let bob = (gait.bob * 0.5 * (1 - cos(4 * .pi * phase))).rounded()

        var isLegPixel = [Bool](repeating: false, count: source.width * source.height)
        for leg in analysis.legs where !leg.isFar {
            for y in (analysis.hipY + 1)...analysis.groundY {
                for x in leg.columns where source.alpha(x, y) > alphaThreshold {
                    isLegPixel[y * source.width + x] = true
                }
            }
        }

        func draw(_ leg: SpriteGaitAnalysis.Leg) {
            let angle = 2 * .pi * (phase + leg.phase)
            let footDX = gait.stride * legHeight * cos(angle)
            let liftPX = gait.lift * legHeight * max(0, -sin(angle))
            for y in (analysis.hipY + 1)...analysis.groundY {
                let depth = Double(y - analysis.hipY) / legHeight
                let dx = Int((footDX * depth).rounded())
                let dy = -Int((liftPX * depth).rounded()) - Int((bob * (1 - depth)).rounded())
                for x in leg.columns where source.alpha(x, y) > alphaThreshold {
                    output.blit(from: source, x: x, y: y, toX: x + dx, y: y + dy, shade: leg.isFar ? 0.72 : 1)
                }
            }
        }

        for leg in analysis.legs where leg.isFar { draw(leg) }
        let bodyShift = -Int(bob)
        for y in 0..<source.height {
            for x in 0..<source.width
            where source.alpha(x, y) > alphaThreshold && !isLegPixel[y * source.width + x] {
                output.blit(from: source, x: x, y: y, toX: x, y: y + bodyShift, shade: 1)
            }
        }
        for leg in analysis.legs where !leg.isFar { draw(leg) }
        return output.makeImage()
    }

    // MARK: Pixels

    /// RGBA8, premultiplied, rows top to bottom.
    private struct Bitmap {
        let width: Int
        let height: Int
        var pixels: [UInt8]

        init(width: Int, height: Int) {
            self.width = width
            self.height = height
            pixels = [UInt8](repeating: 0, count: width * height * 4)
        }

        init?(_ image: CGImage) {
            width = image.width
            height = image.height
            pixels = [UInt8](repeating: 0, count: width * height * 4)
            let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
                guard let context = CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                ) else { return false }
                context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                return true
            }
            guard drawn else { return nil }
        }

        func alpha(_ x: Int, _ y: Int) -> UInt8 {
            pixels[(y * width + x) * 4 + 3]
        }

        mutating func blit(from source: Bitmap, x: Int, y: Int, toX: Int, y toY: Int, shade: Double) {
            guard toX >= 0, toX < width, toY >= 0, toY < height else { return }
            let from = (y * source.width + x) * 4
            let to = (toY * width + toX) * 4
            for channel in 0..<3 {
                pixels[to + channel] = UInt8(Double(source.pixels[from + channel]) * shade)
            }
            pixels[to + 3] = source.pixels[from + 3]
        }

        func makeImage() -> CGImage? {
            var copy = pixels
            return copy.withUnsafeMutableBytes { buffer in
                CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                )?.makeImage()
            }
        }
    }
}
