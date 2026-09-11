#!/usr/bin/env swift
import AppKit
import ImageIO
import CryptoKit

// Atlas slicing is mechanical packaging: preserve source colors/alpha, never
// recolor a form or manufacture one from a neighboring stage. A merged/missing
// body fails closed before export instead of silently cutting through an animal.
let arguments = Array(CommandLine.arguments.dropFirst())
let flags = Array(arguments.prefix { $0.hasPrefix("--") })
precondition(flags.allSatisfy { ["--export", "--shiny"].contains($0) }, "Unknown atlas flag")
let export = flags.contains("--export")
let shiny = flags.contains("--shiny")
let paths = Array(arguments.dropFirst(flags.count))
let expectedColumns = ["Cat": 7, "Dog": 7, "Fox": 7, "Capybara": 7,
                       "Raptor": 8, "Mammoth": 7, "Pterosaur": 8,
                       "Dragon": 7, "Phoenix": 7, "Kirin": 7]
let states = ["idle", "working", "evolutionReady", "sleeping"]
precondition(!paths.isEmpty, "usage: prepare-art-atlas.swift [--export] [--shiny] ATLAS.png ... (run at repository root)")
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
    let name = url.deletingPathExtension().lastPathComponent
    guard let columns = expectedColumns[name] else { fatalError("Unknown atlas: \(name)") }
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
            for n in q { labels[n] = components.count }
            components.append([q.count, loX, loY, hiX, hiY]); members.append(q)
        }
    }
    print(url.lastPathComponent, w, h, "regions:", components.count)
    guard components.count == columns * 4 else {
        fatalError("Expected \(columns * 4) separate bodies; redraw touching/missing forms before export")
    }
    let byBaseline = components.indices.sorted { components[$0][4] < components[$1][4] }
    var ordered: [Int] = []
    for row in 0..<4 {
        let group = Array(byBaseline[(row * columns)..<((row + 1) * columns)])
            .sorted { components[$0][1] < components[$1][1] }
        let baselines = group.map { components[$0][4] }
        precondition(baselines.max()! - baselines.min()! < h / 8, "Inconsistent atlas row")
        ordered.append(contentsOf: group)
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
            let row = index / columns, stage = index % columns + 1
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
            let encoder = CGImageDestinationCreateWithURL(destination.appendingPathComponent(file) as CFURL,
                                                         "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(encoder, sprite, nil)
            precondition(CGImageDestinationFinalize(encoder), "Could not write \(file)")
            metadata.append(["file": file, "sourceBounds": [minX,minY,maxX,maxY],
                             "size": [sw,sh], "pixels": pts.count])
        }
        let sourceAlpha = stride(from: 3, to: pixels.count, by: 4).reduce(Int64(0)) { $0 + Int64(pixels[$1]) }
        precondition(sourceAlpha == exportedAlpha, "Lost or duplicated source alpha")
        let report: [String: Any] = ["source": url.lastPathComponent,
            "sha256": SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined(),
            "columns": columns, "rows": 4, "variant": shiny ? "shiny" : "normal",
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
