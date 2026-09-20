#!/usr/bin/env swift
import AppKit

// Local asset contact sheets only. No desktop capture or provider-log access.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("build/art-review")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let shiny = CommandLine.arguments.contains("--shiny")
let suffix = shiny ? ".shiny" : ""
let allLines: [(String, Int)] = [("cat",7),("dog",7),("fox",7),("capybara",7),
    ("raptor",8),("mammoth",7),("pterosaur",8),("dragon",7),("phoenix",7),("kirin",7)]
let lines = allLines.filter { line, _ in
    !shiny || FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/EvoBarCore/Resources/Sprites/\(line).1.shiny.idle.png").path)
}
precondition(!lines.isEmpty, "No bundled artwork for this variant")
let states = ["idle", "working", "evolutionReady", "sleeping"]
func render(name: String, rows: [[(String, String)]], light: Bool) throws {
    let cellWidth = 180, cellHeight = 170, height = rows.count * cellHeight
    let width = (rows.map(\.count).max() ?? 1) * cellWidth
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    (light ? NSColor(calibratedWhite: 0.94, alpha: 1) : NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.12, alpha: 1)).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    for (r, row) in rows.enumerated() {
        for (c, item) in row.enumerated() {
            let path = root.appendingPathComponent("Sources/EvoBarCore/Resources/Sprites/\(item.0).png")
            guard let image = NSImage(contentsOf: path) else { fatalError("Missing \(path)") }
            let scale = min(150 / image.size.width, 125 / image.size.height)
            let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
            let x = CGFloat(c * cellWidth), y = CGFloat(height - (r + 1) * cellHeight)
            image.draw(in: NSRect(x: x + (180 - size.width) / 2, y: y + 27 + (130 - size.height) / 2, width: size.width, height: size.height))
            (item.1 as NSString).draw(in: NSRect(x: x + 10, y: y + 6, width: 164, height: 18), withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: light ? NSColor.black : NSColor.white])
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name + ".png"))
}
for light in [false, true] {
    let theme = (shiny ? "shiny-" : "") + (light ? "light" : "dark")
    try render(name: "baby-states-\(theme)", rows: lines.map { line, _ in
        states.map { ("\(line).1\(suffix).\($0)", "\(line) \($0)") }
    }, light: light)
    let featured = lines.map { line, count in ("\(line).\(count)\(suffix).idle", line) }
    let featuredRows = stride(from: 0, to: featured.count, by: 5).map { Array(featured[$0..<min($0 + 5, featured.count)]) }
    try render(name: "final-forms-\(theme)", rows: featuredRows, light: light)
    let formCount = lines.reduce(0) { $0 + $1.1 }
    try render(name: "all-\(formCount)-\(theme)", rows: lines.map { line, count in
        (1...count).map { ("\(line).\($0)\(suffix).idle", "\(line).\($0)") }
    }, light: light)
    for (line, count) in lines {
        try render(name: "\(line)-poses-\(theme)", rows: states.map { state in
            (1...count).map { ("\(line).\($0)\(suffix).\(state)", "\(line).\($0) \(state == "evolutionReady" ? "ready" : state)") }
        }, light: light)
    }
}
print(output.path)
