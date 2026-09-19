import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct OversizedLogLineTests {
    @Test(arguments: [7, 64, 4096])
    func oversizedRecordDoesNotBlockFollowingUsage(chunkSize: Int) throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarLargeLine-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: file) }
        let data = Data(("one\n" + String(repeating: "x", count: 2048) + "\ntwo\n").utf8)
        try data.write(to: file)
        let parser = CountingParser()
        let result = try IncrementalJSONLScanner.scan(url: file, checkpoint: SourceCheckpoint(), parser: parser,
                                                    chunkSize: chunkSize, maximumLineSize: 32)
        #expect(parser.recordSizes == [3, 3])
        #expect(result.malformedLineCount == 1)
        #expect(result.checkpoint.byteOffset == UInt64(data.count))
        let repeated = try IncrementalJSONLScanner.scan(url: file, checkpoint: result.checkpoint, parser: parser,
                                                      chunkSize: chunkSize, maximumLineSize: 32)
        #expect(repeated.malformedLineCount == 0)
        #expect(parser.recordSizes == [3, 3])
    }

    @Test func unfinishedOversizedRecordKeepsItsStartUntilNewlineArrives() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarPartialLine-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: file) }
        var data = Data(("one\n" + String(repeating: "x", count: 2048)).utf8)
        try data.write(to: file)
        let parser = CountingParser()
        let first = try IncrementalJSONLScanner.scan(url: file, checkpoint: SourceCheckpoint(), parser: parser,
                                                   chunkSize: 17, maximumLineSize: 32)
        #expect(first.checkpoint.byteOffset == 4)
        #expect(first.malformedLineCount == 0)
        data.append(Data("\ntwo\n".utf8))
        try data.write(to: file)
        let second = try IncrementalJSONLScanner.scan(url: file, checkpoint: first.checkpoint, parser: parser,
                                                    chunkSize: 17, maximumLineSize: 32)
        #expect(second.malformedLineCount == 1)
        #expect(second.checkpoint.byteOffset == UInt64(data.count))
        #expect(parser.recordSizes == [3, 3])
    }

    @Test func exactLimitAndConsecutiveOversizedRecordsRespectBoundaries() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarBoundaryLine-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("12345678\n123456789\n1234567890\nok\n\n".utf8).write(to: file)
        let parser = CountingParser()
        let result = try IncrementalJSONLScanner.scan(url: file, checkpoint: SourceCheckpoint(), parser: parser,
                                                    chunkSize: 4, maximumLineSize: 8)
        #expect(parser.recordSizes == [8, 2])
        #expect(result.malformedLineCount == 2)
    }
}

private final class CountingParser: JSONLUsageParsing {
    var sessionID: String? { nil }
    var modelID: String? { nil }
    var recordSizes: [Int] = []
    func parse(line: Data) throws -> UsageEvent? {
        recordSizes.append(line.count)
        return nil
    }
}
