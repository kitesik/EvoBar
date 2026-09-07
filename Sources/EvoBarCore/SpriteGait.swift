import CoreGraphics
import Foundation

/// A quadruped gait, expressed as footfall phases and a stride profile.
///
/// Each sprite is a single side-view pose, so the cycle is synthesised. A foot
/// is driven along a target path and the leg is solved to reach it, rather than
/// the leg being swung and the foot going wherever it lands. A planted foot
/// stays on the ground and slides backward at constant speed, which is what
/// makes the animal read as moving forward over the scrolling ground.
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
    /// Half the stride, as a fraction of leg length. A dog's hip swings through
    /// roughly 25 degrees each way at a walk and further at a trot; anything
    /// much shorter reads as a shuffle.
    public var strideFraction: Double { self == .trot ? 0.46 : 0.40 }
    /// Peak foot clearance during swing, as a fraction of leg length.
    var liftFraction: Double { self == .trot ? 0.24 : 0.14 }
    /// The most the body may rise above its drawn height, in source pixels.
    /// How far it drops is decided by the planted legs.
    var bob: Double { self == .trot ? 2 : 1 }
    /// Phase offsets in cycle fractions for legs ordered hind, hind, front, front.
    public var phases: [Double] { self == .trot ? [0, 0.5, 0.5, 0] : [0, 0.5, 0.25, 0.75] }

    /// How fast the ground passes under the animal, in leg lengths per second.
    /// A planted foot covers twice the stride amplitude in one stance, so the
    /// scene must scroll at exactly this rate or the feet skate.
    public var groundSpeedInLegLengths: Double {
        2 * strideFraction / (cycleDuration * stanceFraction)
    }

    /// Where a foot is at cycle position `t` (0 ..< 1, 0 = touchdown).
    ///
    /// `forward` runs from +1 (foot at its foremost point) to -1 (rearmost). A
    /// planted foot slides backward at constant speed; a lifted foot swings
    /// forward in an arc. `lift` is 0 while planted and peaks just past the
    /// middle of the swing, so the foot snaps up and reaches down to land.
    public func footState(at t: Double) -> (forward: Double, lift: Double) {
        let t = t - t.rounded(.down)
        if t < stanceFraction {
            return (1 - 2 * t / stanceFraction, 0)
        }
        let s = (t - stanceFraction) / (1 - stanceFraction)
        return (-cos(.pi * s), pow(sin(.pi * s), 0.75))
    }
}

/// How the source sprite was drawn, which decides how far above the ground a
/// leg may end. A standing animal has every foot on or nearly on the ground, so
/// anything hanging higher is tail or fur; a running one stretches its legs
/// well clear of it.
public enum SpritePose: Sendable {
    case standing
    case running

    /// Highest a foot may hang above the ground, as a fraction of body height.
    var footClearance: Double { self == .running ? 0.12 : 0.04 }
}

/// Where the legs are in a side-view sprite. Derived from the alpha channel only.
public struct SpriteGaitAnalysis: Equatable, Sendable {
    public struct Leg: Equatable, Sendable {
        /// Source columns this leg poses. Every column under the belly belongs to
        /// exactly one leg, with a small lap between neighbours.
        public let columns: ClosedRange<Int>
        /// Column the hip sits on.
        public let pivotX: Int
        /// Where this leg's foot is drawn. The gait oscillates around it, so the
        /// artist's pose is kept rather than overwritten.
        public let footX: Int
        public let footY: Int
        public let phase: Double
        /// Hind legs fold their joint forward, front legs fold it back. This is
        /// the difference between a stifle and an elbow, and it is what makes a
        /// quadruped's two ends read differently.
        public let foldsForward: Bool
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

/// What a caller needs to move the scenery in step with the feet.
public struct SpriteGaitMetrics: Equatable, Sendable {
    /// Leg length as a fraction of the sprite's longer side, which is the side a
    /// square fit box constrains. Multiplying by that box's size gives the leg
    /// length in points.
    public let legHeightFraction: Double

