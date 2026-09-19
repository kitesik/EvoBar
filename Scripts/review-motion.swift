#!/usr/bin/env swift
import AppKit
import Foundation
import ImageIO

#if !EVOBAR_MOTION_REVIEW_LINKED
// Build just the actual production decoder/presentation helper, without taking
// SwiftPM's lock or duplicating its crop formula in this review tool.
let reviewRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let reviewTool = reviewRoot.appendingPathComponent("build/art-review/motion-tool")
try FileManager.default.createDirectory(at: reviewTool, withIntermediateDirectories: true)
func execute(_ arguments: [String]) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus
}
let compileStatus = try execute(["swiftc", "-D", "EVOBAR_MOTION_REVIEW_STANDALONE",
    "-emit-library", "-emit-module", "-module-name", "EvoBarMotionReview",
    reviewRoot.appendingPathComponent("Sources/EvoBarCore/AnimalAssets.swift").path,
    "-o", reviewTool.appendingPathComponent("libEvoBarMotionReview.dylib").path,
    "-emit-module-path", reviewTool.appendingPathComponent("EvoBarMotionReview.swiftmodule").path])
guard compileStatus == 0 else { exit(compileStatus) }
exit(try execute(["swift", "-D", "EVOBAR_MOTION_REVIEW_LINKED", "-I", reviewTool.path,
    "-L", reviewTool.path, "-lEvoBarMotionReview", URL(fileURLWithPath: #filePath).path]
    + Array(CommandLine.arguments.dropFirst())))
#else
import EvoBarMotionReview

// Mechanical review only: crop the shipped strips without retouching artwork,
// then render the four phases at actual menu/pet sizes on both backgrounds.
// Run from any directory: swift Scripts/review-motion.swift --expected-count 60
// Add --raw for the unnormalized before-comparison in build/art-review/motion-raw.
// Add --no-menu-rim for normalized sizes without the menu-only contrast shadow.
struct ReviewError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

struct Strip {
    let id: String
    let line: String
    let stage: Int
    let variant: String
    let frames: [CGImage]
    let rawDimension: Int
    let presentationCrop: CGRect
}

let manager = FileManager.default
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sprites = root.appendingPathComponent("Sources/EvoBarCore/Resources/Sprites")
let arguments = CommandLine.arguments
let raw = arguments.contains("--raw")
let menuRim = !raw && !arguments.contains("--no-menu-rim")
let output = root.appendingPathComponent("build/art-review/motion\(raw ? "-raw" : menuRim ? "" : "-no-rim")")
let expected: Int? = try {
    guard let index = arguments.firstIndex(of: "--expected-count") else { return nil }
    guard arguments.indices.contains(index + 1), let count = Int(arguments[index + 1]), count > 0 else {
        throw ReviewError("--expected-count needs a positive number")
    }
    return count
}()

let urls = try manager.contentsOfDirectory(at: sprites, includingPropertiesForKeys: nil)
    .filter { $0.lastPathComponent.hasSuffix(".motion.png") }
    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
guard !urls.isEmpty else { throw ReviewError("No authored motion strips to review") }
if let expected, urls.count != expected {
    throw ReviewError("Expected \(expected) complete strips; found \(urls.count). Wait for asset imports to finish.")
}

let strips: [Strip] = try urls.map { url in
    let id = String(url.lastPathComponent.dropLast(".motion.png".count))
    let pieces = id.split(separator: ".")
    guard (pieces.count == 2 || (pieces.count == 3 && pieces[2] == "shiny")),
          let stage = Int(pieces[1]), stage > 0,
          let decoded = AuthoredSpriteMotion.decodeFrames(from: try Data(contentsOf: url)),
          let crop = AuthoredSpriteMotion.presentationCrop(for: decoded),
          let presented = AuthoredSpriteMotion.presentationFrames(from: decoded) else {
        throw ReviewError("Invalid four-square strip: \(url.lastPathComponent)")
    }
    return Strip(id: id, line: String(pieces[0]), stage: stage,
                 variant: pieces.count == 3 ? "shiny" : "normal", frames: raw ? decoded : presented,
                 rawDimension: decoded[0].width, presentationCrop: crop)
}

func label(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, light: Bool, size: CGFloat = 11) {
    (text as NSString).draw(in: NSRect(x: x, y: y, width: width, height: size + 6), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: size, weight: .medium),
        .foregroundColor: light ? NSColor.black : NSColor.white
    ])
}

