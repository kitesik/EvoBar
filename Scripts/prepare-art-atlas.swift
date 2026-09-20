#!/usr/bin/env swift
import AppKit
import ImageIO
import CryptoKit

// Atlas slicing is mechanical packaging: preserve source colors/alpha, never
// recolor a form or manufacture one from a neighboring stage. A merged/missing
// body fails closed before export instead of silently cutting through an animal.
let arguments = Array(CommandLine.arguments.dropFirst())
let flags = Array(arguments.prefix { $0.hasPrefix("--") })
precondition(flags.allSatisfy { ["--export", "--shiny", "--single-stage"].contains($0) || $0.hasPrefix("--stage=") }, "Unknown atlas flag")
let singleStage = flags.contains("--single-stage")
let stageFlags = flags.filter { $0.hasPrefix("--stage=") }
precondition(stageFlags.count <= 1 && (stageFlags.isEmpty || singleStage), "--stage requires --single-stage and may appear once")
let targetStage = stageFlags.first.flatMap { Int($0.dropFirst(8)) } ?? (stageFlags.isEmpty ? 1 : 0)
let export = flags.contains("--export")
let shiny = flags.contains("--shiny")
let paths = Array(arguments.dropFirst(flags.count))
let expectedColumns = ["Cat": 7, "Dog": 7, "Fox": 7, "Capybara": 7,
                       "Raptor": 8, "Mammoth": 7, "Pterosaur": 8,
                       "Dragon": 7, "Phoenix": 7, "Kirin": 7]
