#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Calibrated transparent gutters in the checked-in 1536×1024 source sheet.
private let columnEdges = [0, 235, 490, 780, 1_120, 1_536]
private let workingEvolutionEdges = [530, 530, 530, 545, 530]
private let rowEdges = [0, 315, 530, 825, 1_024]
private let states = ["idle", "working", "evolutionReady", "sleeping"]
private let alphaThreshold: UInt8 = 8
private let padding = 6

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: extract-sprite-sheet.swift SOURCE.png OUTPUT_DIRECTORY\n".utf8))
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Could not decode sprite sheet at \(sourceURL.path)")
}
guard sheet.width == columnEdges.last!, sheet.height == rowEdges.last! else {
    fatalError("Expected the checked-in 1536×1024 EvoBar cat sprite sheet")
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for row in 0..<states.count {
    for column in 0..<(columnEdges.count - 1) {
        let x0 = columnEdges[column]
        let x1 = columnEdges[column + 1]
        let y0 = row == 2 ? workingEvolutionEdges[column] : rowEdges[row]
        let y1 = row == 1 ? workingEvolutionEdges[column] : rowEdges[row + 1]
        let cellRect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
        guard let cell = sheet.cropping(to: cellRect),
              let contentBounds = alphaBounds(of: cell) else {
            fatalError("Sprite cell \(column + 1),\(row + 1) is empty")
        }

        let cropRect = contentBounds
            .insetBy(dx: -CGFloat(padding), dy: -CGFloat(padding))
            .intersection(CGRect(x: 0, y: 0, width: cell.width, height: cell.height))
            .integral
        guard let sprite = cell.cropping(to: cropRect) else {
            fatalError("Could not crop sprite cell \(column + 1),\(row + 1)")
        }

        let name = "cat.\(column + 1).\(states[row]).png"
        let destinationURL = outputDirectory.appendingPathComponent(name)
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            fatalError("Could not create \(destinationURL.path)")
        }
        CGImageDestinationAddImage(destination, sprite, nil)
        guard CGImageDestinationFinalize(destination) else {
            fatalError("Could not write \(destinationURL.path)")
        }
    }
}

private func alphaBounds(of image: CGImage) -> CGRect? {
    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
    let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard rendered else { return nil }

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1
    for y in 0..<height {
        for x in 0..<width where pixels[(y * bytesPerRow) + (x * 4) + 3] > alphaThreshold {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
    guard maxX >= minX, maxY >= minY else { return nil }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}