func fill(_ rect: NSRect, light: Bool) {
    (light ? NSColor(calibratedWhite: 0.94, alpha: 1)
           : NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.12, alpha: 1)).setFill()
    rect.fill()
}

func draw(_ image: CGImage, x: CGFloat, y: CGFloat, size: CGFloat, menuLight: Bool? = nil) {
    let render = {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current?.imageInterpolation = .high
        if menuLight != nil && menuRim {
            // Mirrors the native menu-only NSShadow in StatusItemController;
            // pet artwork is deliberately untouched. No colour replacement.
            let contrast = NSShadow()
            contrast.shadowColor = NSColor.labelColor.withAlphaComponent(0.35)
            contrast.shadowBlurRadius = 0.5
            contrast.shadowOffset = .zero
            contrast.set()
        }
        NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            .draw(in: NSRect(x: x, y: y, width: size, height: size))
    }
    if let light = menuLight, let appearance = NSAppearance(named: light ? .aqua : .darkAqua) {
        appearance.performAsCurrentDrawingAppearance(render)
    } else { render() }
}

func canvas(width: Int, height: Int, drawing: () -> Void) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw ReviewError("Unable to allocate review canvas")
    }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = context
    drawing()
    return bitmap
}

func contactSheet(_ group: [Strip], light: Bool) throws -> NSBitmapImageRep {
    let cellWidth = 132, cellHeight = 152, left = 126, header = 60
    let width = left + 4 * cellWidth, height = header + group.count * cellHeight
    return try canvas(width: width, height: height) {
        fill(NSRect(x: 0, y: 0, width: width, height: height), light: light)
        label("\(group[0].line) / \(group[0].variant) / 96px + 24px", x: 12,
              y: CGFloat(height - 24), width: CGFloat(width - 24), light: light, size: 13)
        for phase in 0..<4 {
            label("phase \(phase + 1)", x: CGFloat(left + phase * cellWidth + 24),
                  y: CGFloat(height - 48), width: 110, light: light)
        }
        for (row, strip) in group.enumerated() {
            let y = CGFloat(height - header - (row + 1) * cellHeight)
            label("stage \(strip.stage)", x: 12, y: y + 83, width: 112, light: light)
            label("96px pet", x: 12, y: y + 62, width: 112, light: light, size: 10)
            label("24px menu", x: 12, y: y + 9, width: 112, light: light, size: 10)
            for phase in 0..<4 {
                let x = CGFloat(left + phase * cellWidth)
                draw(strip.frames[phase], x: x + 18, y: y + 42, size: 96)
                draw(strip.frames[phase], x: x + 54, y: y + 6, size: 24, menuLight: light)
            }
        }
    }
}

func animatedMontage(_ group: [Strip], phase: Int) throws -> CGImage {
    let cellWidth = 124, rowHeight = 162, header = 34
    let width = max(496, group.count * cellWidth), height = 2 * rowHeight + header
    let bitmap = try canvas(width: width, height: height) {
        fill(NSRect(x: 0, y: 0, width: width, height: height), light: false)
        label("\(group[0].line) / \(group[0].variant) / working loop: 4 x 0.12s", x: 10,
              y: CGFloat(height - 25), width: CGFloat(width - 20), light: false, size: 12)
        for (row, light) in [false, true].enumerated() {
            let y = CGFloat(height - header - (row + 1) * rowHeight)
            fill(NSRect(x: 0, y: y, width: CGFloat(width), height: CGFloat(rowHeight)), light: light)
            for (column, strip) in group.enumerated() {
                let x = CGFloat(column * cellWidth)
                draw(strip.frames[phase], x: x + 14, y: y + 48, size: 96)
                draw(strip.frames[phase], x: x + 50, y: y + 19, size: 24, menuLight: light)
                label("stage \(strip.stage)", x: x + 30, y: y + 1, width: 90, light: light, size: 10)
            }
        }
    }
    guard let image = bitmap.cgImage else { throw ReviewError("Missing montage pixels") }
    return image
}

