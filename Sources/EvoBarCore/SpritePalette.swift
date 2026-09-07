import CoreGraphics
import Foundation

/// The colour a sprite reads as, so scenery can be tinted from the artwork
/// itself. A line carries one theme colour in the manifest, but a companion's
/// palette changes completely by its last stage, and a scene tinted amber
/// behind a cosmic blue tiger looks like a mismatch.
public enum SpritePalette {
    /// Hue, saturation and brightness of the sprite's most characteristic
    /// colour: the busiest hue, weighted by how saturated and how opaque each
    /// pixel is, so outlines and pale bellies do not decide the answer.
    public static func dominantColor(of image: CGImage) -> (hue: Double, saturation: Double, brightness: Double)? {
        let width = image.width, height = image.height
        guard width > 0, height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
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

        let buckets = 24
        var weight = [Double](repeating: 0, count: buckets)
        var saturationSum = [Double](repeating: 0, count: buckets)
        var brightnessSum = [Double](repeating: 0, count: buckets)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha > 0.5 else { continue }
            // Undo the premultiplication so a soft edge is not read as dark.
            let r = Double(pixels[index]) / 255 / alpha
            let g = Double(pixels[index + 1]) / 255 / alpha
            let b = Double(pixels[index + 2]) / 255 / alpha
            let (hue, saturation, brightness) = hsb(min(r, 1), min(g, 1), min(b, 1))
            guard saturation > 0.15, brightness > 0.15 else { continue }
            let bucket = min(buckets - 1, Int(hue * Double(buckets)))
            let vote = saturation * alpha
            weight[bucket] += vote
            saturationSum[bucket] += saturation * vote
            brightnessSum[bucket] += brightness * vote
        }
        guard let best = weight.indices.max(by: { weight[$0] < weight[$1] }), weight[best] > 0 else { return nil }
        return (
            hue: (Double(best) + 0.5) / Double(buckets),
            saturation: min(1, saturationSum[best] / weight[best]),
            brightness: min(1, brightnessSum[best] / weight[best])
        )
    }

    private static func hsb(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let maximum = max(r, g, b), minimum = min(r, g, b)
        let delta = maximum - minimum
        var hue = 0.0
        if delta > 0 {
            if maximum == r {
                hue = (g - b) / delta
            } else if maximum == g {
                hue = 2 + (b - r) / delta
            } else {
                hue = 4 + (r - g) / delta
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        return (hue, maximum == 0 ? 0 : delta / maximum, maximum)
    }
}
