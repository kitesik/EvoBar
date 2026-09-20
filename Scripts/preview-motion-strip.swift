#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// Mechanical preview packaging: preserves authored pixels, no synthetic poses.
let args = Array(CommandLine.arguments.dropFirst())
precondition(args.count == 2, "usage: preview-motion-strip.swift STRIP.png PREVIEW.gif")
let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[0]) as CFURL, nil)!
let strip = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(strip.width == strip.height * 4 && strip.height <= 256)
let output = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL,
                                            "com.compuserve.gif" as CFString, 4, nil)!
CGImageDestinationSetProperties(output, [kCGImagePropertyGIFDictionary:
    [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for index in 0..<4 {
    let frame = strip.cropping(to: CGRect(x: index * strip.height, y: 0,
                                         width: strip.height, height: strip.height))!
    CGImageDestinationAddImage(output, frame, [kCGImagePropertyGIFDictionary:
        [kCGImagePropertyGIFDelayTime: 0.12]] as CFDictionary)
}
precondition(CGImageDestinationFinalize(output))
print("Created four-frame looping preview:", args[1])