func visibleBounds(_ image: CGImage) throws -> [String: Double] {
    let width = image.width, height = image.height
    var rgba = [UInt8](repeating: 0, count: width * height * 4)
    try rgba.withUnsafeMutableBytes { bytes in
        guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw ReviewError("Unable to measure visible bounds")
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    var left = width, right = -1, top = height, bottom = -1
    for y in 0..<height {
        for x in 0..<width where rgba[(y * width + x) * 4 + 3] > 32 {
            left = min(left, x); right = max(right, x)
            top = min(top, y); bottom = max(bottom, y)
        }
    }
    guard right >= left, bottom >= top else { throw ReviewError("Empty authored frame") }
    return ["widthAt24px": Double(right - left + 1) * 24 / Double(width),
            "heightAt24px": Double(bottom - top + 1) * 24 / Double(height)]
}

try manager.createDirectory(at: output, withIntermediateDirectories: true)
let groups = Dictionary(grouping: strips) { "\($0.line)-\($0.variant)" }
var generated: [String] = []
for key in groups.keys.sorted() {
    let group = groups[key]!.sorted { $0.stage < $1.stage }
    for light in [false, true] {
        let name = "\(key)-\(light ? "light" : "dark").png"
        let bitmap = try contactSheet(group, light: light)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ReviewError("Could not encode \(name)")
        }
        try data.write(to: output.appendingPathComponent(name), options: .atomic)
        generated.append(name)
    }
    let name = "\(key)-loop.gif"
    guard let destination = CGImageDestinationCreateWithURL(output.appendingPathComponent(name) as CFURL,
                                                          "com.compuserve.gif" as CFString, 4, nil) else {
        throw ReviewError("Could not create \(name)")
    }
    CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary:
        [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.12,
        kCGImagePropertyGIFUnclampedDelayTime: 0.12]] as CFDictionary
    for phase in 0..<4 { CGImageDestinationAddImage(destination, try animatedMontage(group, phase: phase), properties) }
    guard CGImageDestinationFinalize(destination) else { throw ReviewError("Could not finish \(name)") }
    guard let verification = CGImageSourceCreateWithURL(output.appendingPathComponent(name) as CFURL, nil),
          CGImageSourceGetCount(verification) == 4 else { throw ReviewError("Invalid GIF frame count: \(name)") }
    for phase in 0..<4 {
        let properties = CGImageSourceCopyPropertiesAtIndex(verification, phase, nil) as? [CFString: Any]
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        guard let delay = gif?[kCGImagePropertyGIFDelayTime] as? Double,
              abs(delay - 0.12) < 0.001 else { throw ReviewError("Invalid GIF frame delay: \(name)") }
    }
    generated.append(name)
}

let stripInventory: [[String: Any]] = try strips.map { strip in
    ["assetID": strip.id, "frameDimension": strip.frames[0].width,
     "rawFrameDimension": strip.rawDimension,
     "presentationCrop": [strip.presentationCrop.minX, strip.presentationCrop.minY,
                          strip.presentationCrop.width, strip.presentationCrop.height],
     "visibleBoundsByPhase": try strip.frames.map(visibleBounds)]
}
let inventory: [String: Any] = [
    "stripCount": strips.count,
    "framesPerStrip": 4,
    "displaySizesPixels": [24, 96],
    "gifFrameDurationSeconds": 0.12,
    "groups": groups.keys.sorted(),
    "mode": raw ? "raw" : "shared-production-presentation",
    "menuOnlyContrastRim": menuRim,
    "strips": stripInventory,
    "generated": generated,
    "scope": "Mechanical cropping/resizing review only. Existence, distinct bytes or technical validity do not certify anatomy or animation quality."
]
try JSONSerialization.data(withJSONObject: inventory, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("inventory.json"), options: .atomic)
print("Reviewed \(strips.count) strips in \(groups.count) groups: \(generated.count) images/GIFs")
print(output.path)
#endif
