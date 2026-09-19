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
        var lineBytes: UInt64 = 0
        var skippingOversizedLine = false
        var completeBytes: UInt64 = 0
        var events: [UsageEvent] = []
        var malformed = 0

        while let chunk = try handle.read(upToCount: max(1, chunkSize)), !chunk.isEmpty {
            try Task.checkCancellation()
            var start = chunk.startIndex
            while start < chunk.endIndex {
                let newline = chunk[start...].firstIndex(of: 0x0A)
                let end = newline ?? chunk.endIndex
                let fragment = chunk[start..<end]
                lineBytes += UInt64(fragment.count)
                if !skippingOversizedLine {
                    if lineBytes > UInt64(max(0, maximumLineSize)) {
                        // Images and tool payloads can be much larger than usage
                        // records. Discard their bytes, not the rest of the file.
                        skippingOversizedLine = true
                        buffer.removeAll(keepingCapacity: false)
                    } else {
                        buffer.append(contentsOf: fragment)
                    }
                }
                guard let newline else { break }
                completeBytes += lineBytes + 1
                if skippingOversizedLine {
                    malformed += 1
                } else if !buffer.isEmpty {
                    do {
                        if let event = try parser.parse(line: buffer) { events.append(event) }
                    } catch {
                        malformed += 1
                    }
                }
                buffer.removeAll(keepingCapacity: true)
                lineBytes = 0
                skippingOversizedLine = false
                start = chunk.index(after: newline)
            }
        }

        checkpoint.byteOffset += completeBytes
        checkpoint.fileSize = fileSize
        checkpoint.sessionID = parser.sessionID ?? checkpoint.sessionID
        checkpoint.modelID = parser.modelID ?? checkpoint.modelID
        return ScanBatch(events: events, checkpoint: checkpoint, malformedLineCount: malformed)
    }
}
