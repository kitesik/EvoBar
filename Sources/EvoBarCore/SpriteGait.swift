import CoreGraphics
import Foundation

/// A quadruped gait, expressed as phase offsets for the four legs.
///
/// Each sprite is a single side-view pose, so the cycle is synthesised: each
/// leg swings about its hip like a pendulum, lifts during its swing phase, and
/// the body bobs twice per stride. The swing fades in over the top of the leg so
/// the hip stays attached, and a leg drawn stretched out in a running pose
/// still moves as one piece instead of tearing.
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

    /// Peak swing of a leg about its hip, in radians.
    var swing: Double { self == .trot ? 25 * .pi / 180 : 15 * .pi / 180 }
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

        /// Maximal column runs where `included` holds, bridging single-column gaps.
        func columnRuns(_ included: [Bool]) -> [ClosedRange<Int>] {
            var runs: [ClosedRange<Int>] = []
            var x = 0
            while x < width {
                guard included[x] else { x += 1; continue }
                var end = x
                while end + 1 < width, included[end + 1] || (end + 2 < width && included[end + 2]) {
                    end += 1
                }
                if end - x + 1 >= 2 { runs.append(x...end) }
                x = end + 1
            }
            return runs
        }

        // Feet touch the ground. The widest gap between feet is the belly between
        // hind and front legs; its underside is the hip line. Smaller gaps (between
        // the two legs of a pair) sit near the ground and must not pull the hip down.
        let groundRuns = columnRuns(bottom.map { $0 >= groundY - 2 })
        guard !groundRuns.isEmpty else { return nil }
        let bodyHeight = groundY - top
        var hipY = groundY - Int(Double(bodyHeight) * 0.3)
        if groundRuns.count >= 2 {
            var bellyGap = 0..<0
            for index in 0..<(groundRuns.count - 1) {
                let gap = (groundRuns[index].upperBound + 1)..<groundRuns[index + 1].lowerBound
                if gap.count > bellyGap.count { bellyGap = gap }
            }
            let bellyBottoms = bellyGap.map { bottom[$0] }.filter { $0 >= 0 }.sorted()
            if bellyBottoms.count >= 2 { hipY = bellyBottoms[bellyBottoms.count / 2] }
        }
        let legHeight = groundY - hipY
        if legHeight < Int(Double(bodyHeight) * 0.18) { hipY = groundY - Int(Double(bodyHeight) * 0.3) }
        hipY = max(hipY, groundY - Int(Double(bodyHeight) * 0.5))

        // Legs are whatever reaches well below the hip line, so a leg raised off
        // the ground in a running pose still gets its own phase, while the belly
        // sagging a few pixels under the line does not count.
        let legReach = hipY + Int(Double(groundY - hipY) * 0.35)
        // A low-hanging tail also reaches past the hip line. When both leg pairs
        // stand on the ground, legs stay within a short reach of the outermost
        // feet and anything beyond is body. A one-foot running pose cannot be
        // clipped this way, so it keeps every run.
        let margin = Int(Double(groundY - hipY) * 0.25)
        let legSpan = groundRuns.count >= 2
            ? (groundRuns.first!.lowerBound - margin)...(groundRuns.last!.upperBound + margin)
            : 0...(width - 1)
        var runs = columnRuns(bottom.map { $0 > legReach }).compactMap { run -> ClosedRange<Int>? in
            let lower = max(run.lowerBound, legSpan.lowerBound)
            let upper = min(run.upperBound, legSpan.upperBound)
            return upper - lower >= 1 ? lower...upper : nil
        }
        guard !runs.isEmpty else { return nil }

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

        // Each leg swings as a pendulum about the middle of its hip. The swing
        // fades in over the top third of the leg so the joint never opens, and the
        // foot lifts during the swing phase while the hip follows the body bob.
        func draw(_ leg: SpriteGaitAnalysis.Leg) {
            let cycle = 2 * .pi * (phase + leg.phase)
            let theta = gait.swing * cos(cycle)
            let liftPX = gait.lift * legHeight * max(0, -sin(cycle))
            let pivotX = Double(leg.columns.lowerBound + leg.columns.upperBound) / 2
            let pivotY = Double(analysis.hipY)
            let (sinT, cosT) = (sin(theta), cos(theta))
            for y in (analysis.hipY + 1)...analysis.groundY {
                let depth = Double(y - analysis.hipY) / legHeight
                let weight = min(1, depth / 0.3)
                let dy = -liftPX * depth - bob * (1 - depth)
                for x in leg.columns where source.alpha(x, y) > alphaThreshold {
                    // Map the four quarters of the pixel so a rotated limb has no pinholes.
                    for (qx, qy) in [(-0.25, -0.25), (0.25, -0.25), (-0.25, 0.25), (0.25, 0.25)] {
                        let px = Double(x) + qx
                        let py = Double(y) + qy
                        let rx = px - pivotX
                        let ry = py - pivotY
                        let swungX = pivotX + rx * cosT - ry * sinT
                        let swungY = pivotY + rx * sinT + ry * cosT
                        let toX = Int((px + weight * (swungX - px)).rounded())
                        let toY = Int((py + weight * (swungY - py) + dy).rounded())
                        output.blit(from: source, x: x, y: y, toX: toX, y: toY, shade: leg.isFar ? 0.72 : 1)
                    }
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
