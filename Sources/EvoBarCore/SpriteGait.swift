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
    /// What the stride, the lift and the scenery scroll are measured by: the
    /// visible leg and about as much again. It is longer than the leg the eye
    /// sees, because the part of the leg inside the body swings too.
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
    /// How far down a leg the bend is finished; the paw below it travels whole.
    static let bendShare = 0.76

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
        func cycle(movingLegs: Bool) -> (frames: [CGImage], lost: Int) {
            var lost = 0
            let frames = (0..<frameCount).compactMap { frame -> CGImage? in
                let rendered = rig.render(
                    gait: gait, phase: Double(frame) / Double(frameCount), movingLegs: movingLegs)
                lost = max(lost, rendered.lost)
                return rendered.image
            }
            return (frames, lost)
        }

        // Every sheet is drawn differently, and on a few the legs cannot be told
        // from the belly well enough to move them: posing pulls a piece away
        // from the animal, and it has to be dropped rather than left flying
        // beside it. Rather than walk with a hole in it, such a sheet keeps its
        // legs still and walks on its body alone, which is how a single drawing
        // has always been animated when it cannot be taken apart.
        var rendered = cycle(movingLegs: true)
        let drawn = opaqueCount(bitmap)
        if drawn > 0, rendered.lost * 40 > drawn {
            rendered = cycle(movingLegs: false)
        }
        let frames = rendered.frames
        guard frames.count == frameCount else { return nil }
        let metrics = SpriteGaitMetrics(
            legHeightFraction: Double(analysis.strideLength) / Double(max(image.width, image.height))
        )
        return (frames, metrics)
    }

    private static func opaqueCount(_ bitmap: Bitmap?) -> Int {
        guard let bitmap else { return 0 }
        return stride(from: 3, to: bitmap.pixels.count, by: 4).count { bitmap.pixels[$0] > alphaThreshold }
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
                // A cast shadow is dark. Some sheets wreathe the feet in a pale
                // mist or a cloud, just as wide and just as translucent, and
                // that is part of the animal's look, not something to drop.
                var light = 0.0
                var alpha = 0.0
                for index in component {
                    let at = index * 4
                    light += 0.3 * Double(bitmap.pixels[at]) + 0.59 * Double(bitmap.pixels[at + 1])
                        + 0.11 * Double(bitmap.pixels[at + 2])
                    alpha += Double(bitmap.pixels[at + 3])
                }
                let luminance = alpha > 0 ? light / alpha : 0
                if maxX - minX + 1 >= span / 4, luminance < 0.6 {
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

    // MARK: Rig

    /// The source sprite plus everything needed to pose it, computed once.
    ///
    /// The legs are rubber hoses, the way hand-drawn cartoons have always moved
    /// a limb that has no drawn joints. Each row of a leg slides horizontally
    /// and vertically by the foot's displacement times how far down the leg that
    /// row lies: nothing at the hip line, all of it at the paw. The leg bends
    /// smoothly instead of breaking at a knee, it stays joined to the body
    /// because its top row never moves, and it cannot tear, widen or throw off a
    /// shard, because every row is only moved.
    ///
    /// This replaced a two-bone inverse-kinematic rig that rotated a thigh, a
    /// shin and a paw as separate pieces and sheared the haunch to follow them.
    /// On a flat single-frame illustration, where the legs overlap each other
    /// and merge into the belly, those pieces cut against one another: paws
    /// broke off ahead of the body, slivers stretched into whips, and the torso
    /// read as jelly. A drawing with no skeleton cannot be posed as though it
    /// had one.
    private struct Rig {
        let analysis: SpriteGaitAnalysis
        let bitmap: Bitmap
        /// The animal itself: one run of opaque pixels. Anything opaque outside
        /// it is something the artist drew loose, a sparkle or a floating leaf.
        let body: [Bool]
        /// The painted ground shadow, drawn by neither the body nor the legs.
        let shadow: [Bool]
        /// Which drawn leg each pixel below the hip line belongs to, or -1 for
        /// body. Neighbouring legs part at the background between them on each
        /// row, so a paw never carries the edge of the leg beside it.
        let owner: [Int8]
        /// Near legs in drawing order, then the far legs, which are shaded and
        /// drawn behind them.
        let order: [Int]
        /// The topmost row each leg owns. A leg drawn reaching forward joins the
        /// body at its upper corner, well below the belly line, and that row is
        /// where its bend has to start: move it and the leg lets go of the body.
        let legTop: [Int]
        /// The row the feet stand on: the lowest foot the artist drew. It is not
        /// always the lowest row of the drawing, which may be a mist or a cloud
        /// wreathed around the paws and hanging below them.
        let floorY: Int

        init(analysis: SpriteGaitAnalysis, bitmap: Bitmap, body: [Bool], shadow: [Bool]) {
            self.analysis = analysis
            self.bitmap = bitmap
            self.body = body
            self.shadow = shadow
            let width = bitmap.width
            let drawn = analysis.legs.indices.filter { !analysis.legs[$0].isFar }

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

            // Ownership below the hip line. A leg's detected run is only its
            // narrowest point, so between two legs the boundary on each row is
            // the middle of the widest gap of background between their pivots,
            // and where they touch it is the middle of the columns they own.
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

            // A far leg is drawn behind every near leg, and a near leg that
            // stands further out is drawn in front of the one beside it, so a
            // pair reads as one leg passing the other.
            legTop = analysis.legs.indices.map { index in
                let source = Int8(analysis.legs[index].isFar
                    ? (drawn.first { analysis.legs[$0].columns == analysis.legs[index].columns } ?? index)
                    : index)
                for y in (analysis.hipY + 1)...analysis.groundY
                where analysis.legSpan.contains(where: { owner[y * width + $0] == source }) {
                    return y
                }
                return analysis.hipY + 1
            }

            floorY = analysis.legs.filter { !$0.isFar }.map(\.footY).max() ?? analysis.groundY

            order = analysis.legs.indices.sorted { a, b in
                let (first, second) = (analysis.legs[a], analysis.legs[b])
                if first.isFar != second.isFar { return second.isFar }
                return a < b
            }
        }

        func render(gait: SpriteGait, phase: Double, movingLegs: Bool) -> (image: CGImage?, lost: Int) {
            var output = Bitmap(width: bitmap.width, height: bitmap.height)
            let rise = Int(bodyRise(gait: gait, phase: phase))

            // The body is topmost and rigid: it only rises and falls, so a
            // swinging leg can never cut into it and the torso never bends.
            for y in 0..<bitmap.height {
                let sourceY = y + rise
                guard sourceY >= 0, sourceY < bitmap.height else { continue }
                for x in 0..<bitmap.width {
                    let from = sourceY * bitmap.width + x
                    guard bitmap.pixels[from * 4 + 3] > alphaThreshold, owner[from] < 0, !shadow[from] else { continue }
                    output.copy(from: bitmap, at: from, to: y * bitmap.width + x, shade: 1)
                }
            }

            for index in order {
                draw(leg: index, gait: gait, phase: phase, rise: rise, movingLegs: movingLegs, into: &output)
            }
            let lost = dropLoosePieces(from: &output, rise: rise)
            return (output.makeImage(), lost)
        }

        /// Clears anything in the finished frame that has come away from the
        /// animal. A sprite drawn with a sparkle, a floating leaf or a tail tip
        /// clear of the rump keeps those, because they were loose in the drawing
        /// too and have not moved; a paw that has slid out from under its leg,
        /// or a sliver stretched off the edge of the canvas, has not. Posing can
        /// therefore never leave a piece flying beside the animal, whatever a
        /// particular sheet does that the leg-finding did not expect.
        ///
        /// Only the legs move, so only the rows they reach can come apart. The
        /// torso above them is one piece by construction and is the seed: what
        /// the fill cannot reach from there, through pixels that touch, is loose.
        @discardableResult
        private func dropLoosePieces(from output: inout Bitmap, rise: Int) -> Int {
            let width = bitmap.width, height = bitmap.height
            let top = max(0, analysis.hipY - 1)
            guard top < height else { return 0 }
            var reached = [Bool](repeating: false, count: width * height)
            var stack: [Int] = []
            for x in 0..<width where output.pixels[(top * width + x) * 4 + 3] > alphaThreshold {
                reached[top * width + x] = true
                stack.append(top * width + x)
            }
            while let index = stack.popLast() {
                let (x, y) = (index % width, index / width)
                for dy in -1...1 {
                    let ny = y + dy
                    guard ny >= top, ny < height else { continue }
                    for dx in -1...1 where dx != 0 || dy != 0 {
                        let nx = x + dx
                        guard nx >= 0, nx < width else { continue }
                        let neighbour = ny * width + nx
                        guard !reached[neighbour],
                              output.pixels[neighbour * 4 + 3] > alphaThreshold else { continue }
                        reached[neighbour] = true
                        stack.append(neighbour)
                    }
                }
            }
            var cleared = 0
            for y in top..<height {
                for x in 0..<width {
                    let index = y * width + x
                    guard output.pixels[index * 4 + 3] > alphaThreshold, !reached[index] else { continue }
                    // Something the artist drew loose here, and that has not
                    // moved, is left alone; anything else is cleared.
                    let sourceY = y + rise
                    if sourceY >= 0, sourceY < height, !body[sourceY * width + x],
                       bitmap.pixels[(sourceY * width + x) * 4 + 3] > alphaThreshold {
                        continue
                    }
                    for channel in 0..<4 { output.pixels[index * 4 + channel] = 0 }
                    cleared += 1
                }
            }
            return cleared
        }

        /// Where this leg's paw sits, relative to where it was drawn. Forward
        /// is the stride; down is the settle that brings a paw the artist drew
        /// clear of the ground onto the same floor as the others; up is the
        /// swing clearing that floor again.
        private func offset(of index: Int, gait: SpriteGait, phase: Double) -> (dx: Double, dy: Double) {
            let leg = Double(analysis.strideLength)
            let foot = gait.footState(at: phase + analysis.legs[index].phase)
            // Only enough to close the gap under a paw the artist drew a hair
            // clear of the floor. A larger one would mean the foot was read in
            // the wrong place, and pushing the leg that far down would pull it
            // away from the belly.
            let reach = Double(max(2, analysis.legHeight / 8))
            let settle = min(reach, Double(floorY - analysis.legs[index].footY))
            return (gait.strideFraction * leg * foot.forward, settle - gait.liftFraction * leg * foot.lift)
        }

        /// How far the body sits from its drawn height this frame, twice a
        /// cycle: the rise and fall of a real walk, lowest at each touchdown
        /// when the legs are splayed under it and back up as a leg passes
        /// vertical. It only ever dips, never lifts, so the ground the artist
        /// drew the animal standing on stays the lowest it ever reaches.
        private func bodyRise(gait: SpriteGait, phase: Double) -> Double {
            -(0.014 * Double(analysis.bodyHeight) * (1 + cos(4 * .pi * phase)) / 2).rounded()
        }

        /// Draws one leg. Every row of it moves by the paw's displacement times
        /// how far down the leg the row lies, so the top row stays welded to the
        /// body and the paw travels the full stride. Sampling the source through
        /// that mapping, one row at a time, means the leg can bend but never
        /// tear, widen, or leave a piece behind.
        private func draw(leg index: Int, gait: SpriteGait, phase: Double, rise: Int, movingLegs: Bool, into output: inout Bitmap) {
            let width = bitmap.width
            let (dx, dy) = movingLegs ? offset(of: index, gait: gait, phase: phase) : (0, 0)
            let source = Int8(analysis.legs[index].isFar
                ? (analysis.legs.indices.first { !analysis.legs[$0].isFar && analysis.legs[$0].columns == analysis.legs[index].columns } ?? index)
                : index)
            let shade = analysis.legs[index].isFar ? 0.62 : 1.0
            // The bend runs from the leg's own topmost row down to its own drawn
            // foot, so the row that holds on to the body never moves and the paw
            // takes the whole displacement. A running pose can draw a leg
            // reaching almost straight forward, its foot barely below the top of
            // it, so the bend always keeps a few rows to happen in.
            let top = legTop[index]
            let span = max(3, Double(analysis.legs[index].footY - top))

            // Settling a paw onto the ground stretches the leg, and a stretched
            // leg drawn row by row skips destination rows, which combs it into
            // stripes. Each row therefore covers every row from just below the
            // one above it down to its own, so the leg stays solid however far
            // it stretches; where it squeezes instead, the upper row wins.
            var previous = Int.min
            for sourceY in (analysis.hipY + 1)...analysis.groundY {
                // How far down the leg this row lies, eased so the bend gathers
                // toward the foot the way a real leg's does, and finished before
                // the paw: a paw is a wide flat blob, and shifting its rows by
                // different amounts combs it into stripes, so the last quarter
                // of the leg travels as one block.
                let depth = min(1, max(0, Double(sourceY - top) / (span * SpriteGaitRenderer.bendShare)))
                let ramp = depth * depth
                // The bob is absorbed by the leg: the top follows the body up
                // and down, the paw stays on the ground unless it is swinging.
                let y = sourceY - Int((Double(rise) * (1 - ramp)).rounded()) + Int((dy * ramp).rounded())
                let first = previous == Int.min ? y : min(y, previous + 1)
                previous = max(previous, y)
                let top = max(0, first), bottom = min(bitmap.height - 1, y)
                guard top <= bottom else { continue }
                let shift = Int((dx * ramp).rounded())
                for destinationY in top...bottom {
                    for sourceX in analysis.legSpan where owner[sourceY * width + sourceX] == source {
                        let x = sourceX + shift
                        guard x >= 0, x < width else { continue }
                        let to = destinationY * width + x
                        guard output.pixels[to * 4 + 3] == 0 else { continue }
                        output.copy(from: bitmap, at: sourceY * width + sourceX, to: to, shade: shade)
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