let states = ["idle", "working", "evolutionReady", "sleeping"]
precondition(!paths.isEmpty, "usage: prepare-art-atlas.swift [--export] [--shiny] [--single-stage [--stage=N]] ATLAS.png ... (single-stage: idle, working, ready, sleeping left-to-right; stage defaults to 1)")
for path in paths {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError(path) }
    precondition([CGImageAlphaInfo.premultipliedFirst, .premultipliedLast, .first, .last].contains(image.alphaInfo),
                 "Atlas must contain a real alpha channel, not a painted checkerboard")
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w * h * 4)
    pixels.withUnsafeMutableBytes { p in
        let c = CGContext(data: p.baseAddress, width: w, height: h, bitsPerComponent: 8,
                          bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    let visible = stride(from: 3, to: pixels.count, by: 4).filter { pixels[$0] > 32 }.count
    precondition(visible < w * h * 9 / 10, "Opaque atlas background; redraw with transparency")
    var border: [Int] = []
    for x in 0..<w { border.append(x); border.append((h - 1) * w + x) }
    for y in 0..<h { border.append(y * w); border.append(y * w + w - 1) }
    precondition(border.allSatisfy { pixels[$0 * 4 + 3] <= 2 }, "Clipped atlas edge; redraw with padding")
    let name = url.deletingPathExtension().lastPathComponent
    guard let catalogColumns = expectedColumns[name] else { fatalError("Unknown atlas: \(name)") }
    precondition((1...catalogColumns).contains(targetStage), "Invalid target stage for \(name)")
    let columns = singleStage ? 1 : catalogColumns
    // A large detached ready sparkle can be bigger than the body-component
    // cutoff. Annotate its exact reviewed bounds, tied to this source hash;
    // do not loosen the body threshold or drop any of its pixels.
    let partsURL = url.deletingPathExtension().appendingPathExtension("parts.json")
    var reviewedDetails: [[Int]] = []
    if FileManager.default.fileExists(atPath: partsURL.path) {
        let parts = try JSONSerialization.jsonObject(with: Data(contentsOf: partsURL)) as? [String: Any]
        let hash = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
        precondition(parts?["sourceSHA256"] as? String == hash, "Stale detached-detail annotation")
        reviewedDetails = parts?["detachedDetailBounds"] as? [[Int]] ?? []
        precondition(reviewedDetails.allSatisfy { $0.count == 4 }, "Invalid detached-detail bounds")
    }
    var matchedDetails = Set<Int>()
    var seen = [Bool](repeating: false, count: w * h)
    var labels = [Int](repeating: -1, count: w * h)
    var components: [[Int]] = []
    var members: [[Int]] = []
    for seed in 0..<(w * h) where !seen[seed] && pixels[seed * 4 + 3] > 32 {
        var q = [seed], i = 0, loX = w, loY = h, hiX = 0, hiY = 0
        seen[seed] = true
        while i < q.count {
            let n = q[i]; i += 1
            let x = n % w, y = n / w
            loX = min(loX, x); hiX = max(hiX, x); loY = min(loY, y); hiY = max(hiY, y)
            for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1)] {
                let nx = x + dx, ny = y + dy
                if nx < 0 || nx >= w || ny < 0 || ny >= h { continue }
                let m = ny * w + nx
                if !seen[m] && pixels[m * 4 + 3] > 32 { seen[m] = true; q.append(m) }
            }
        }
        if q.count > 700 {
            if let detail = reviewedDetails.firstIndex(of: [loX, loY, hiX, hiY]) {
                precondition(matchedDetails.insert(detail).inserted, "Duplicate detached detail")
                continue // Retained below by the exact-alpha extras assignment.
            }
            for n in q { labels[n] = components.count }
            components.append([q.count, loX, loY, hiX, hiY]); members.append(q)
        }
    }
    print(url.lastPathComponent, w, h, "regions:", components.count)
    precondition(matchedDetails.count == reviewedDetails.count, "Detached-detail annotation did not match")
    guard components.count == columns * 4 else {
        fatalError("Expected \(columns * 4) separate bodies; redraw touching/missing forms before export")
    }
    let byBaseline = components.indices.sorted { components[$0][4] < components[$1][4] }
    var ordered: [Int] = []
    if singleStage {
        ordered = components.indices.sorted { components[$0][1] < components[$1][1] }
        for index in 1..<ordered.count {
            precondition(components[ordered[index - 1]][3] < components[ordered[index]][1],
                         "Overlapping state portraits; redraw before export")
        }
    } else {
        for row in 0..<4 {
            let group = Array(byBaseline[(row * columns)..<((row + 1) * columns)])
                .sorted { components[$0][1] < components[$1][1] }
            let baselines = group.map { components[$0][4] }
            precondition(baselines.max()! - baselines.min()! < h / 8, "Inconsistent atlas row")
            ordered.append(contentsOf: group)
        }
    }
    // Grow all body masks simultaneously through their antialiased edges. A
    // low-alpha bridge must be split by distance, never assigned wholesale to
    // one animal: some generated sheets connect neighboring outlines at alpha 1.
    var frontier = members.flatMap { $0 }, cursor = 0
    while cursor < frontier.count {
        let n = frontier[cursor]; cursor += 1
        let owner = labels[n], x = n % w, y = n / w
        for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1)] {
            let nx = x + dx, ny = y + dy
            if nx < 0 || nx >= w || ny < 0 || ny >= h { continue }
            let m = ny * w + nx
            if labels[m] == -1 && pixels[m * 4 + 3] > 0 {
                labels[m] = owner; members[owner].append(m); frontier.append(m)
            }
        }
    }
    // Detached details (the ready spark) go to the nearest body. Preserve every
    // nontransparent source pixel including its alpha, with no recoloring.
    var extrasSeen = [Bool](repeating: false, count: w * h)
    for seed in 0..<(w * h) where labels[seed] == -1 && !extrasSeen[seed] && pixels[seed * 4 + 3] > 0 {
        var q = [seed], i = 0, xSum = 0, ySum = 0
        extrasSeen[seed] = true
        var touches: [Int: Int] = [:]
        while i < q.count {
            let n = q[i]; i += 1
            let x = n % w, y = n / w
            xSum += x; ySum += y
            for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1)] {
                let nx = x + dx, ny = y + dy
                if nx < 0 || nx >= w || ny < 0 || ny >= h { continue }
                let m = ny * w + nx
                if labels[m] >= 0 { touches[labels[m], default: 0] += 1; continue }
                if !extrasSeen[m] && pixels[m * 4 + 3] > 0 { extrasSeen[m] = true; q.append(m) }
            }
        }
        let cx = xSum / q.count, cy = ySum / q.count
        func distance(_ id: Int) -> Int {
            let b = components[id]
            let dx = max(0, max(b[1] - cx, cx - b[3]))
            let dy = max(0, max(b[2] - cy, cy - b[4]))
            return dx * dx + dy * dy
        }
        let owner = touches.keys.sorted { touches[$0]! == touches[$1]! ? $0 < $1 : touches[$0]! > touches[$1]! }.first
            ?? components.indices.min { distance($0) == distance($1) ? $0 < $1 : distance($0) < distance($1) }!
        members[owner].append(contentsOf: q)
    }
    if export {
        let destination = URL(fileURLWithPath: "Sources/EvoBarCore/Resources/Sprites", isDirectory: true)
        var metadata: [[String: Any]] = []
        var exportedAlpha: Int64 = 0
        for (index, id) in ordered.enumerated() {
            let row = index / columns, stage = singleStage ? targetStage : index % columns + 1
            let pts = members[id]
            let minX = pts.map { $0 % w }.min()!, maxX = pts.map { $0 % w }.max()!
            let minY = pts.map { $0 / w }.min()!, maxY = pts.map { $0 / w }.max()!
            let pad = 12, sw = maxX - minX + 1 + pad * 2, sh = maxY - minY + 1 + pad * 2
            var output = [UInt8](repeating: 0, count: sw * sh * 4)
            for p in pts {
                let target = ((p / w - minY + pad) * sw + p % w - minX + pad) * 4
                for c in 0..<4 { output[target + c] = pixels[p * 4 + c] }
                exportedAlpha += Int64(pixels[p * 4 + 3])
            }
            let data = Data(output)
            let sprite = CGImage(width: sw, height: sh, bitsPerComponent: 8, bitsPerPixel: 32,
                                 bytesPerRow: sw * 4, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                 provider: CGDataProvider(data: data as CFData)!, decode: nil,
                                 shouldInterpolate: true, intent: .defaultIntent)!
            let file = "\(name.lowercased()).\(stage)\(shiny ? ".shiny" : "").\(states[row]).png"
            // Mechanical size normalization; preserve the entire drawing and
            // add the full gutter after resizing so it never shrinks below 12px.
            var packaged = sprite
            if max(sw, sh) > 400 {
                let bodyWidth = sw - pad * 2, bodyHeight = sh - pad * 2
                let longest = max(bodyWidth, bodyHeight)
                let targetWidth = (bodyWidth * 376 + longest - 1) / longest
                let targetHeight = (bodyHeight * 376 + longest - 1) / longest
                let body = sprite.cropping(to: CGRect(x: pad, y: pad, width: bodyWidth, height: bodyHeight))!
                let context = CGContext(data: nil, width: targetWidth + pad * 2, height: targetHeight + pad * 2,
                    bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.interpolationQuality = .none
                context.draw(body, in: CGRect(x: pad, y: pad, width: targetWidth, height: targetHeight))
                packaged = context.makeImage()!
            }
            let encoder = CGImageDestinationCreateWithURL(destination.appendingPathComponent(file) as CFURL,
                                                         "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(encoder, packaged, nil)
            precondition(CGImageDestinationFinalize(encoder), "Could not write \(file)")
            metadata.append(["file": file, "sourceBounds": [minX,minY,maxX,maxY],
                             "size": [packaged.width,packaged.height], "extractedSize": [sw,sh], "pixels": pts.count])
        }
        let sourceAlpha = stride(from: 3, to: pixels.count, by: 4).reduce(Int64(0)) { $0 + Int64(pixels[$1]) }
        precondition(sourceAlpha == exportedAlpha, "Lost or duplicated source alpha")
        let report: [String: Any] = ["source": url.lastPathComponent,
            "sha256": SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined(),
            "columns": singleStage ? 4 : columns, "rows": singleStage ? 1 : 4,
            "singleStage": singleStage, "variant": shiny ? "shiny" : "normal",
            "sourceAlpha": sourceAlpha, "exportedAlpha": exportedAlpha,
            "sprites": metadata]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: url.deletingPathExtension().appendingPathExtension("json"), options: .atomic)
        print("Exported \(metadata.count) sprites, exact alpha conservation")
    }
    let preview = NSImage(size: NSSize(width: w, height: h))
    preview.lockFocus()
    NSColor(calibratedWhite: 0.90, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()
    NSImage(cgImage: image, size: NSSize(width: w, height: h)).draw(in: NSRect(x: 0, y: 0, width: w, height: h))
    preview.unlockFocus()
    // Review-only compositing; source alpha is never modified.
    let output = URL(fileURLWithPath: "build/art-review", isDirectory: true)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let bitmap = NSBitmapImageRep(data: preview.tiffRepresentation!)!
    let previewName = shiny ? "\(name)-shiny.png" : url.lastPathComponent
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(previewName))
}
