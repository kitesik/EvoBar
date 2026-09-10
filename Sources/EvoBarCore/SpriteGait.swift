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
    /// Highest opaque row of the animal itself.
    public let bodyTop: Int
    /// Rows of body above the hip line that swing with the legs. The hip line is
    /// where a leg leaves the body, but the joint it swings from sits in the
    /// haunch or the chest, a little under half way up the animal. Posing only
    /// the part below the hip line gives a paw that slides under a still haunch;
    /// swinging only a hand's breadth above it reads as a knee bending with the
    /// hip locked; swinging everything below the back turns the body to jelly.
    public let thighHeight: Int
    /// Joint to ground as the stride sees it: the visible leg and about as much
    /// again. The stride, the lift and the scenery scroll are measured by this.
    /// It is shorter than the joint height on purpose; a paw swung a full
    /// hip-to-ground leg's worth each way overshoots how far animals step.
    public let strideLength: Int
    /// Horizontal extent that holds legs. Anything outside is body or tail.
    public let legSpan: ClosedRange<Int>
    /// Columns carrying leg material rather than the belly dipping past the hip.
    public let isLegColumn: [Bool]
    /// Near legs first, then any far stand-ins.
    public let legs: [Leg]

    public var legHeight: Int { groundY - hipY }
    public var bodyHeight: Int { groundY - bodyTop }
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
        let shadow = groundShadow(bitmap)
        let body = mainComponent(bitmap, excluding: shadow)
        guard let analysis = analyze(bitmap, body: body, gait: gait, pose: pose) else { return nil }
        let rig = Rig(analysis: analysis, bitmap: bitmap, body: body, shadow: shadow)
        let frames = (0..<frameCount).compactMap { frame in
            rig.render(gait: gait, phase: Double(frame) / Double(frameCount))
        }
        guard frames.count == frameCount else { return nil }
        let metrics = SpriteGaitMetrics(
            legHeightFraction: Double(analysis.strideLength) / Double(max(image.width, image.height))
        )
        return (frames, metrics)
    }

    public static func analyze(_ image: CGImage, gait: SpriteGait, pose: SpritePose = .standing) -> SpriteGaitAnalysis? {
        guard let bitmap = Bitmap(image) else { return nil }
        return analyze(bitmap, body: mainComponent(bitmap, excluding: groundShadow(bitmap)), gait: gait, pose: pose)
    }

    /// The soft shadow some sheets paint under the paws: a translucent patch in
    /// the bottom of the drawing that spans a good part of the animal's width.
    /// A paw's anti-aliased rim is translucent too, but only a paw wide. Taken
    /// as leg, a shadow slides about under the feet as a grey slab; the scene
    /// draws its own shadow, so it is dropped from the frames entirely.
    private static func groundShadow(_ bitmap: Bitmap) -> [Bool] {
        let width = bitmap.width, height = bitmap.height
        var shadow = [Bool](repeating: false, count: width * height)
        var left = width, right = -1, ground = -1
        for index in 0..<(width * height) where bitmap.pixels[index * 4 + 3] > alphaThreshold {
            left = min(left, index % width)
            right = max(right, index % width)
            ground = max(ground, index / width)
        }
        guard right >= left, ground >= 0 else { return shadow }
        let span = right - left + 1
        let top = max(0, ground - height / 6)
        // The sheets paint their shadows at three fifths to nine tenths opacity;
        // the paws themselves are solid.
        func translucent(_ index: Int) -> Bool {
            let alpha = bitmap.pixels[index * 4 + 3]
            return alpha > alphaThreshold && alpha < 240
        }
        var seen = [Bool](repeating: false, count: width * height)
        for y in top...ground {
            for x in 0..<width where !seen[y * width + x] && translucent(y * width + x) {
                var component: [Int] = []
                var stack = [y * width + x]
                seen[y * width + x] = true
                var minX = x, maxX = x
                while let index = stack.popLast() {
                    component.append(index)
                    let (cx, cy) = (index % width, index / width)
                    minX = min(minX, cx)
                    maxX = max(maxX, cx)
                    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                        let (nx, ny) = (cx + dx, cy + dy)
                        guard nx >= 0, nx < width, ny >= top, ny <= ground else { continue }
                        let neighbour = ny * width + nx
                        guard !seen[neighbour], translucent(neighbour) else { continue }
                        seen[neighbour] = true
                        stack.append(neighbour)
                    }
                }
                if maxX - minX + 1 >= span / 4 {
                    for index in component { shadow[index] = true }
                }
            }
        }
        return shadow
    }

    // MARK: Silhouette

    /// The largest connected run of opaque pixels: the animal itself. Sparkles,
    /// glow wisps and stray fragments left by sheet extraction are excluded, so a
    /// speck below the paws cannot be mistaken for the ground.
    private static func mainComponent(_ bitmap: Bitmap, excluding shadow: [Bool]) -> [Bool] {
        let width = bitmap.width, height = bitmap.height
        var label = [Int32](repeating: 0, count: width * height)
        var best: (id: Int32, size: Int) = (0, 0)
        var next: Int32 = 0
        var stack: [Int] = []
        for start in 0..<(width * height)
        where label[start] == 0 && bitmap.pixels[start * 4 + 3] > alphaThreshold && !shadow[start] {
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
                    guard label[neighbour] == 0, bitmap.pixels[neighbour * 4 + 3] > alphaThreshold, !shadow[neighbour] else { continue }
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
        var topOf = [Int](repeating: bitmap.height, count: width)
        var top = bitmap.height
        for x in 0..<width {
            for y in stride(from: bitmap.height - 1, through: 0, by: -1) where body[y * width + x] {
                bottom[x] = max(bottom[x], y)
                break
            }
            for y in 0..<bitmap.height where body[y * width + x] {
                topOf[x] = y
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

        // The hip and the shoulder sit a little under half way up a standing
        // quadruped, so the swinging part reaches from there down to the hip
        // line, never up into the back.
        var thighHeight = Int(Double(bodyHeight) * 0.42) - legHeight
        thighHeight = min(max(3, thighHeight), max(3, hipY - top - 4))
        // The stride is measured over a shorter leg: the visible part and about
        // as much again, clamped to a third of the height, which is how far a
        // walking animal actually reaches.
        var strideThigh = Int(Double(bodyHeight) * 0.38) - legHeight
        strideThigh = max(Int(Double(legHeight) * 0.25), strideThigh)
        strideThigh = max(3, min(strideThigh, legHeight))
        let strideLength = legHeight + strideThigh

        let margin = Int(Double(legHeight) * 0.25)
        var legSpan = max(0, firstLow - margin)...min(width - 1, lastLow + margin)

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

        // A tail hanging behind the legs, or a ruff hanging in front of them,
        // can reach the ground like a leg. It hangs from the rump rather than
        // from under the torso, so above its outer columns the drawing begins
        // low, and its tip is rounded where a paw is flat. Only an outermost run
        // can be one, and only in a standing pose: a running leg kicked back
        // past the rump looks the same from here. Whatever hangs outside the
        // legs is body, and the span shrinks past it.
        if pose == .standing, best.count > 1 {
            func hangs(_ run: ClosedRange<Int>, outerIsLeft: Bool) -> Bool {
                let quarter = outerIsLeft ? run.lowerBound + run.count / 4 : run.upperBound - run.count / 4
                guard topOf[quarter] > top + Int(Double(bodyHeight) * 0.45) else { return false }
                let bottoms = run.filter { isLegColumn[$0] }.map { bottom[$0] }
                guard let lowest = bottoms.max() else { return false }
                return Double(bottoms.count { $0 >= lowest - 2 }) / Double(bottoms.count) < 0.3
            }
            var joined = best
            if hangs(joined[0], outerIsLeft: true) { joined.removeFirst() }
            if joined.count > 1, hangs(joined[joined.count - 1], outerIsLeft: false) { joined.removeLast() }
            if joined.count < best.count {
                // The run is only the tail's narrowest point; the cut moves on
                // to the first column with nothing down the shin, so the tail's
                // wider parts do not stay behind as leg.
                var lower = legSpan.lowerBound, upper = legSpan.upperBound
                for run in best where !joined.contains(run) {
                    if run.upperBound < joined[0].lowerBound {
                        var cut = run.upperBound + 1
                        while cut < joined[0].lowerBound, isLegColumn[cut] { cut += 1 }
                        lower = max(lower, cut)
                    }
                    if run.lowerBound > joined[joined.count - 1].upperBound {
                        var cut = run.lowerBound - 1
                        while cut > joined[joined.count - 1].upperBound, isLegColumn[cut] { cut -= 1 }
                        upper = min(upper, cut)
                    }
                }
                legSpan = lower...max(lower, upper)
                for x in 0..<width where !legSpan.contains(x) { isLegColumn[x] = false }
                best = joined
            }
        }
        /// Two legs drawn touching part near the ground, where the paws are
        /// narrower than the mass above them. A run with such a gap is a pair;
        /// one without is a single leg, however wide, and posing its halves as
        /// two legs tears it apart.
        func pawSplit(_ run: ClosedRange<Int>) -> [ClosedRange<Int>]? {
            var best: (gap: Int, at: Int)?
            for y in max(hipY + 1, groundY - max(2, legHeight / 5))...groundY {
                var x = run.lowerBound
                while x <= run.upperBound {
                    guard !body[y * width + x], x > run.lowerBound else { x += 1; continue }
                    let start = x
                    while x + 1 <= run.upperBound, !body[y * width + x + 1] { x += 1 }
                    let gap = x - start + 1
                    let leftMaterial = (run.lowerBound..<start).count { body[y * width + $0] }
                    let rightMaterial = ((x + 1)...max(x + 1, run.upperBound)).count { $0 <= run.upperBound && body[y * width + $0] }
                    if gap >= 3, leftMaterial >= 4, rightMaterial >= 4, gap > (best?.gap ?? 0) {
                        best = (gap, (start + x) / 2)
                    }
                    x += 1
                }
            }
            guard let best, best.at > run.lowerBound, best.at < run.upperBound else { return nil }
            return [run.lowerBound...(best.at - 1), best.at...run.upperBound]
        }
        /// Two legs drawn overlapping have no gap, but the artist outlined the
        /// near one, so a dark vertical seam runs down the inside of the mass. A
        /// column well inside the run that is much darker than the run as a
        /// whole is that seam. Stripes and spots run across a leg, not down it,
        /// so averaging each column over the shin evens them out.
        func contourSplit(_ run: ClosedRange<Int>) -> [ClosedRange<Int>]? {
            let margin = max(2, run.count / 5)
            guard run.count >= 8, run.lowerBound + margin < run.upperBound - margin else { return nil }
            let rows = (hipY + Int(Double(legHeight) * 0.5))...(hipY + Int(Double(legHeight) * 0.9))
            var lit: [Int: Double] = [:]
            for x in run {
                var sum = 0.0, alpha = 0.0
                for y in rows where body[y * width + x] {
                    let at = (y * width + x) * 4
                    sum += 0.3 * Double(bitmap.pixels[at]) + 0.59 * Double(bitmap.pixels[at + 1]) + 0.11 * Double(bitmap.pixels[at + 2])
                    alpha += Double(bitmap.pixels[at + 3])
                }
                if alpha > 0 { lit[x] = sum / alpha }
            }
            let values = lit.values.sorted()
            guard values.count >= 8 else { return nil }
            let median = values[values.count / 2]
            let interior = (run.lowerBound + margin)...(run.upperBound - margin)
            guard let seam = interior.filter({ lit[$0] != nil }).min(by: { lit[$0]! < lit[$1]! }),
                  lit[seam]! < median * 0.55 else { return nil }
            return [run.lowerBound...seam, (seam + 1)...run.upperBound]
        }
        func halving(_ run: ClosedRange<Int>) -> [ClosedRange<Int>] {
            let middle = run.lowerBound + run.count / 2
            return [run.lowerBound...(middle - 1), middle...run.upperBound]
        }
        if best.count == 1 { best = pawSplit(best[0]) ?? contourSplit(best[0]) ?? halving(best[0]) }

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
            // A mass wide enough to hold both legs of the pair is split where
            // the paws part, else at the contour, else in the middle. A narrow
            // one is a single drawn leg, so the far leg becomes a stand-in.
            var runs = Array(group.prefix(2))
            if runs.count == 1, runs[0].count >= max(6, Int(Double(legHeight) * 0.55)) {
                runs = pawSplit(runs[0]) ?? contourSplit(runs[0]) ?? halving(runs[0])
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
            bodyTop: top,
            thighHeight: thighHeight,
            strideLength: strideLength,
            legSpan: legSpan,
            isLegColumn: isLegColumn,
            legs: legs + standIns
        )
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

    // MARK: Rig

    /// The source sprite plus everything needed to pose it, computed once.
    ///
    /// Each leg is solved by inverse kinematics from a joint above the hip line
    /// (the hip inside the haunch, the shoulder inside the chest) through a knee
    /// on the hip line to the ankle. Nothing is then rotated: every piece is
    /// drawn row by row with a horizontal shift or stretch, so a source scanline
    /// always lands on one destination scanline. A rotated limb tears its pixel
    /// edges, tilts its cut against the piece above and pokes a corner out as a
    /// shard; a sheared one cannot.
    ///
    /// The haunch and the chest are bands that swing: each row shifts by the
    /// near leg's knee displacement scaled by depth below the joint, the way a
    /// thigh turning about the hip carries the haunch with it. The shift is full
    /// from the knee column outward and fades to nothing over a short run of
    /// columns toward the belly, so the belly and everything above the joints
    /// stay rigid and the two bands, which swing out of phase, never meet. The
    /// chest takes half the swing: a shoulder moves far less than a hip. The
    /// shin below blends from the band mapping at its top to a plain shift
    /// under the ankle, and the paw only travels. Every seam is therefore
    /// continuous by construction, and the far leg, whose top follows the band
    /// it hides behind while its foot follows its own stride, emerges from
    /// behind the near leg the way it should.
    private struct Rig {
        /// A leg's rest geometry, measured from the drawing.
        struct Bones {
            let leg: SpriteGaitAnalysis.Leg
            /// The joint the leg swings from, above the hip line.
            let hip: Point
            /// Where the leg leaves the body at rest: the stifle or the elbow, on the hip line.
            let knee: Point
            let foot: Point
            /// Where the stride is centred: half-way from the joint to the drawn
            /// foot, on the ground line. A standing sprite keeps its pose, a
            /// running sprite drawn at full stretch keeps half its splay, which is
            /// about where a trotting foot actually lands, and a paw the artist
            /// drew lifted comes down to stand with the others.
            let centre: Point
            /// Thigh, shin bone and the paw beneath them.
            let upper: Double
            let lower: Double
            let paw: Double
            /// Rest ankle; the paw is everything below it.
            let ankle: Point
            /// The band this leg's top follows, when its side of the belly has one.
            let band: Int?
            /// Whose pixels this leg is drawn from: itself, or the leg a stand-in copies.
            let source: Int
            /// The fuller leg of the pair, drawn shaded beneath this one when the
            /// art shows little of it.
            let ghost: Int?
        }

        /// The haunch or the chest, swinging with its near leg.
        struct Band {
            /// Column beyond which nothing moves.
            let pinX: Int
            /// The haunch band's free edge is behind the animal; the chest band's is in front.
            let rearFacing: Bool
            /// The near leg whose knee the band follows.
            let driver: Int
            let top: Int
            /// Columns from the knee toward the belly over which the shift fades out.
            let fade: Double
            /// How much of the knee's swing the band takes.
            let factor: Double
        }

        struct Pose {
            let kneeX: Double
            let ankle: Point
        }

        let analysis: SpriteGaitAnalysis
        let bitmap: Bitmap
        let body: [Bool]
        /// The painted ground shadow, drawn by neither the body nor the legs.
        let shadow: [Bool]
        /// Which drawn leg each pixel below the hip line belongs to, or -1 for
        /// body. Neighbouring legs part at the background between them on each
        /// row, so a paw never carries the edge of the leg beside it.
        let owner: [Int8]
        /// Band pixels, excluded from the body and redrawn leaning.
        let isBandPixel: [Bool]
        let bones: [Bones]
        let bands: [Band]

        init(analysis: SpriteGaitAnalysis, bitmap: Bitmap, body: [Bool], shadow: [Bool]) {
            self.analysis = analysis
            self.bitmap = bitmap
            self.body = body
            self.shadow = shadow
            let width = bitmap.width
            let thigh = Double(analysis.thighHeight)
            let drawn = analysis.legs.indices.filter { !analysis.legs[$0].isFar }

            // Ownership below the hip line. A leg's detected run is only its
            // narrowest point, so between two legs the boundary on each row is
            // the middle of the widest gap of background between their pivots,
            // and where they touch it is the middle of the columns they own.
            // Fur hanging under the belly between the legs lies below the hip
            // line too, but it is not leg: taken as leg it swings about as a
            // slab. A leg is what stands on the ground, so only pixels joined,
            // below the hip line, to the bottom quarter of the drawing count.
            var standing = [Bool](repeating: false, count: width * bitmap.height)
            var stack: [Int] = []
            let seedRow = analysis.hipY + analysis.legHeight * 3 / 4
            for y in seedRow...analysis.groundY {
                for x in analysis.legSpan where body[y * width + x] && !standing[y * width + x] {
                    standing[y * width + x] = true
                    stack.append(y * width + x)
                }
            }
            while let index = stack.popLast() {
                let (x, y) = (index % width, index / width)
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let (nx, ny) = (x + dx, y + dy)
                    guard nx >= 0, nx < width, ny > analysis.hipY, ny <= analysis.groundY else { continue }
                    let neighbour = ny * width + nx
                    guard !standing[neighbour], body[neighbour] else { continue }
                    standing[neighbour] = true
                    stack.append(neighbour)
                }
            }

            var owner = [Int8](repeating: -1, count: width * bitmap.height)
            for y in (analysis.hipY + 1)...analysis.groundY {
                var boundaries: [Int] = []
                for (left, right) in zip(drawn, drawn.dropFirst()) {
                    let a = analysis.legs[left], b = analysis.legs[right]
                    var boundary = a.columns.upperBound
                    var widest = 0
                    var x = a.pivotX
                    while x <= b.pivotX {
                        guard !body[y * width + x] else { x += 1; continue }
                        let start = x
                        while x + 1 <= b.pivotX, !body[y * width + x + 1] { x += 1 }
                        if x - start + 1 > widest {
                            widest = x - start + 1
                            boundary = (start + x) / 2
                        }
                        x += 1
                    }
                    boundaries.append(boundary)
                }
                for x in analysis.legSpan where analysis.isLegColumn[x] && standing[y * width + x] {
                    let slot = boundaries.firstIndex { x <= $0 } ?? drawn.count - 1
                    owner[y * width + x] = Int8(drawn[slot])
                }
            }
            self.owner = owner

            /// Pixels a leg owns down the shin, where the belly's fur no longer
            /// confuses the count. The art hides most of a far leg behind its
            /// near leg, so the fuller leg of a pair is the near one.
            func area(_ index: Int) -> Int {
                var count = 0
                for y in (analysis.hipY + analysis.legHeight / 2)...analysis.groundY {
                    for x in analysis.legSpan where owner[y * width + x] == Int8(index) { count += 1 }
                }
                return count
            }

            /// Mean brightness of a leg's shin and paw. Sprites shade the far leg
            /// darker; measured down the shin, the belly's fur cannot confuse it.
            func brightness(_ index: Int) -> Double {
                var sum = 0.0, alpha = 0.0
                for y in (analysis.hipY + analysis.legHeight / 2)...analysis.groundY {
                    for x in analysis.legSpan where owner[y * width + x] == Int8(index) {
                        let at = (y * width + x) * 4
                        sum += 0.3 * Double(bitmap.pixels[at]) + 0.59 * Double(bitmap.pixels[at + 1])
                            + 0.11 * Double(bitmap.pixels[at + 2])
                        alpha += Double(bitmap.pixels[at + 3])
                    }
                }
                return alpha > 0 ? sum / alpha : 0
            }

            // The near leg of each pair drives its band: the brighter one, since
            // the far leg is drawn in shadow; when they match, the fuller one;
            // when those match too, the outer one, because a side view draws the
            // near legs on the outside and lets the far legs show between.
            func driver(hind: Bool) -> Int? {
                let pair = drawn.filter { analysis.legs[$0].foldsForward == hind }
                guard pair.count == 2 else { return pair.first }
                let lit = pair.map(brightness)
                if abs(lit[0] - lit[1]) > 0.08 { return lit[0] > lit[1] ? pair[0] : pair[1] }
                let areas = pair.map(area)
                if Double(max(areas[0], areas[1])) > 1.15 * Double(min(areas[0], areas[1])) {
                    return areas[0] > areas[1] ? pair[0] : pair[1]
                }
                return pair.min { a, b in
                    hind ? analysis.legs[a].pivotX < analysis.legs[b].pivotX
                        : analysis.legs[a].pivotX > analysis.legs[b].pivotX
                }
            }
            let drivers = [driver(hind: true), driver(hind: false)]

            // What the art draws of a far leg is a sliver, and a sliver swung
            // clear of the body stretches into a whip. The fuller partner lends
            // it its shape.
            /// Whether background separates two legs down the shin. Legs drawn
            /// apart are each whole as drawn; only a leg touching its partner is
            /// the sliver the partner leaves visible.
            func apart(_ a: Int, _ b: Int) -> Bool {
                let left = min(analysis.legs[a].pivotX, analysis.legs[b].pivotX)
                let right = max(analysis.legs[a].pivotX, analysis.legs[b].pivotX)
                for y in (analysis.hipY + analysis.legHeight / 2)...(analysis.hipY + analysis.legHeight * 4 / 5) {
                    var gap = 0
                    for x in left...right {
                        gap = body[y * width + x] ? 0 : gap + 1
                        if gap >= 3 { return true }
                    }
                }
                return false
            }
            // A far leg drawn as a sliver behind its near leg, touching it and
            // well under half its size, borrows the near leg's shape. A far leg
            // the art draws whole, splayed ahead of or behind the near leg, needs
            // nothing, and a copy laid over it would show as a slab. The near leg
            // never borrows.
            func ghost(for index: Int) -> Int? {
                let near = drivers[analysis.legs[index].foldsForward ? 0 : 1]
                guard let near, near != index, !apart(index, near),
                      Double(area(index)) < 0.4 * Double(area(near)) else { return nil }
                return near
            }

            let hindPin = analysis.drawnLegs.filter(\.foldsForward).map(\.columns.upperBound).max()
            let frontPin = analysis.drawnLegs.filter { !$0.foldsForward }.map(\.columns.lowerBound).min()
            let top = analysis.hipY - analysis.thighHeight + 1
            // The knee moves by the thigh's share of the foot's swing; the fade
            // needs a little over twice that so a row never folds over itself.
            let share = thigh / (thigh + Double(analysis.legHeight))
            let swing = 0.46 * Double(analysis.strideLength) * share
            let fade = max(8, 2.2 * swing)
            var bands: [Band] = []
            var bandOfHind: Int?, bandOfFront: Int?
            if let hindPin, let driver = drivers[0] {
                bandOfHind = bands.count
                bands.append(Band(pinX: hindPin, rearFacing: true, driver: driver, top: top, fade: fade, factor: 0.85))
            }
            if let frontPin, let driver = drivers[1] {
                bandOfFront = bands.count
                bands.append(Band(pinX: frontPin, rearFacing: false, driver: driver, top: top, fade: fade, factor: 0.5))
            }
            self.bands = bands

            bones = analysis.legs.enumerated().map { index, leg in
                let knee = Point(x: Double(leg.pivotX), y: Double(analysis.hipY))
                let foot = Point(x: Double(leg.footX), y: Double(leg.footY))
                let shin = foot - knee
                let shinLength = max(4, shin.length)
                // The paw stays flat on the ground; the thigh and the shin bone
                // carry the bend. A hair of slack keeps the chain off the straight
                // configuration, where the solve has no defined bend direction,
                // and the paw is whatever the bone leaves, so the drawn foot tip
                // lands exactly where the solve aims it.
                let bone = shinLength * 0.85
                let hip = Point(x: knee.x, y: knee.y - thigh)
                return Bones(
                    leg: leg,
                    hip: hip,
                    knee: knee,
                    foot: foot,
                    centre: Point(x: hip.x + (foot.x - hip.x) * 0.5, y: Double(analysis.groundY)),
                    upper: thigh,
                    lower: bone * 1.02,
                    paw: shinLength - bone,
                    ankle: Point(x: knee.x + shin.x / shinLength * bone, y: knee.y + shin.y / shinLength * bone),
                    band: leg.foldsForward ? bandOfHind : bandOfFront,
                    source: leg.isFar
                        ? (drawn.first { analysis.legs[$0].columns == leg.columns } ?? index)
                        : index,
                    ghost: leg.isFar ? nil : ghost(for: index)
                )
            }

            // The band is every row from the joint down to the hip line, plus
            // whatever hangs below the hip line outside the legs: a tail behind
            // them or a ruff in front moves with the bottom of the band it hangs
            // from, instead of tearing off where the band leans away.
            var isBandPixel = [Bool](repeating: false, count: width * bitmap.height)
            for band in bands {
                let columns = band.rearFacing ? 0...band.pinX : band.pinX...(width - 1)
                for y in top...analysis.groundY {
                    for x in columns where body[y * width + x] && (y <= analysis.hipY || !analysis.legSpan.contains(x)) {
                        isBandPixel[y * width + x] = true
                    }
                }
            }
            self.isBandPixel = isBandPixel
        }

        func render(gait: SpriteGait, phase: Double) -> CGImage? {
            var output = Bitmap(width: bitmap.width, height: bitmap.height)
            let bob = bodyRise(gait: gait, phase: phase)
            let rise = Int(bob)
            let poses = bones.map { solve(bone: $0, gait: gait, phase: phase, bob: bob) }

            // The body is topmost: a swinging leg can never cut into the torso.
            for y in 0..<bitmap.height {
                let sourceY = y + rise
                guard sourceY >= 0, sourceY < bitmap.height else { continue }
                for x in 0..<bitmap.width {
                    let from = sourceY * bitmap.width + x
                    guard bitmap.pixels[from * 4 + 3] > alphaThreshold, owner[from] < 0, !isBandPixel[from], !shadow[from] else { continue }
                    output.copy(from: bitmap, at: from, to: y * bitmap.width + x, shade: 1)
                }
            }

            for band in bands {
                draw(band: band, shift: poses[band.driver].kneeX - bones[band.driver].knee.x, rise: rise, into: &output)
            }

            // Legs fill only what the body left empty: the fully drawn legs first,
            // then each sliver of a leg beneath a shaded copy of its partner's
            // shape moved to its own rest foot, then the far legs the art never
            // drew, which are that copy alone.
            for index in bones.indices where !bones[index].leg.isFar && bones[index].ghost == nil {
                draw(bones[index], pose: poses[index], pixels: index, offset: 0, shade: 1, poses: poses, rise: rise, into: &output)
            }
            for index in bones.indices where !bones[index].leg.isFar && bones[index].ghost != nil {
                let partner = bones[index].ghost!
                let offset = Int((bones[index].foot.x - bones[partner].foot.x).rounded())
                draw(bones[index], pose: poses[index], pixels: partner, offset: offset, shade: 0.62, poses: poses, rise: rise, into: &output)
                draw(bones[index], pose: poses[index], pixels: index, offset: 0, shade: 1, poses: poses, rise: rise, into: &output)
            }
            for index in bones.indices where bones[index].leg.isFar {
                draw(bones[index], pose: poses[index], pixels: bones[index].source, offset: 0, shade: 0.62, poses: poses, rise: rise, into: &output)
            }
            return output.makeImage()
        }

        /// Where the ankle must be for this leg at this moment: over the foot's
        /// point on its stride, less the paw's height. Stride and lift scale
        /// with the measured stride length, the same figure the scenery scrolls
        /// by, so a planted foot and the ground move together.
        private func ankleTarget(
            for bone: Bones,
            gait: SpriteGait,
            foot: (forward: Double, lift: Double)
        ) -> Point {
            let leg = Double(analysis.strideLength)
            return Point(
                x: bone.centre.x + gait.strideFraction * leg * foot.forward,
                y: bone.centre.y - gait.liftFraction * leg * foot.lift - bone.paw
            )
        }

        /// How far the body sits above its drawn height this frame. The planted
        /// legs decide: a foot far from its joint needs the joint lower to stay on
        /// the ground, so the body is lowest while the planted legs are splayed
        /// and highest as one passes vertical. That is the rise and fall of a
        /// real walk, and it is what keeps a planted foot on the ground instead
        /// of floating at the ends of its stride. The drop is capped so an
        /// over-long stride lifts a toe a hair rather than sinking the body.
        private func bodyRise(gait: SpriteGait, phase: Double) -> Double {
            // The body is lowest at each touchdown, when two legs are splayed
            // under it, and highest as a leg passes vertical: twice a cycle, by a
            // little over a hundredth of the animal's height.
            let bounce = 0.012 * Double(analysis.bodyHeight) * (1 + cos(4 * .pi * phase)) / 2
            var rise = gait.bob - bounce
            for bone in bones {
                let foot = gait.footState(at: phase + bone.leg.phase)
                guard foot.lift == 0 else { continue }
                let ankle = ankleTarget(for: bone, gait: gait, foot: foot)
                let chain = bone.upper + bone.lower
                let dx = ankle.x - bone.hip.x
                let vertical = max(0, chain * chain - dx * dx).squareRoot()
                rise = min(rise, vertical - (ankle.y - bone.hip.y))
            }
            return max(rise, -0.14 * Double(analysis.strideLength)).rounded()
        }

        /// The knee and the ankle for this leg at this moment.
        private func solve(bone: Bones, gait: SpriteGait, phase: Double, bob: Double) -> Pose {
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
            return Pose(
                kneeX: hip.x + bone.upper * cos(upperAngle),
                ankle: Point(x: hip.x + reach * cos(direction), y: hip.y + reach * sin(direction))
            )
        }

        /// How much of the row's shift a column takes: all of it from the
        /// driver's knee column outward, easing to none over the fade toward the
        /// belly, and none past the pin.
        private func weight(in band: Band, at x: Double) -> Double {
            let pivot = bones[band.driver].knee.x
            let pin = Double(band.pinX)
            let fade = min(band.fade, max(1, abs(pin - pivot)))
            let inward = band.rearFacing ? x - pivot : pivot - x
            guard inward > 0 else { return 1 }
            let u = min(1, inward / fade)
            let eased = 1 - u * u * (3 - 2 * u)
            return (band.rearFacing ? x <= pin : x >= pin) ? eased : 0
        }

        /// The band's share of the knee's swing, capped so the fade can never
        /// fold over on itself.
        private func limited(_ lean: Double, in band: Band) -> Double {
            let cap = 0.45 * min(band.fade, max(1, abs(Double(band.pinX) - bones[band.driver].knee.x)))
            return min(cap, max(-cap, lean * band.factor))
        }

        /// Where a band row shifted by `lean` puts source column `x`.
        private func destination(in band: Band, lean: Double, x: Double) -> Double {
            x + lean * weight(in: band, at: x)
        }

        /// For every destination column of a band row shifted by `lean`, the
        /// source column it draws. The forward map is monotonic, so one walk
        /// along it inverts the whole row.
        private func sources(in band: Band, lean: Double) -> [Double] {
            let width = bitmap.width
            guard lean != 0 else { return (0..<width).map(Double.init) }
            let forward = (0..<width).map { destination(in: band, lean: lean, x: Double($0)) }
            var result = [Double](repeating: 0, count: width)
            var s = 0
            for x in 0..<width {
                let target = Double(x)
                while s + 1 < width, forward[s + 1] <= target { s += 1 }
                if s + 1 < width, forward[s + 1] > forward[s] {
                    result[x] = Double(s) + (target - forward[s]) / (forward[s + 1] - forward[s])
                } else {
                    result[x] = Double(s) + (target - forward[s])
                }
            }
            return result
        }

        /// Draws one band swinging with the solved knee. Each destination row
        /// maps back onto its whole source row, so the band can neither tear nor
        /// leave a hole; its free edge simply moves. Rows below the hip line hold
        /// only what hangs outside the legs and swing as far as the hip line does.
        private func draw(band: Band, shift: Double, rise: Int, into output: inout Bitmap) {
            let width = bitmap.width
            let depth = Double(analysis.hipY - band.top + 1)
            let columns = band.rearFacing ? 0...band.pinX : band.pinX...(width - 1)
            let full = limited(shift, in: band)
            for y in 0..<bitmap.height {
                let sourceY = y + rise
                guard sourceY >= band.top, sourceY <= analysis.groundY else { continue }
                let lean = full * min(1, Double(sourceY - band.top + 1) / depth)
                let sources = sources(in: band, lean: lean)
                for x in columns {
                    let index = y * width + x
                    guard output.pixels[index * 4 + 3] == 0 else { continue }
                    let sx = Int(sources[x].rounded())
                    guard sx >= 0, sx < width, isBandPixel[sourceY * width + sx] else { continue }
                    output.copy(from: bitmap, at: sourceY * width + sx, to: index, shade: 1)
                }
            }
        }

        /// Draws one leg in `bone`'s pose from leg `source`'s pixels, moved
        /// `offset` columns: the shin blends from the band's mapping at the hip
        /// line to a plain shift under the ankle, squeezed to the solved height
        /// and widened by the slope it leans at so a steep leg stays as thick as
        /// a turned one, and the paw travels with the ankle. Never overwrites the
        /// body or a leg already drawn in front of it.
        private func draw(
            _ bone: Bones,
            pose: Pose,
            pixels source: Int,
            offset: Int,
            shade: Double,
            poses: [Pose],
            rise: Int,
            into output: inout Bitmap
        ) {
            let width = bitmap.width
            let ankleShift = pose.ankle - bone.ankle
            let ankleRow = Int(bones[source].ankle.y.rounded())
            let hipRow = analysis.hipY
            let pivot = bone.knee.x

            // The top row follows the band above it exactly; without a band it
            // follows the knee.
            let topSources: [Double]
            let topShift: Double
            if let index = bone.band {
                let band = bands[index]
                let lean = limited(poses[band.driver].kneeX - bones[band.driver].knee.x, in: band)
                topSources = sources(in: band, lean: lean)
                topShift = destination(in: band, lean: lean, x: pivot) - pivot
            } else {
                topShift = pose.kneeX - bone.knee.x
                topSources = (0..<width).map { Double($0) - topShift }
            }

            let sourceRows = ankleRow - hipRow
            let top = hipRow + 1 - rise
            let bottom = ankleRow + Int(ankleShift.y.rounded())
            if sourceRows > 0, bottom >= top {
                let destinationRows = bottom - top + 1
                let slope = (ankleShift.x - topShift) / Double(destinationRows)
                let fullWidening = min(1.6, (1 + slope * slope).squareRoot())
                for y in max(0, top)...min(bitmap.height - 1, bottom) {
                    let progress = Double(y - top) / Double(max(1, destinationRows - 1))
                    let sourceY = min(ankleRow, hipRow + 1 + (y - top) * sourceRows / destinationRows)
                    // The paw below only travels, so the widening eases off toward the ankle.
                    let widening = 1 + (fullWidening - 1) * min(1, (1 - progress) / 0.35)
                    for x in 0..<width {
                        let index = y * width + x
                        guard output.pixels[index * 4 + 3] == 0 else { continue }
                        let sheared = (1 - progress) * topSources[x] + progress * (Double(x) - ankleShift.x)
                        let sx = Int((pivot + (sheared - pivot) / widening).rounded()) - offset
                        guard sx >= 0, sx < width, owner[sourceY * width + sx] == Int8(source) else { continue }
                        output.copy(from: bitmap, at: sourceY * width + sx, to: index, shade: shade)
                    }
                }
            }

            let dx = Int(ankleShift.x.rounded()) + offset, dy = Int(ankleShift.y.rounded())
            for sourceY in (ankleRow + 1)...max(ankleRow + 1, analysis.groundY) where sourceY <= analysis.groundY {
                let y = sourceY + dy
                guard y >= 0, y < bitmap.height else { continue }
                for sx in 0..<width where owner[sourceY * width + sx] == Int8(source) {
                    let x = sx + dx
                    guard x >= 0, x < width, output.pixels[(y * width + x) * 4 + 3] == 0 else { continue }
                    output.copy(from: bitmap, at: sourceY * width + sx, to: y * width + x, shade: shade)
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