    /// Ground speed in fit-box sizes per second, so a caller drawing the sprite
    /// in a box of side `n` scrolls at `groundSpeed * n` points per second.
    public func groundSpeed(for gait: SpriteGait) -> Double {
        gait.groundSpeedInLegLengths * legHeightFraction
    }
}

public enum SpriteGaitRenderer {
    private static let alphaThreshold: UInt8 = 8

    /// Renders one full gait cycle. Returns `nil` when no legs can be found.
    public static func frames(
        from image: CGImage,
        gait: SpriteGait,
        pose: SpritePose = .standing,
        frameCount: Int = 8
    ) -> (frames: [CGImage], metrics: SpriteGaitMetrics)? {
        guard let bitmap = Bitmap(image) else { return nil }
        let body = mainComponent(bitmap)
        guard let analysis = analyze(bitmap, body: body, gait: gait, pose: pose) else { return nil }
        let rig = Rig(analysis: analysis, bitmap: bitmap, body: body)
        let frames = (0..<frameCount).compactMap { frame in
            rig.render(gait: gait, phase: Double(frame) / Double(frameCount))
        }
        guard frames.count == frameCount else { return nil }
        let metrics = SpriteGaitMetrics(
            legHeightFraction: Double(analysis.legHeight) / Double(max(image.width, image.height))
        )
        return (frames, metrics)
    }

