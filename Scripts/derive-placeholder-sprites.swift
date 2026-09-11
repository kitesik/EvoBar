#!/usr/bin/env swift

// Stages added on 2026-09-09 have no drawn sheet yet. Until one exists, each
// gets a placeholder recoloured from a neighbouring form of the same line, so
// an evolution is visible instead of showing the same drawing twice. Every
// placeholder stays `artworkPending` in the manifest and is replaced, not
// edited, when the real sheet is extracted.
//
// usage: derive-placeholder-sprites.swift SPRITES_DIRECTORY

import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Placeholder {
    let source: String
    let target: String
    /// Hue rotation in radians, saturation multiplier, brightness offset.
    let hue: Float
    let saturation: Float
    let brightness: Float
}

let placeholders: [Placeholder] = [
    Placeholder(source: "cat.3", target: "cat.4", hue: 0.05, saturation: 0.45, brightness: 0.06),       // lynx: grey-buff
    Placeholder(source: "cat.5", target: "cat.6", hue: -0.38, saturation: 0.7, brightness: -0.14),     // smilodon: dark tawny
    Placeholder(source: "dog.3", target: "dog.4", hue: 0, saturation: 0.3, brightness: 0.02),          // gray wolf
    Placeholder(source: "dog.3", target: "dog.6", hue: -0.15, saturation: 0.85, brightness: -0.13),    // epicyon: dark tawny, heavy
    Placeholder(source: "fox.2", target: "fox.4", hue: 0.12, saturation: 0.55, brightness: 0.06),      // qiu's fox: pale sand
    Placeholder(source: "fox.3", target: "fox.5", hue: 0, saturation: 0.45, brightness: 0.2),          // snow fox: near white
    Placeholder(source: "capybara.4", target: "capybara.5", hue: -0.3, saturation: 0.9, brightness: -0.05), // phoberomys: browner
    Placeholder(source: "capybara.4", target: "capybara.6", hue: -0.32, saturation: 0.8, brightness: -0.17), // josephoartigasia: dark umber
]
let states = ["idle", "working", "evolutionReady", "sleeping"]

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: derive-placeholder-sprites.swift SPRITES_DIRECTORY\n".utf8))
    exit(2)
}
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
// Archive-only utility: a recolor must never replace a newly drawn stage.
let existingTargets = placeholders.flatMap { placeholder in
    states.map { directory.appendingPathComponent("\(placeholder.target).\($0).png") }
}.filter { FileManager.default.fileExists(atPath: $0.path) }
guard existingTargets.isEmpty else {
    FileHandle.standardError.write(Data("Refusing to overwrite existing artwork. This legacy tool only writes to an empty archive directory. Use prepare-art-atlas.swift for Atlas V2.\n".utf8))
    exit(2)
}
let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])

for placeholder in placeholders {
    for state in states {
        let sourceURL = directory.appendingPathComponent("\(placeholder.source).\(state).png")
        let targetURL = directory.appendingPathComponent("\(placeholder.target).\(state).png")
        guard let image = CIImage(contentsOf: sourceURL) else {
            fatalError("Could not read \(sourceURL.path)")
        }
        var output = image
        if placeholder.hue != 0 {
            output = output.applyingFilter("CIHueAdjust", parameters: [kCIInputAngleKey: placeholder.hue])
        }
        output = output.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: placeholder.saturation,
            kCIInputBrightnessKey: placeholder.brightness,
            kCIInputContrastKey: 1.0,
        ])
        guard let rendered = context.createCGImage(output, from: image.extent) else {
            fatalError("Could not render \(targetURL.lastPathComponent)")
        }
        guard let destination = CGImageDestinationCreateWithURL(
            targetURL as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { fatalError("Could not open \(targetURL.path)") }
        CGImageDestinationAddImage(destination, rendered, nil)
        guard CGImageDestinationFinalize(destination) else { fatalError("Could not write \(targetURL.path)") }
        print("wrote \(targetURL.lastPathComponent) from \(placeholder.source)")
    }
}
