#!/usr/bin/env swift
import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

// Mechanical packaging only. Every exported frame comes from a separately
// authored body in the source atlas. No recolouring, rigging, interpolation
// between poses, per-frame scaling, or synthetic in-between frames is allowed.
// Run from the repository root. Rows are consecutive phases; columns are stages.
let arguments = Array(CommandLine.arguments.dropFirst())
let flags = Array(arguments.prefix { $0.hasPrefix("--") })
precondition(flags.allSatisfy { ["--export", "--shiny", "--single-stage"].contains($0) }, "Unknown motion atlas flag")
// Pilot atlas: one stage, four phases ordered left to right. Same validation
// and alpha-preserving packaging as a full line; never invent in-between art.
let singleStage = flags.contains("--single-stage")
let shouldExport = flags.contains("--export")
let shiny = flags.contains("--shiny")
let paths = Array(arguments.dropFirst(flags.count))
precondition(!paths.isEmpty, "usage: prepare-motion-atlas.swift [--export] [--shiny] ATLAS.png ...")
let expectedColumns = ["Cat": 7, "Dog": 7, "Fox": 7, "Capybara": 7,
                       "Raptor": 8, "Mammoth": 7, "Pterosaur": 8,
                       "Dragon": 7, "Phoenix": 7, "Kirin": 7]
let fliers: Set<String> = ["Pterosaur", "Dragon", "Phoenix"]
let frameCount = 4
let maximumFrameSide = 256
let gutter = 12

func digest(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

func makeImage(_ pixels: [UInt8], width: Int, height: Int) -> CGImage {
    CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: Data(pixels) as CFData)!, decode: nil,
            shouldInterpolate: true, intent: .defaultIntent)!
}

struct Body {
    let coreBounds: [Int]
    var pixels: [Int]
}

struct PreparedStrip {
    let filename: String
    let image: CGImage
    let metadata: [String: Any]
}

