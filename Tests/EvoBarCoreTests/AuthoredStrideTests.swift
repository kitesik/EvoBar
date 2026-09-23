import CoreGraphics
import EvoBarCore
import Foundation
import ImageIO
import Testing

@Suite struct AuthoredStrideTests {
    private func frames(_ assetID: String) -> [CGImage]? {
        let reference = AnimalAssetReference(assetID: assetID, fallbackEmoji: "", visualState: .idle)
        return BundledAnimalSpriteStore.motionData(for: reference)
            .flatMap(AuthoredSpriteMotion.decodeFrames(from:))
            .flatMap(AuthoredSpriteMotion.presentationFrames(from:))
    }

    /// A strip that walks has a measurable stride, and it is a stride rather
    /// than the whole animal sliding across the frame.
    @Test func walkingStripsMeasureAPlausibleStride() throws {
        for assetID in ["cat.5", "dog.4", "pterosaur.1", "raptor.5", "capybara.2"] {
            let cropped = try #require(frames(assetID), "\(assetID) has no authored strip")
            let stride = AuthoredSpriteMotion.strideFraction(of: cropped)
            #expect(stride > 0.005, "\(assetID) stride \(stride) is too small to scroll by")
            #expect(stride < 0.5, "\(assetID) stride \(stride) is more than half the frame")
        }
    }

    /// The reason a constant could not serve: the lines do not walk alike. If
    /// this ever collapses to one value the measurement has stopped working.
    @Test func stridesDifferBetweenLines() throws {
        var measured: [String: Double] = [:]
        for assetID in ["cat.5", "raptor.5", "mammoth.6", "fox.1"] {
            guard let cropped = frames(assetID) else { continue }
            measured[assetID] = AuthoredSpriteMotion.strideFraction(of: cropped)
        }
        #expect(measured.count >= 3)
        let values = measured.values.sorted()
        #expect(values.last! > values.first! * 2, "strides \(measured) are too alike to be measured")
    }

    /// Nothing to measure must read as no movement, never as a default speed.
    @Test func anEmptyOrSingleFrameStripHasNoStride() {
        #expect(AuthoredSpriteMotion.strideFraction(of: []) == 0)
    }
}
