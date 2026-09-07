import CoreGraphics
import Foundation

/// A quadruped gait, expressed as footfall phases and a stride profile.
///
/// Each sprite is a single side-view pose, so the cycle is synthesised. A leg is
/// posed as two rigid bones, thigh and shin, hinged at hip and knee. A planted
/// foot slides backward at constant speed while a lifted foot tucks and swings
/// forward, which is what makes the animal read as moving forward over the
/// scrolling ground.
public enum SpriteGait: String, Sendable, CaseIterable {
    /// Four-beat lateral sequence (hind, same-side front, other hind, other front).
    case walk
    /// Two-beat diagonal pairs (near front with far hind, then the other pair).
    case trot

    public var cycleDuration: TimeInterval {
        switch self {
        case .walk: 1.1
        case .trot: 0.6
        }
    }

    /// Fraction of the cycle each foot spends planted (the duty factor). A walk
    /// keeps feet down longer than half the time; a trot is close to half.
    public var stanceFraction: Double { self == .trot ? 0.5 : 0.62 }
    /// Peak swing of the whole leg about its hip, in radians.
    var hipSwing: Double { self == .trot ? 22 * .pi / 180 : 15 * .pi / 180 }
    /// Peak flexion of the shin about the knee, in radians. This is what lifts
    /// the foot clear of the ground, so no separate vertical offset is needed
    /// and the leg never separates at a joint.
    var kneeFlex: Double { self == .trot ? 34 * .pi / 180 : 22 * .pi / 180 }
    /// Body rise and fall in source pixels, twice per stride.
    var bob: Double { self == .trot ? 2 : 1 }
    /// Phase offsets in cycle fractions for legs ordered hind, hind, front, front.
    public var phases: [Double] { self == .trot ? [0, 0.5, 0.5, 0] : [0, 0.5, 0.25, 0.75] }

    /// Where a foot is at cycle position `t` (0 ..< 1, 0 = touchdown).
    ///
    /// `forward` runs from +1 (foot at its foremost point) to -1 (rearmost). A
    /// planted foot slides backward at constant speed; a lifted foot swings
    /// forward in an arc. `lift` is 0 while planted and peaks mid-swing.
    public func footState(at t: Double) -> (forward: Double, lift: Double) {
        let t = t - t.rounded(.down)
        if t < stanceFraction {
            return (1 - 2 * t / stanceFraction, 0)
        }
        let s = (t - stanceFraction) / (1 - stanceFraction)
        return (-cos(.pi * s), sin(.pi * s))
    }
}

/// Where the legs are in a side-view sprite. Derived from the alpha channel only.
public struct SpriteGaitAnalysis: Equatable, Sendable {
    public struct Leg: Equatable, Sendable {
        /// Source columns this leg poses. Legs of a pair drawn as one mass share
        /// a few columns so the split between them is an overlap, never a cut.
        public let columns: ClosedRange<Int>
        /// Column the hip and knee joints sit on.
        public let pivotX: Int
        public let phase: Double
        /// A leg the sprite does not draw, standing in for the far side of a
        /// pair. Darkened, and the body covers it wherever they meet.
        public let isFar: Bool
    }

    /// Row where the legs begin: the underside of the belly between the leg pairs.
    public let hipY: Int
    /// Lowest opaque row of the animal itself; the feet stand here.
    public let groundY: Int
    /// Horizontal extent that holds legs. Anything outside is body or tail.
    public let legSpan: ClosedRange<Int>
    /// Columns carrying leg material rather than the belly dipping past the hip.
    public let isLegColumn: [Bool]
    /// Near legs first, then any far stand-ins.
    public let legs: [Leg]

    public var legHeight: Int { groundY - hipY }
    public var drawnLegs: [Leg] { legs.filter { !$0.isFar } }
}

public enum SpriteGaitRenderer {
    private static let alphaThreshold: UInt8 = 8

    /// Renders one full gait cycle. Returns `nil` when no legs can be found.
    public static func frames(from image: CGImage, gait: SpriteGait, frameCount: Int = 8) -> [CGImage]? {
        guard let bitmap = Bitmap(image) else { return nil }
        let body = mainComponent(bitmap)
        guard let analysis = analyze(bitmap, body: body, gait: gait) else { return nil }
        let rig = Rig(analysis: analysis, bitmap: bitmap, body: body)
        return (0..<frameCount).compactMap { frame in
            rig.render(gait: gait, phase: Double(frame) / Double(frameCount))
        }
    }

