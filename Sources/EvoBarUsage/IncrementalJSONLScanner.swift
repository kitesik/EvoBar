import EvoBarCore
import Foundation

public enum JSONLScannerError: Error {
    case fileTooLarge
}

public enum IncrementalJSONLScanner {
    public static func scan(
        url: URL,
        checkpoint originalCheckpoint: SourceCheckpoint,
        parser: JSONLUsageParsing,
        chunkSize: Int = 64 * 1024,
        maximumLineSize: Int = 8 * 1024 * 1024
    ) throws -> ScanBatch {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        var checkpoint = originalCheckpoint
        if fileSize < checkpoint.byteOffset {
            checkpoint.byteOffset = 0
            checkpoint.generation += 1
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: checkpoint.byteOffset)

        var buffer = Data()
        var completeBytes: UInt64 = 0
        var events: [UsageEvent] = []
        var malformed = 0

        while let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty {
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                let consumed = buffer.distance(from: buffer.startIndex, to: newline) + 1
                buffer.removeFirst(consumed)
                completeBytes += UInt64(consumed)
                if line.isEmpty { continue }
                do {
                    if let event = try parser.parse(line: line) { events.append(event) }
                } catch {
                    malformed += 1
                }
            }
            if buffer.count > maximumLineSize {
                throw JSONLScannerError.fileTooLarge
            }
        }

        checkpoint.byteOffset += completeBytes
        checkpoint.fileSize = fileSize
        checkpoint.sessionID = parser.sessionID ?? checkpoint.sessionID
        checkpoint.modelID = parser.modelID ?? checkpoint.modelID
        return ScanBatch(events: events, checkpoint: checkpoint, malformedLineCount: malformed)
    }
}
