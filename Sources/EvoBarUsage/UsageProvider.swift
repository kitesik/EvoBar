import EvoBarCore
import Foundation

public enum DetectionStatus: Equatable, Sendable {
    case found(sourceCount: Int)
    case notFound
    case permissionRequired
    case failed(code: String)
}

public struct LogLocation: Equatable, Sendable {
    public let url: URL
    public let providerID: ProviderID

    public init(url: URL, providerID: ProviderID) {
        self.url = url
        self.providerID = providerID
    }
}

public struct SourceCheckpoint: Codable, Equatable, Sendable {
    public var byteOffset: UInt64
    public var fileSize: UInt64
    public var generation: Int
    public var sessionID: String?
    public var modelID: String?

    public init(
        byteOffset: UInt64 = 0,
        fileSize: UInt64 = 0,
        generation: Int = 0,
        sessionID: String? = nil,
        modelID: String? = nil
    ) {
        self.byteOffset = byteOffset
        self.fileSize = fileSize
        self.generation = generation
        self.sessionID = sessionID
        self.modelID = modelID
    }
}

public struct ScanBatch: Sendable {
    public let events: [UsageEvent]
    public let checkpoint: SourceCheckpoint
    public let malformedLineCount: Int

    public init(
        events: [UsageEvent],
        checkpoint: SourceCheckpoint,
        malformedLineCount: Int
    ) {
        self.events = events
        self.checkpoint = checkpoint
        self.malformedLineCount = malformedLineCount
    }
}

public protocol UsageProvider: Sendable {
    var providerID: ProviderID { get }
    func detectionStatus() async -> DetectionStatus
    func discoverLogLocations() async throws -> [LogLocation]
    func discoverLogs() async throws -> LogDiscoveryReport
    func scan(location: LogLocation, checkpoint: SourceCheckpoint) async throws -> ScanBatch
}

public extension UsageProvider {
    func discoverLogs() async throws -> LogDiscoveryReport {
        LogDiscoveryReport(locations: try await discoverLogLocations())
    }
}

public protocol JSONLUsageParsing: AnyObject {
    var sessionID: String? { get }
    var modelID: String? { get }
    func parse(line: Data) throws -> UsageEvent?
}
