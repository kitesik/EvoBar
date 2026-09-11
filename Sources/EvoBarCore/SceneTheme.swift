import Foundation

/// A backdrop the user bought for the companion's scene. The manifest carries
/// the name and the price, as it does for every other item; the colours live
/// here, with the rest of the app's palette.
///
/// Buying one changes nothing a user is working toward. It is the first thing
/// Token Coins buy that exists only to be looked at, which is what a wallet
/// filled by work needs if it is not to sit untouched.
public enum SceneTheme: String, CaseIterable, Sendable {
    case dawn
    case dusk
    case night
    case snow

    /// The manifest id, so an item and a theme find each other.
    public var itemID: String { "scene-\(rawValue)" }

    public init?(itemID: String) {
        guard itemID.hasPrefix("scene-") else { return nil }
        self.init(rawValue: String(itemID.dropFirst("scene-".count)))
    }

    /// Sky, hills and ground as red, green, blue in 0 through 1. The scene
    /// tints its own gradients and ticks from these; with no theme chosen it
    /// keeps taking its colour from the companion's own artwork.
    public var palette: (sky: RGB, hills: RGB, ground: RGB) {
        switch self {
        case .dawn:
            (RGB(0.99, 0.78, 0.62), RGB(0.86, 0.58, 0.60), RGB(0.62, 0.45, 0.55))
        case .dusk:
            (RGB(0.45, 0.33, 0.58), RGB(0.86, 0.47, 0.42), RGB(0.35, 0.24, 0.42))
        case .night:
            (RGB(0.16, 0.21, 0.42), RGB(0.24, 0.30, 0.52), RGB(0.12, 0.15, 0.30))
        case .snow:
            (RGB(0.80, 0.88, 0.96), RGB(0.68, 0.78, 0.90), RGB(0.88, 0.92, 0.97))
        }
    }

    public struct RGB: Equatable, Sendable {
        public let red: Double
        public let green: Double
        public let blue: Double

        public init(_ red: Double, _ green: Double, _ blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
}
