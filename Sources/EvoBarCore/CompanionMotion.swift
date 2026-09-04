import Foundation

public struct CompanionMotionProfile: Equatable, Sendable {
    public let frameInterval: TimeInterval?
    public let verticalOffsets: [Double]
    public let scaleFactors: [Double]

    public init(
        frameInterval: TimeInterval?,
        verticalOffsets: [Double],
        scaleFactors: [Double]
    ) {
        self.frameInterval = frameInterval
        self.verticalOffsets = verticalOffsets
        self.scaleFactors = scaleFactors
    }

    public func verticalOffset(for frame: Int) -> Double {
        guard !verticalOffsets.isEmpty else { return 0 }
        return verticalOffsets[positiveModulo(frame, verticalOffsets.count)]
    }

    public func scaleFactor(for frame: Int) -> Double {
        guard !scaleFactors.isEmpty else { return 1 }
        return scaleFactors[positiveModulo(frame, scaleFactors.count)]
    }

    public static func resolve(
        qualityID: String,
        visualState: CompanionVisualState
    ) -> CompanionMotionProfile {
        guard qualityID != "powerSaver", visualState != .sleeping else {
            return CompanionMotionProfile(
                frameInterval: nil,
                verticalOffsets: [0],
                scaleFactors: [1]
            )
        }

        let smooth = qualityID == "smooth"
        switch visualState {
        case .working:
            return CompanionMotionProfile(
                frameInterval: smooth ? 0.28 : 0.55,
                verticalOffsets: [0, 1],
                scaleFactors: [1, 0.96]
            )
        case .evolutionReady:
            return CompanionMotionProfile(
                frameInterval: smooth ? 0.4 : 0.7,
                verticalOffsets: [0, 0],
                scaleFactors: [1, 0.88]
            )
        case .idle:
            return CompanionMotionProfile(
                frameInterval: smooth ? 0.9 : 1.4,
                verticalOffsets: [0, 1],
                scaleFactors: [1, 0.97]
            )
        case .sleeping:
            return CompanionMotionProfile(
                frameInterval: nil,
                verticalOffsets: [0],
                scaleFactors: [1]
            )
        }
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