for path in paths {
    let url = URL(fileURLWithPath: path)
    let name = url.deletingPathExtension().lastPathComponent
    guard let lineColumns = expectedColumns[name] else { fatalError("Unknown motion atlas: \(name)") }
    let columns = singleStage ? 1 : lineColumns
    let sourceData = try Data(contentsOf: url)
    guard let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
          let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Unreadable atlas: \(path)")
    }
    precondition([CGImageAlphaInfo.premultipliedFirst, .premultipliedLast, .first, .last]
        .contains(sourceImage.alphaInfo), "A real alpha channel is required; painted checkerboards are not accepted")
    let width = sourceImage.width, height = sourceImage.height
    precondition(width >= columns * 64 && height >= frameCount * 64,
                 "Motion atlas is too small for independently authored forms")
    precondition(width <= 8192 && height <= 8192 && width * height <= 16_777_216,
                 "Atlas exceeds bounded import size")
    var rgba = [UInt8](repeating: 0, count: width * height * 4)
    rgba.withUnsafeMutableBytes { bytes in
        let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    let alphaSum = stride(from: 3, to: rgba.count, by: 4).reduce(Int64(0)) { $0 + Int64(rgba[$1]) }
    let visiblePixels = stride(from: 3, to: rgba.count, by: 4).filter { rgba[$0] > 0 }.count
    precondition(visiblePixels < width * height * 9 / 10, "Opaque or near-opaque atlas background")
    var sourceBorderNontransparent = 0, sourceBorderMaxAlpha = 0
    for y in 0..<height {
        for x in 0..<width where x < 2 || y < 2 || x >= width - 2 || y >= height - 2 {
            let alpha = Int(rgba[(y * width + x) * 4 + 3])
            if alpha > 0 { sourceBorderNontransparent += 1 }
            sourceBorderMaxAlpha = max(sourceBorderMaxAlpha, alpha)
        }
    }
    // Inspected Phoenix/Raptor sources have only alpha1–2 encoding haze at the
    // edge, far outside their animal silhouettes. Do not mistake that haze for
    // clipped bodies or erase it: the mask assignment below preserves every
    // nonzero source pixel. Runtime frame gutters remain fully transparent.
    precondition(sourceBorderMaxAlpha <= 2,
                 "Substantive source alpha touches the atlas edge (max=\(sourceBorderMaxAlpha)); redraw without clipping")
    print("SOURCE", path, "sha256=\(digest(sourceData))", "size=\(width)x\(height)",
          "alphaSum=\(alphaSum)", "nontransparent=\(visiblePixels)",
          "borderNontransparent=\(sourceBorderNontransparent)", "borderMaxAlpha=\(sourceBorderMaxAlpha)",
          "before any resize")

    // Label substantial opaque bodies. Touching bodies become a single
    // component and therefore fail the exact region-count check.
    var visited = [Bool](repeating: false, count: width * height)
    var labels = [Int](repeating: -1, count: width * height)
    var bodies: [Body] = []
    let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    for seed in 0..<(width * height) where !visited[seed] && rgba[seed * 4 + 3] > 32 {
        var queue = [seed], cursor = 0
        var minX = width, minY = height, maxX = 0, maxY = 0
        visited[seed] = true
        while cursor < queue.count {
            let pixel = queue[cursor]; cursor += 1
            let x = pixel % width, y = pixel / width
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
            for (dx, dy) in neighbors {
                let nx = x + dx, ny = y + dy
                guard nx >= 0 && nx < width && ny >= 0 && ny < height else { continue }
                let next = ny * width + nx
                if !visited[next] && rgba[next * 4 + 3] > 32 {
                    visited[next] = true; queue.append(next)
                }
            }
        }
        if queue.count > 700 {
            for pixel in queue { labels[pixel] = bodies.count }
            bodies.append(Body(coreBounds: [minX, minY, maxX, maxY], pixels: queue))
        }
    }
    precondition(bodies.count == columns * frameCount,
                 "Expected \(columns * frameCount) separate bodies, found \(bodies.count); missing/touching/fragmented forms must be redrawn")

    // A row is established from body centres, not wingtip/foot baselines, since
    // authored wing cycles deliberately change their outer silhouette.
    let verticalOrder = bodies.indices.sorted {
        let a = bodies[$0].coreBounds, b = bodies[$1].coreBounds
        return a[1] + a[3] < b[1] + b[3]
    }
    var ordered: [Int] = []
    var previousRowMaxCenter = -1
    var sourceOverlappingColumnPairs: [[String: Any]] = []
    if singleStage {
        ordered = bodies.indices.sorted { bodies[$0].coreBounds[0] < bodies[$1].coreBounds[0] }
        for index in 1..<ordered.count {
            precondition(bodies[ordered[index - 1]].coreBounds[2] < bodies[ordered[index]].coreBounds[0],
                         "Single-stage phases must be separated horizontally")
        }
    }
    for row in 0..<(singleStage ? 0 : frameCount) {
        let group = Array(verticalOrder[(row * columns)..<((row + 1) * columns)]).sorted {
            bodies[$0].coreBounds[0] + bodies[$0].coreBounds[2]
                < bodies[$1].coreBounds[0] + bodies[$1].coreBounds[2]
        }
        let centers = group.map { (bodies[$0].coreBounds[1] + bodies[$0].coreBounds[3]) / 2 }
        precondition(centers.max()! - centers.min()! < height / 8, "Inconsistent motion-phase row \(row + 1)")
        precondition(centers.min()! - previousRowMaxCenter > height / 16,
                     "Motion rows cannot be separated reliably")
        previousRowMaxCenter = centers.max()!
        for column in 1..<columns {
            let left = bodies[group[column - 1]].coreBounds, right = bodies[group[column]].coreBounds
            let centerDistance = (right[0] + right[2] - left[0] - left[2]) / 2
            // Independently labelled silhouettes may overlap in X without
            // touching: an elevated tail can extend above the next beak. The
            // exact connected-body count already rejects merged animals. Keep
            // stage positions unambiguous instead of rejecting their X boxes.
            precondition(centerDistance >= width / columns / 3,
                         "Stage centers in row \(row + 1) are too close to order reliably")
            if left[2] >= right[0] {
                sourceOverlappingColumnPairs.append(["row": row + 1, "stages": [column, column + 1],
                    "leftBounds": left, "rightBounds": right, "centerDistance": centerDistance])
            }
        }
        ordered.append(contentsOf: group)
    }
    for column in 0..<columns {
        let centres = (0..<frameCount).map { phase -> Int in
            let bounds = bodies[ordered[phase * columns + column]].coreBounds
            return (bounds[0] + bounds[2]) / 2
        }
        precondition(centres.max()! - centres.min()! < width / columns,
                     "Stage \(column + 1) changes column between phases")
    }

    // Expand all masks through antialiased edges simultaneously. This assigns
    // faint bridges by distance and preserves, rather than deletes, source alpha.
    var frontier = bodies.flatMap(\.pixels), cursor = 0
    while cursor < frontier.count {
        let pixel = frontier[cursor]; cursor += 1
        let owner = labels[pixel], x = pixel % width, y = pixel / width
        for (dx, dy) in neighbors {
            let nx = x + dx, ny = y + dy
            guard nx >= 0 && nx < width && ny >= 0 && ny < height else { continue }
            let next = ny * width + nx
            if labels[next] == -1 && rgba[next * 4 + 3] > 0 {
                labels[next] = owner; bodies[owner].pixels.append(next); frontier.append(next)
            }
        }
    }
    // Preserve detached small details with their nearest body; no detail may be
    // shared or duplicated across stages/phases.
    var extraVisited = [Bool](repeating: false, count: width * height)
    var distantHazeFragments = 0, distantHazePixels = 0, distantHazeMaxAlpha = 0
    var distantHazeMaximumDistance = 0.0
    for seed in 0..<(width * height) where labels[seed] == -1 && !extraVisited[seed] && rgba[seed * 4 + 3] > 0 {
        var queue = [seed], cursor = 0, xSum = 0, ySum = 0
        extraVisited[seed] = true
        while cursor < queue.count {
            let pixel = queue[cursor]; cursor += 1
            let x = pixel % width, y = pixel / width
            xSum += x; ySum += y
            for (dx, dy) in neighbors {
                let nx = x + dx, ny = y + dy
                guard nx >= 0 && nx < width && ny >= 0 && ny < height else { continue }
                let next = ny * width + nx
                if labels[next] == -1 && !extraVisited[next] && rgba[next * 4 + 3] > 0 {
                    extraVisited[next] = true; queue.append(next)
                }
            }
        }
        let cx = xSum / queue.count, cy = ySum / queue.count
        func distance(_ id: Int) -> Int {
            let bounds = bodies[id].coreBounds
            let dx = max(0, max(bounds[0] - cx, cx - bounds[2]))
            let dy = max(0, max(bounds[1] - cy, cy - bounds[3]))
            return dx * dx + dy * dy
        }
        let owner = bodies.indices.min { distance($0) == distance($1) ? $0 < $1 : distance($0) < distance($1) }!
        let maximumDistance = max(width / columns, height / frameCount) / 2
        if distance(owner) >= maximumDistance * maximumDistance {
            let maxAlpha = queue.map { Int(rgba[$0 * 4 + 3]) }.max()!
            // Repaired Pterosaur has seven isolated alpha1 fragments (eight
            // pixels total) well outside its bodies. Preserve this encoding
            // haze with the nearest body, but still reject substantive remote
            // details rather than silently stealing them from another form.
            precondition(maxAlpha <= 2,
                         "Detached detail too far from any body: pixels=\(queue.count), maxAlpha=\(maxAlpha), center=\(cx),\(cy), distance=\(sqrt(Double(distance(owner))))")
            distantHazeFragments += 1; distantHazePixels += queue.count
            distantHazeMaxAlpha = max(distantHazeMaxAlpha, maxAlpha)
            distantHazeMaximumDistance = max(distantHazeMaximumDistance, sqrt(Double(distance(owner))))
        }
        for pixel in queue { labels[pixel] = owner }
        bodies[owner].pixels.append(contentsOf: queue)
    }
    let assignedAlpha = bodies.reduce(Int64(0)) { partial, body in
        partial + body.pixels.reduce(Int64(0)) { $0 + Int64(rgba[$1 * 4 + 3]) }
    }
    precondition(assignedAlpha == alphaSum, "Source alpha lost or duplicated during extraction")
    print("EXTRACTION", "overlappingXBounds=\(sourceOverlappingColumnPairs.count)",
          "distantHazeFragments=\(distantHazeFragments)", "distantHazePixels=\(distantHazePixels)",
          "distantHazeMaxAlpha=\(distantHazeMaxAlpha)", "sourceAlpha=extractedAlpha=\(assignedAlpha)")

    // Optional hand-reviewed anatomical anchors are source pixel coordinates,
    // one [x,y] per phase per stage: {"anchors": [[[x,y], ...4], ...stages]}.
    // They only affect transparent placement, never the authored body pixels.
    let anchorURL = url.deletingPathExtension().appendingPathExtension("anchors.json")
    var authoredAnchors: [[[Int]]]? = nil
    if FileManager.default.fileExists(atPath: anchorURL.path) {
        let payload = try JSONSerialization.jsonObject(with: Data(contentsOf: anchorURL)) as? [String: Any]
        authoredAnchors = payload?["anchors"] as? [[[Int]]]
        precondition(authoredAnchors?.count == columns && authoredAnchors!.allSatisfy {
            $0.count == frameCount && $0.allSatisfy { $0.count == 2 }
        }, "Invalid anatomical anchor sidecar")
    }

    var prepared: [PreparedStrip] = []
    for column in 0..<columns {
        let phaseIDs = (0..<frameCount).map { ordered[$0 * columns + column] }
        var bounds: [[Int]] = [], anchors: [[Int]] = []
        for (phase, id) in phaseIDs.enumerated() {
            let points = bodies[id].pixels
            let box = [points.map { $0 % width }.min()!, points.map { $0 / width }.min()!,
                       points.map { $0 % width }.max()!, points.map { $0 / width }.max()!]
            bounds.append(box)
            let core = bodies[id].coreBounds
            let anchor = authoredAnchors?[column][phase]
                ?? [(core[0] + core[2]) / 2, fliers.contains(name) ? (core[1] + core[3]) / 2 : core[3]]
            precondition(anchor[0] >= box[0] && anchor[0] <= box[2] && anchor[1] >= box[1] && anchor[1] <= box[3],
                         "Anatomical anchor lies outside the body bounds")
            anchors.append(anchor)
        }
        let left = (0..<frameCount).map { anchors[$0][0] - bounds[$0][0] }.max()!
        let right = (0..<frameCount).map { bounds[$0][2] - anchors[$0][0] }.max()!
        let above = (0..<frameCount).map { anchors[$0][1] - bounds[$0][1] }.max()!
        let below = (0..<frameCount).map { bounds[$0][3] - anchors[$0][1] }.max()!
        let contentSide = max(left + right + 1, above + below + 1)
        let sourceSide = contentSide + gutter * 2
        let side = min(sourceSide, maximumFrameSide)
        // Scale the CONTENT to a common square, then provide an unscaled 12px
        // output gutter. Every phase uses the same scale and anchor transform.
        let outputContentSide = side - gutter * 2
        let scale = Double(outputContentSide) / Double(contentSide)
        let targetAnchor = [left + (contentSide - left - right - 1) / 2,
                            above + (fliers.contains(name) ? (contentSide - above - below - 1) / 2
                                : contentSide - above - below - 1)]
        var stripPixels = [UInt8](repeating: 0, count: side * frameCount * side * 4)
        var phaseMetadata: [[String: Any]] = []
        var distinctHashes = Set<String>()
        for (phase, id) in phaseIDs.enumerated() {
            var unscaled = [UInt8](repeating: 0, count: contentSide * contentSide * 4)
            for pixel in bodies[id].pixels {
                let x = pixel % width - anchors[phase][0] + targetAnchor[0]
                let y = pixel / width - anchors[phase][1] + targetAnchor[1]
                precondition(x >= 0 && x < contentSide && y >= 0 && y < contentSide, "Anchor crop would clip source pixels")
                let target = (y * contentSide + x) * 4
                for channel in 0..<4 { unscaled[target + channel] = rgba[pixel * 4 + channel] }
            }
            let frameDigest = digest(Data(unscaled))
            precondition(distinctHashes.insert(frameDigest).inserted, "Stage \(column + 1) repeats an exact motion frame")
            var output = [UInt8](repeating: 0, count: side * side * 4)
            output.withUnsafeMutableBytes { bytes in
                let context = CGContext(data: bytes.baseAddress, width: side, height: side,
                                        bitsPerComponent: 8, bytesPerRow: side * 4,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.interpolationQuality = singleStage ? .none : .high
                context.draw(makeImage(unscaled, width: contentSide, height: contentSide),
                             in: CGRect(x: gutter, y: gutter, width: outputContentSide, height: outputContentSide))
            }
            for y in 0..<side {
                for x in 0..<side {
                    let target = (y * side * frameCount + phase * side + x) * 4
                    for channel in 0..<4 { stripPixels[target + channel] = output[(y * side + x) * 4 + channel] }
                }
            }
            phaseMetadata.append(["phase": phase, "sourceBounds": bounds[phase], "sourceAnchor": anchors[phase],
                                  "unscaledSHA256": frameDigest, "sourcePixels": bodies[id].pixels.count,
                                  "sourceAlpha": bodies[id].pixels.reduce(Int64(0)) { $0 + Int64(rgba[$1 * 4 + 3]) }])
        }
        let filename = "\(name.lowercased()).\(column + 1)\(shiny ? ".shiny" : "").motion.png"
        print("STRIP", filename, "frames=4", "frameSide=\(side)", "uniformScale=\(scale)")
        prepared.append(PreparedStrip(filename: filename,
            image: makeImage(stripPixels, width: side * frameCount, height: side),
            metadata: ["file": filename, "frameCount": frameCount, "frameSide": side,
                       "unscaledContentSide": contentSide, "uniformScale": scale, "gutter": gutter,
                       "targetAnchorBeforeScale": targetAnchor,
                       "anchorPolicy": authoredAnchors != nil ? "reviewed-anatomical" : (fliers.contains(name) ? "opaque-bounds-center-review-required" : "ground-baseline"),
                       "frames": phaseMetadata]))
    }
    // All validation is complete before writing any stage from this atlas.
    if shouldExport {
        let destination = URL(fileURLWithPath: "Sources/EvoBarCore/Resources/Sprites", isDirectory: true)
        for strip in prepared {
            let temporaryURL = destination.appendingPathComponent(".\(UUID().uuidString).png")
            guard let encoder = CGImageDestinationCreateWithURL(temporaryURL as CFURL, "public.png" as CFString, 1, nil) else {
                fatalError("Could not create PNG encoder")
            }
            CGImageDestinationAddImage(encoder, strip.image, nil)
            precondition(CGImageDestinationFinalize(encoder), "Could not encode \(strip.filename)")
            let encoded = try Data(contentsOf: temporaryURL)
            try encoded.write(to: destination.appendingPathComponent(strip.filename), options: .atomic)
            try FileManager.default.removeItem(at: temporaryURL)
        }
        let report: [String: Any] = ["source": url.lastPathComponent, "sha256": digest(sourceData),
            "sourceSize": [width, height], "sourceAlpha": alphaSum, "extractedAlphaBeforeResize": assignedAlpha,
            "sourceBorderNontransparentPixels": sourceBorderNontransparent, "sourceBorderMaxAlpha": sourceBorderMaxAlpha,
            "sourceOverlappingColumnPairs": sourceOverlappingColumnPairs,
            "distantHazeFragments": distantHazeFragments, "distantHazePixels": distantHazePixels,
            "distantHazeMaxAlpha": distantHazeMaxAlpha, "distantHazeMaximumDistance": distantHazeMaximumDistance,
            "sourceNontransparentPixels": visiblePixels, "columns": singleStage ? frameCount : columns,
            "rows": singleStage ? 1 : frameCount, "singleStage": singleStage,
            "variant": shiny ? "shiny" : "normal", "strips": prepared.map(\.metadata)]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: url.deletingPathExtension().appendingPathExtension("json"), options: .atomic)
        print("Exported \(prepared.count) authored motion strips; exact source alpha conservation before uniform resize")
    }
}