    public static func analyze(_ image: CGImage, gait: SpriteGait, pose: SpritePose = .standing) -> SpriteGaitAnalysis? {
        guard let bitmap = Bitmap(image) else { return nil }
        return analyze(bitmap, body: mainComponent(bitmap), gait: gait, pose: pose)
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

    private static func analyze(
        _ bitmap: Bitmap,
        body: [Bool],
        gait: SpriteGait,
        pose: SpritePose
    ) -> SpriteGaitAnalysis? {
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
        let bodyHeight = groundY - top

        // Legs, near or far, end within the pose's reach of the ground; the belly
        // between them hangs well clear of it, and a tail hangs somewhere between.
        // The hip line is the belly's underside, and the legs are whatever lies
        // below it between the outermost low columns. A tail or a chest tuft
        // outside that span is body, however low it hangs. A chubby sprite with
        // no clear belly gets a short leg.
        //
        // The hip line is where the leg leaves the body, however short that makes
        // the leg. Pushing it up into the body to get a longer leg turns belly into
        // leg, and a swinging leg then carries a slab of belly with it and leaves a
        // rectangular hole behind. A stubby animal takes stubby steps instead.
        let nearGround = groundY - max(2, Int(Double(bodyHeight) * pose.footClearance))
        let clearance = groundY - Int(Double(bodyHeight) * 0.12)
        let lowColumns = (0..<width).filter { bottom[$0] >= nearGround }
        guard let firstLow = lowColumns.first, let lastLow = lowColumns.last else { return nil }
        let bellyBottoms = (firstLow...lastLow).map { bottom[$0] }.filter { $0 >= 0 && $0 < clearance }.sorted()
        var hipY = bellyBottoms.count >= 2
            ? bellyBottoms[bellyBottoms.count / 2]
            : groundY - Int(Double(bodyHeight) * 0.12)
        hipY = min(hipY, groundY - Int(Double(bodyHeight) * 0.06))
        hipY = max(hipY, groundY - Int(Double(bodyHeight) * 0.5))
        let legHeight = groundY - hipY
        guard legHeight >= 6 else { return nil }

        let margin = Int(Double(legHeight) * 0.25)
        let legSpan = max(0, firstLow - margin)...min(width - 1, lastLow + margin)

        // The belly dips a little past the hip line between the pairs. Posing that
        // with a leg would drag the outline across the gap, so a column counts as
        // leg only when it carries material well down the shin.
        let shinY = hipY + Int(Double(legHeight) * 0.38)
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
        if best.count == 1, best[0].count >= 6 { best = halving(best[0]) }

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

        var detected: [(run: ClosedRange<Int>, phase: Double, hind: Bool, standIn: Bool)] = []
        for (groupIndex, group) in groups.enumerated() where !group.isEmpty {
            let phases = [gait.phases[groupIndex * 2], gait.phases[groupIndex * 2 + 1]]
            let isHind = groupIndex == 0
            // A mass wide enough to hold both legs of the pair is halved. A narrow
            // one is a single drawn leg, so the far leg becomes a stand-in.
            var runs = Array(group.prefix(2))
            if runs.count == 1, runs[0].count >= max(6, Int(Double(legHeight) * 0.55)) {
                runs = halving(runs[0])
            }
            for (offset, run) in runs.enumerated() {
                detected.append((run, phases[offset], isHind, false))
            }
            if runs.count == 1 { detected.append((runs[0], phases[1], isHind, true)) }
        }
        let drawn = detected.filter { !$0.standIn }
        guard !drawn.isEmpty else { return nil }

        // Every column under the belly must belong to exactly one leg. A leg's
        // detected run is only its narrowest point, so ownership grows to the
        // midpoint between neighbours. A column left out would be dropped by the
        // body and drawn by no leg, which is how a notch gets cut out of a thigh;
        // a column claimed twice would be posed twice and leave a stray shard.
        func ownership(of index: Int) -> ClosedRange<Int> {
            let run = drawn[index].run
            let lower = index == 0
                ? legSpan.lowerBound
                : (drawn[index - 1].run.upperBound + run.lowerBound) / 2 + 1
            let upper = index == drawn.count - 1
                ? legSpan.upperBound
                : (run.upperBound + drawn[index + 1].run.lowerBound) / 2
            let start = max(legSpan.lowerBound, min(lower, run.lowerBound))
            let end = min(legSpan.upperBound, max(upper, run.upperBound))
            return start...end
        }

        /// Where this leg's foot is drawn: the lowest material it owns, averaged
        /// across the bottom rows so a splayed running pose keeps its reach.
        func restFoot(columns: ClosedRange<Int>) -> (x: Int, y: Int) {
            var lowest = hipY
            for x in columns where isLegColumn[x] {
                for y in stride(from: groundY, through: hipY + 1, by: -1) where body[y * width + x] {
                    lowest = max(lowest, y)
                    break
                }
            }
            var sum = 0, count = 0
            for x in columns where isLegColumn[x] {
                for y in max(hipY + 1, lowest - 2)...lowest where body[y * width + x] {
                    sum += x
                    count += 1
                    break
                }
            }
            let centre = count > 0 ? sum / count : (columns.lowerBound + columns.upperBound) / 2
            return (centre, max(lowest, hipY + 4))
        }

        var legs: [SpriteGaitAnalysis.Leg] = []
        var standIns: [SpriteGaitAnalysis.Leg] = []
        var drawnIndex = 0
        for entry in detected {
            if entry.standIn {
                let source = legs[legs.count - 1]
                standIns.append(
                    .init(
                        columns: source.columns,
                        pivotX: source.pivotX,
                        footX: source.footX,
                        footY: source.footY,
                        phase: entry.phase,
                        foldsForward: source.foldsForward,
                        isFar: true
                    )
                )
            } else {
                let columns = ownership(of: drawnIndex)
                let foot = restFoot(columns: columns)
                legs.append(
                    .init(
                        columns: columns,
                        pivotX: (entry.run.lowerBound + entry.run.upperBound) / 2,
                        footX: foot.x,
                        footY: foot.y,
                        phase: entry.phase,
                        foldsForward: entry.hind,
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

    // MARK: Geometry

    private struct Point {
        var x: Double
        var y: Double

        static func - (a: Point, b: Point) -> Point { Point(x: a.x - b.x, y: a.y - b.y) }
        static func + (a: Point, b: Point) -> Point { Point(x: a.x + b.x, y: a.y + b.y) }
        var length: Double { (x * x + y * y).squareRoot() }
        var angle: Double { atan2(y, x) }
    }

    /// A rigid pose: rotate about `pivot`, then translate. Only the inverse is
    /// used when drawing, so every destination pixel gets exactly one lookup and
    /// a posed limb can never tear, double-write, or leave holes.
    private struct Rigid {
        let pivot: Point
        let angle: Double
        let shift: Point

        func source(of point: Point) -> Point {
            let moved = point - shift
            let (sinA, cosA) = (sin(-angle), cos(-angle))
            let (rx, ry) = (moved.x - pivot.x, moved.y - pivot.y)
            return Point(x: pivot.x + rx * cosA - ry * sinA, y: pivot.y + rx * sinA + ry * cosA)
        }

        func destination(of point: Point) -> Point {
            let (sinA, cosA) = (sin(angle), cos(angle))
            let (rx, ry) = (point.x - pivot.x, point.y - pivot.y)
            return Point(x: pivot.x + rx * cosA - ry * sinA + shift.x, y: pivot.y + rx * sinA + ry * cosA + shift.y)
        }
    }

    // MARK: Rig

    /// The source sprite plus everything needed to pose it, computed once.
    private struct Rig {
        /// A leg's rest geometry, measured from the drawing.
        struct Bones {
            let leg: SpriteGaitAnalysis.Leg
            let hip: Point
            let foot: Point
            /// Where the stride is centred: half-way from the hip to the drawn
            /// foot. A standing sprite keeps its pose exactly, and a running
            /// sprite drawn at full stretch keeps half its splay, which is about
            /// where a trotting foot actually lands.
            let centre: Point
            /// Unit vector from hip to foot as drawn.
            let axis: Point
            let length: Double
            /// Upper and lower bone lengths, and the paw beneath them.
            let upper: Double
            let lower: Double
            let paw: Double
            let knee: Point
            let ankle: Point
            /// Distance along the axis at which the body's static cap ends.
            let capReach: Double
            /// How far above the hip line the posed thigh borrows body. A wide
            /// stub's top corners drop further when it turns, so this grows with
            /// the leg's width.
            let reach: Double
        }

        let analysis: SpriteGaitAnalysis
        let bitmap: Bitmap
        let body: [Bool]
        /// Leg pixels past the hip cap, excluded from the body so the torso never
        /// drags them along.
        let isLegPixel: [Bool]
        let bones: [Bones]

        init(analysis: SpriteGaitAnalysis, bitmap: Bitmap, body: [Bool]) {
            self.analysis = analysis
            self.bitmap = bitmap
            self.body = body
            let legHeight = Double(analysis.legHeight)

            bones = analysis.legs.map { leg in
                let hip = Point(x: Double(leg.pivotX), y: Double(analysis.hipY))
                let foot = Point(x: Double(leg.footX), y: Double(leg.footY))
                let span = foot - hip
                let length = max(4, span.length)
                let axis = Point(x: span.x / length, y: span.y / length)
                // The paw stays flat on the ground; the two bones above it carry
                // the bend. A hair of slack keeps the chain off the straight
                // configuration, where the solve has no defined bend direction,
                // and the paw is whatever the bones leave, so the drawn foot tip
                // lands exactly where the solve aims it.
                let bone = length * 0.85 / 2 * 1.02
                let paw = length - bone * 2
                return Bones(
                    leg: leg,
                    hip: hip,
                    foot: foot,
                    centre: Point(x: hip.x + span.x * 0.5, y: foot.y),
                    axis: axis,
                    length: length,
                    upper: bone,
                    lower: bone,
                    paw: paw,
                    knee: Point(x: hip.x + axis.x * bone, y: hip.y + axis.y * bone),
                    ankle: Point(x: hip.x + axis.x * bone * 2, y: hip.y + axis.y * bone * 2),
                    capReach: max(2, legHeight * 0.18),
                    reach: max(2, legHeight * 0.18, Double(leg.columns.count) * 0.25)
                )
            }

            // The cap is the top of each leg, drawn with the body and never posed,
            // so the hip joint cannot open however far the leg swings.
            var isLegPixel = [Bool](repeating: false, count: bitmap.width * bitmap.height)
            for bone in bones where !bone.leg.isFar {
                for y in (analysis.hipY + 1)...analysis.groundY {
                    for x in bone.leg.columns
                    where analysis.isLegColumn[x] && body[y * bitmap.width + x] {
                        let along = (Double(x) - bone.hip.x) * bone.axis.x
                            + (Double(y) - bone.hip.y) * bone.axis.y
                        if along > bone.capReach { isLegPixel[y * bitmap.width + x] = true }
                    }
                }
            }
            self.isLegPixel = isLegPixel
        }

        /// Whether a source point belongs to one bone of a leg, measured by how
        /// far along the leg it lies. Splitting by distance rather than by row
        /// keeps a leg drawn at an angle in one piece.
        ///
        /// Neighbouring bones share a short band at each joint. Two rigid pieces
        /// turning by different amounts open a wedge between them otherwise, and
        /// because the bones are tested in order the upper one covers the seam,
        /// which is also how a real limb overlaps at a joint.
        ///
        /// The thigh piece also reaches a little way up into the body, the way a
        /// cutout rig draws a limb with a rounded end hidden behind the torso.
        /// Those pixels stay with the body, which is drawn on top, and the posed
        /// copy only shows where a swing would otherwise open a gap under the
        /// belly, which it fills with the fur just above.
        private func belongs(_ point: Point, bone: Bones, segment: Int) -> Bool {
            let x = Int(point.x.rounded()), y = Int(point.y.rounded())
            guard x >= 0, x < bitmap.width, y >= 0, y < bitmap.height,
                  bone.leg.columns.contains(x), y > analysis.hipY - Int(bone.reach),
                  analysis.isLegColumn[x], body[y * bitmap.width + x] else { return false }
            let along = (point.x - bone.hip.x) * bone.axis.x + (point.y - bone.hip.y) * bone.axis.y
            let overlap = max(2, bone.length * 0.10)
            switch segment {
            case 0: return along < bone.upper + overlap
            case 1: return along >= bone.upper - overlap && along < bone.upper + bone.lower + overlap
            default: return along >= bone.upper + bone.lower - overlap
            }
        }

        func render(gait: SpriteGait, phase: Double) -> CGImage? {
            var output = Bitmap(width: bitmap.width, height: bitmap.height)
            let bob = bodyRise(gait: gait, phase: phase)

            // The body is topmost: a swinging leg can never cut into the torso.
            for y in 0..<bitmap.height {
                let sourceY = y + Int(bob)
                guard sourceY >= 0, sourceY < bitmap.height else { continue }
                for x in 0..<bitmap.width {
                    let from = sourceY * bitmap.width + x
                    guard bitmap.pixels[from * 4 + 3] > alphaThreshold, !isLegPixel[from] else { continue }
                    output.copy(from: bitmap, at: from, to: y * bitmap.width + x, shade: 1)
                }
            }

            // Legs fill only what the body left empty, near legs before stand-ins.
            for bone in bones.sorted(by: { !$0.leg.isFar && $1.leg.isFar }) {
                let pose = solve(bone: bone, gait: gait, phase: phase, bob: bob)
                draw(bone: bone, pose: pose, into: &output)
            }
            return output.makeImage()
        }

        /// Where the ankle must be for this leg at this moment: over the foot's
        /// point on its stride, less the paw's height. Stride and lift scale
        /// with the measured leg height, the same figure the scenery scrolls
        /// by, so a planted foot and the ground move together.
        private func ankleTarget(
            for bone: Bones,
            gait: SpriteGait,
            foot: (forward: Double, lift: Double)
        ) -> Point {
            let leg = Double(analysis.legHeight)
            return Point(
                x: bone.centre.x + gait.strideFraction * leg * foot.forward,
                y: bone.centre.y - gait.liftFraction * leg * foot.lift - bone.paw
            )
        }

        /// How far the body sits above its drawn height this frame. The planted
        /// legs decide: a foot far from its hip needs the hip lower to stay on
        /// the ground, so the body is lowest while the planted legs are splayed
        /// and highest as one passes vertical. That is the rise and fall of a
        /// real walk, and it is what keeps a planted foot on the ground instead
        /// of floating at the ends of its stride. The drop is capped so an
        /// over-long stride lifts a toe a hair rather than sinking the body.
        private func bodyRise(gait: SpriteGait, phase: Double) -> Double {
            var rise = gait.bob
            for bone in bones {
                let foot = gait.footState(at: phase + bone.leg.phase)
                guard foot.lift == 0 else { continue }
                let ankle = ankleTarget(for: bone, gait: gait, foot: foot)
                let chain = bone.upper + bone.lower
                let dx = ankle.x - bone.hip.x
                let vertical = max(0, chain * chain - dx * dx).squareRoot()
                rise = min(rise, vertical - (ankle.y - bone.hip.y))
            }
            return max(rise, -0.14 * Double(analysis.legHeight)).rounded()
        }

        /// Three rigid transforms, one per bone, from a solved foot target.
        private func solve(
            bone: Bones,
            gait: SpriteGait,
            phase: Double,
            bob: Double
        ) -> [Rigid] {
            let foot = gait.footState(at: phase + bone.leg.phase)
            let hip = Point(x: bone.hip.x, y: bone.hip.y - bob)
            let target = ankleTarget(for: bone, gait: gait, foot: foot)

            // Two-bone inverse kinematics: the foot leads and the leg follows, so
            // a planted foot stays exactly on the ground while the body rises and
            // falls over it. Swinging the leg and hoping the foot lands right is
            // what makes a synthesised walk skate.
            let span = target - hip
            let reach = min(max(span.length, abs(bone.upper - bone.lower) + 0.01), bone.upper + bone.lower - 0.01)
            let direction = span.angle
            let cosine = (bone.upper * bone.upper + reach * reach - bone.lower * bone.lower)
                / (2 * bone.upper * reach)
            let opening = acos(min(max(cosine, -1), 1))
            // Screen y grows downward, so a hind leg folding forward turns the
            // solved joint the opposite way from a front leg folding back.
            let upperAngle = direction + (bone.leg.foldsForward ? -opening : opening)
            let knee = Point(
                x: hip.x + bone.upper * cos(upperAngle),
                y: hip.y + bone.upper * sin(upperAngle)
            )
            let ankle = Point(x: hip.x + reach * cos(direction), y: hip.y + reach * sin(direction))
            // The paw lies flat while planted and trails during the swing, toes
            // back and down the way a lifted paw hangs.
            let pawAngle = Double.pi / 2 + 0.5 * foot.lift
            let paw = Point(x: ankle.x + bone.paw * cos(pawAngle), y: ankle.y + bone.paw * sin(pawAngle))

            let rest = bone.axis.angle
            return [
                Rigid(pivot: bone.hip, angle: upperAngle - rest, shift: hip - bone.hip),
                Rigid(pivot: bone.knee, angle: (ankle - knee).angle - rest, shift: knee - bone.knee),
                Rigid(pivot: bone.ankle, angle: (paw - ankle).angle - rest, shift: ankle - bone.ankle),
            ]
        }

        /// Scans only where this leg can land, and never overwrites the body or a
        /// leg already drawn in front of it.
        private func draw(bone: Bones, pose: [Rigid], into output: inout Bitmap) {
            var minX = bitmap.width, maxX = 0, minY = bitmap.height, maxY = 0
            let corners = [
                Point(x: Double(bone.leg.columns.lowerBound), y: Double(analysis.hipY)),
                Point(x: Double(bone.leg.columns.upperBound), y: Double(analysis.hipY)),
                Point(x: Double(bone.leg.columns.lowerBound), y: Double(analysis.groundY)),
                Point(x: Double(bone.leg.columns.upperBound), y: Double(analysis.groundY)),
            ]
            for transform in pose {
                for corner in corners {
                    let posed = transform.destination(of: corner)
                    minX = min(minX, Int(posed.x.rounded()) - 2)
                    maxX = max(maxX, Int(posed.x.rounded()) + 2)
                    minY = min(minY, Int(posed.y.rounded()) - 2)
                    maxY = max(maxY, Int(posed.y.rounded()) + 2)
                }
            }
            guard minX <= maxX, minY <= maxY else { return }
            let shade = bone.leg.isFar ? 0.62 : 1.0
            for y in max(0, minY)...min(bitmap.height - 1, maxY) {
                for x in max(0, minX)...min(bitmap.width - 1, maxX) {
                    let index = y * bitmap.width + x
                    guard output.pixels[index * 4 + 3] == 0 else { continue }
                    let point = Point(x: Double(x), y: Double(y))
                    for (order, transform) in pose.enumerated() {
                        let source = transform.source(of: point)
                        guard belongs(source, bone: bone, segment: order) else { continue }
                        let from = Int(source.y.rounded()) * bitmap.width + Int(source.x.rounded())
                        output.copy(from: bitmap, at: from, to: index, shade: shade)
                        break
                    }
                }
            }
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