    public static func analyze(_ image: CGImage, gait: SpriteGait) -> SpriteGaitAnalysis? {
        guard let bitmap = Bitmap(image) else { return nil }
        return analyze(bitmap, body: mainComponent(bitmap), gait: gait)
    }

    // MARK: Silhouette

    /// The largest connected run of opaque pixels: the animal itself. Sparkles,
    /// glow wisps and stray fragments left by sheet extraction are excluded, so a
    /// speck below the paws cannot be mistaken for the ground.
    private static func mainComponent(_ bitmap: Bitmap) -> [Bool] {
        let width = bitmap.width, height = bitmap.height
        var label = [Int32](repeating: 0, count: width * height)
        var best: (id: Int32, size: Int) = (0, 0)
        var next: Int32 = 0
        var stack: [Int] = []
        for start in 0..<(width * height)
        where label[start] == 0 && bitmap.pixels[start * 4 + 3] > alphaThreshold {
            next += 1
            var size = 0
            stack.append(start)
            label[start] = next
            while let index = stack.popLast() {
                size += 1
                let (x, y) = (index % width, index / width)
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let (nx, ny) = (x + dx, y + dy)
                    guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                    let neighbour = ny * width + nx
                    guard label[neighbour] == 0, bitmap.pixels[neighbour * 4 + 3] > alphaThreshold else { continue }
                    label[neighbour] = next
                    stack.append(neighbour)
                }
            }
            if size > best.size { best = (next, size) }
        }
        return label.map { $0 == best.id && $0 != 0 }
    }

    // MARK: Analysis

    /// Maximal runs of `true`, discarding runs narrower than two columns.
    /// `bridge` closes gaps of that many columns, joining a leg split by an outline.
    private static func columnRuns(_ included: [Bool], bridge: Int) -> [ClosedRange<Int>] {
        var runs: [ClosedRange<Int>] = []
        var x = 0
        while x < included.count {
            guard included[x] else { x += 1; continue }
            var end = x
            while end + 1 < included.count {
                let next = (1...max(1, bridge + 1)).first { end + $0 < included.count && included[end + $0] }
                guard let next else { break }
                end += next
            }
            if end - x + 1 >= 2 { runs.append(x...end) }
            x = end + 1
        }
        return runs
    }

    private static func analyze(_ bitmap: Bitmap, body: [Bool], gait: SpriteGait) -> SpriteGaitAnalysis? {
        let width = bitmap.width
        var bottom = [Int](repeating: -1, count: width)
        var top = bitmap.height
        for x in 0..<width {
            for y in stride(from: bitmap.height - 1, through: 0, by: -1) where body[y * width + x] {
                bottom[x] = max(bottom[x], y)
                break
            }
            for y in 0..<bitmap.height where body[y * width + x] {
                top = min(top, y)
                break
            }
        }
        guard let groundY = bottom.max(), groundY >= 0 else { return nil }

        // Feet touch the ground. The widest gap between feet is the belly between
        // hind and front legs; its underside is the hip line. Smaller gaps (between
        // the two legs of a pair) sit near the ground and must not pull the hip down.
        let groundRuns = columnRuns(bottom.map { $0 >= groundY - 2 }, bridge: 2)
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
        if groundY - hipY < Int(Double(bodyHeight) * 0.18) { hipY = groundY - Int(Double(bodyHeight) * 0.3) }
        hipY = max(hipY, groundY - Int(Double(bodyHeight) * 0.5))
        let legHeight = groundY - hipY
        guard legHeight >= 6 else { return nil }

        // A low-hanging tail also reaches past the hip line. When both leg pairs
        // stand on the ground, legs stay within a short reach of the outermost
        // feet and anything beyond is body. A one-foot running pose cannot be
        // clipped this way, so it keeps the full width.
        let margin = Int(Double(legHeight) * 0.25)
        let legSpan = groundRuns.count >= 2
            ? max(0, groundRuns.first!.lowerBound - margin)...min(width - 1, groundRuns.last!.upperBound + margin)
            : 0...(width - 1)

        // The belly dips a little past the hip line between the pairs. Posing that
        // with a leg would drag the outline across the gap, so a column counts as
        // leg only when it carries material well down the shin.
        let shinY = hipY + Int(Double(legHeight) * 0.45)
        var isLegColumn = [Bool](repeating: false, count: width)
        for x in legSpan {
            isLegColumn[x] = (shinY...groundY).contains { body[$0 * width + x] }
        }

        // Legs merge into the body near the hip and separate lower down, so count
        // them on the row that shows the most. Toes and outline breaks would
        // otherwise register as extra legs, and a leg torn in two would animate as
        // two halves, so near-touching runs are one leg and slivers are dropped.
        let minGap = max(2, Int(Double(legHeight) * 0.10))
        let minWidth = max(4, Int(Double(legHeight) * 0.22))
        var best: [ClosedRange<Int>] = []
        for fraction in [0.55, 0.65, 0.75, 0.85, 0.95] {
            let y = min(groundY, hipY + Int(Double(legHeight) * fraction))
            let included = (0..<width).map { x in
                legSpan.contains(x) && isLegColumn[x] && body[y * width + x]
            }
            var runs: [ClosedRange<Int>] = []
            for run in columnRuns(included, bridge: 1) {
                if let last = runs.last, run.lowerBound - last.upperBound <= minGap {
                    runs[runs.count - 1] = last.lowerBound...run.upperBound
                } else {
                    runs.append(run)
                }
            }
            runs = runs.filter { $0.count >= minWidth }
            while runs.count > 4 { runs = mergingClosestPair(runs) }
            if runs.count > best.count { best = runs }
        }
        guard !best.isEmpty else { return nil }
        if best.count == 1, best[0].count >= 6 {
            best = halving(best[0])
        }

        // Split into hind and front at the widest gap; a lopsided split of four
        // means the gap found was inside a pair, so halve them instead.
        var splitIndex = best.count / 2
        if best.count >= 2 {
            var widest = 0
            for index in 0..<(best.count - 1) {
                let gap = best[index + 1].lowerBound - best[index].upperBound
                let widestGap = best[widest + 1].lowerBound - best[widest].upperBound
                if gap > widestGap { widest = index }
            }
            let candidate = widest + 1
            splitIndex = (best.count == 4 && (candidate == 1 || candidate == 3)) ? 2 : candidate
        }
        let groups = [Array(best[0..<splitIndex]), Array(best[splitIndex...])]

        var detected: [(run: ClosedRange<Int>, phase: Double, standIn: Bool)] = []
        for (groupIndex, group) in groups.enumerated() where !group.isEmpty {
            let phases = [gait.phases[groupIndex * 2], gait.phases[groupIndex * 2 + 1]]
            // A mass wide enough to hold both legs of the pair is halved. A narrow
            // one is a single drawn leg, so the far leg becomes a stand-in.
            var runs = Array(group.prefix(2))
            if runs.count == 1, runs[0].count >= max(6, Int(Double(legHeight) * 0.55)) {
                runs = halving(runs[0])
            }
            for (offset, run) in runs.enumerated() {
                detected.append((run, phases[offset], false))
            }
            if runs.count == 1 { detected.append((runs[0], phases[1], true)) }
        }
        let drawn = detected.filter { !$0.standIn }
        guard !drawn.isEmpty else { return nil }

        // Every column under the belly must belong to some leg. A leg's detected
        // run is only its narrowest point, so ownership grows to the midpoint
        // between neighbours, with a small lap so no seam can open between them.
        // Anything left out would be dropped by the body and drawn by no leg,
        // which is exactly how a notch gets cut out of a thigh.
        let lap = max(1, Int(Double(legHeight) * 0.08))
        func ownership(of index: Int) -> ClosedRange<Int> {
            let run = drawn[index].run
            let lower = index == 0
                ? legSpan.lowerBound
                : (drawn[index - 1].run.upperBound + run.lowerBound) / 2 - lap
            let upper = index == drawn.count - 1
                ? legSpan.upperBound
                : (run.upperBound + drawn[index + 1].run.lowerBound) / 2 + lap
            let start = max(legSpan.lowerBound, min(lower, run.lowerBound))
            let end = min(legSpan.upperBound, max(upper, run.upperBound))
            return start...end
        }

        var legs: [SpriteGaitAnalysis.Leg] = []
        var standIns: [SpriteGaitAnalysis.Leg] = []
        var drawnIndex = 0
        for entry in detected {
            if entry.standIn {
                let source = legs[legs.count - 1]
                standIns.append(
                    .init(columns: source.columns, pivotX: source.pivotX, phase: entry.phase, isFar: true)
                )
            } else {
                legs.append(
                    .init(
                        columns: ownership(of: drawnIndex),
                        pivotX: (entry.run.lowerBound + entry.run.upperBound) / 2,
                        phase: entry.phase,
                        isFar: false
                    )
                )
                drawnIndex += 1
            }
        }
        return SpriteGaitAnalysis(
            hipY: hipY,
            groundY: groundY,
            legSpan: legSpan,
            isLegColumn: isLegColumn,
            legs: legs + standIns
        )
    }

    private static func halving(_ run: ClosedRange<Int>) -> [ClosedRange<Int>] {
        let middle = run.lowerBound + run.count / 2
        return [run.lowerBound...(middle - 1), middle...run.upperBound]
    }

    private static func mergingClosestPair(_ runs: [ClosedRange<Int>]) -> [ClosedRange<Int>] {
        var runs = runs
        var closest = 0
        for index in 1..<(runs.count - 1)
        where runs[index + 1].lowerBound - runs[index].upperBound
            < runs[closest + 1].lowerBound - runs[closest].upperBound {
            closest = index
        }
        runs[closest] = runs[closest].lowerBound...runs[closest + 1].upperBound
        runs.remove(at: closest + 1)
        return runs
    }

    // MARK: Rig

    private struct Point {
        var x: Double
        var y: Double
    }

    private static func rotate(_ point: Point, about pivot: Point, by angle: Double) -> Point {
        let (sinA, cosA) = (sin(angle), cos(angle))
        let (rx, ry) = (point.x - pivot.x, point.y - pivot.y)
        return Point(x: pivot.x + rx * cosA - ry * sinA, y: pivot.y + rx * sinA + ry * cosA)
    }

    /// One leg posed as two rigid bones hinged at hip and knee.
    ///
    /// Only the inverse direction is used when drawing: every destination pixel
    /// asks which source pixel it came from, so a posed limb gets exactly one
    /// lookup per pixel and can never open a hole or double-write.
    private struct LegPose {
        let hip: Point
        let hipAngle: Double
        /// The body's rise and fall, applied to the whole animal.
        let shift: Point
        /// Where the hip rotation carried the knee.
        let knee: Point
        let kneeAngle: Double

        init(hip: Point, hipAngle: Double, shift: Point, kneeSource: Point, kneeAngle: Double) {
            self.hip = hip
            self.hipAngle = hipAngle
            self.shift = shift
            self.kneeAngle = kneeAngle
            let turned = SpriteGaitRenderer.rotate(kneeSource, about: hip, by: hipAngle)
            knee = Point(x: turned.x + shift.x, y: turned.y + shift.y)
        }

        func thighSource(of point: Point) -> Point {
            SpriteGaitRenderer.rotate(
                Point(x: point.x - shift.x, y: point.y - shift.y),
                about: hip,
                by: -hipAngle
            )
        }

        func shinSource(of point: Point) -> Point {
            thighSource(of: SpriteGaitRenderer.rotate(point, about: knee, by: -kneeAngle))
        }
    }

    /// The source sprite plus everything needed to pose it, computed once.
    private struct Rig {
        let analysis: SpriteGaitAnalysis
        let bitmap: Bitmap
        let body: [Bool]
        /// Leg pixels below the hip cap, excluded from the body so the torso never
        /// drags them along.
        let isLegPixel: [Bool]
        /// The top rows of the leg, drawn with the body and never posed. The cap
        /// hides where the thigh pivots, so the hip joint cannot open however far
        /// the leg swings, and the legs still own those rows as source material.
        let capY: Int
        let kneeY: Int

        init(analysis: SpriteGaitAnalysis, bitmap: Bitmap, body: [Bool]) {
            self.analysis = analysis
            self.bitmap = bitmap
            self.body = body
            let legHeight = analysis.legHeight
            capY = analysis.hipY + max(2, Int(Double(legHeight) * 0.18))
            kneeY = analysis.hipY + Int(Double(legHeight) * 0.5)

            var isLegPixel = [Bool](repeating: false, count: bitmap.width * bitmap.height)
            for y in (capY + 1)...analysis.groundY {
                for x in analysis.legSpan
                where analysis.isLegColumn[x] && body[y * bitmap.width + x] {
                    isLegPixel[y * bitmap.width + x] = true
                }
            }
            self.isLegPixel = isLegPixel
        }

        /// Whether a source point belongs to the given leg segment. Leg material
        /// starts under the belly line, and the cap rows count too so a swung leg
        /// always has something to fill the space beneath the cap.
        private func contains(_ point: Point, leg: SpriteGaitAnalysis.Leg, rows: ClosedRange<Int>) -> Bool {
            let x = Int(point.x.rounded()), y = Int(point.y.rounded())
            guard leg.columns.contains(x), rows.contains(y),
                  x >= 0, x < bitmap.width, y >= 0, y < bitmap.height,
                  analysis.isLegColumn[x], body[y * bitmap.width + x] else { return false }
            return true
        }

        func render(gait: SpriteGait, phase: Double) -> CGImage? {
            var output = Bitmap(width: bitmap.width, height: bitmap.height)
            let legHeight = Double(analysis.legHeight)
            let bob = (gait.bob * 0.5 * (1 - cos(4 * .pi * phase))).rounded()
            let bodyShift = Point(x: 0, y: -bob)

            // Two bones per leg, both rigid, so the knee cannot come apart.
            let poses: [(leg: SpriteGaitAnalysis.Leg, pose: LegPose)] = analysis.legs.map { leg in
                let foot = gait.footState(at: phase + leg.phase)
                let hip = Point(x: Double(leg.pivotX), y: Double(analysis.hipY))
                return (
                    leg,
                    LegPose(
                        hip: hip,
                        // The animal faces right, so a positive rotation carries a foot backward.
                        hipAngle: -gait.hipSwing * foot.forward,
                        shift: bodyShift,
                        kneeSource: Point(x: hip.x, y: Double(kneeY)),
                        kneeAngle: gait.kneeFlex * foot.lift
                    )
                )
            }

            // The body is topmost: a swinging leg can never cut into the torso.
            for y in 0..<bitmap.height {
                for x in 0..<bitmap.width {
                    let index = y * bitmap.width + x
                    let source = Point(x: Double(x) - bodyShift.x, y: Double(y) - bodyShift.y)
                    let (sx, sy) = (Int(source.x.rounded()), Int(source.y.rounded()))
                    guard sx >= 0, sx < bitmap.width, sy >= 0, sy < bitmap.height else { continue }
                    let from = sy * bitmap.width + sx
                    guard bitmap.pixels[from * 4 + 3] > alphaThreshold, !isLegPixel[from] else { continue }
                    output.copy(from: bitmap, at: from, to: index, shade: 1)
                }
            }

            // Legs fill only what the body left empty, near legs before stand-ins.
            let reach = Int(legHeight * 0.6) + 2
            let rows = max(0, analysis.hipY - reach)...min(bitmap.height - 1, analysis.groundY + reach)
            let firstColumn = max(0, analysis.legSpan.lowerBound - reach)
            let lastColumn = min(bitmap.width - 1, analysis.legSpan.upperBound + reach)
            let columns = firstColumn...lastColumn
            for y in rows {
                for x in columns {
                    let index = y * bitmap.width + x
                    guard output.pixels[index * 4 + 3] == 0 else { continue }
                    let point = Point(x: Double(x), y: Double(y))
                    for (leg, pose) in poses {
                        let candidates = [
                            (pose.shinSource(of: point), (kneeY + 1)...analysis.groundY),
                            (pose.thighSource(of: point), (analysis.hipY + 1)...kneeY),
                        ]
                        guard let hit = candidates.first(where: { contains($0.0, leg: leg, rows: $0.1) })
                        else { continue }
                        let from = Int(hit.0.y.rounded()) * bitmap.width + Int(hit.0.x.rounded())
                        output.copy(from: bitmap, at: from, to: index, shade: leg.isFar ? 0.62 : 1)
                        break
                    }
                }
            }
            return output.makeImage()
        }
    }

    // MARK: Pixels

    /// RGBA8, premultiplied, rows top to bottom.
    fileprivate struct Bitmap {
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

        mutating func copy(from source: Bitmap, at from: Int, to: Int, shade: Double) {
            for channel in 0..<3 {
                pixels[to * 4 + channel] = UInt8(Double(source.pixels[from * 4 + channel]) * shade)
            }
            pixels[to * 4 + 3] = source.pixels[from * 4 + 3]
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
