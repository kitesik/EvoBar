import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct LogPathResolverTests {
    @Test func tildeSingleAndRecursiveWildcardsResolveJSONLWithoutDuplicates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarGlobTests-\(UUID().uuidString)", isDirectory: true)
        let sessions = root.appendingPathComponent("archive/team-a/sessions/deep", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let log = sessions.appendingPathComponent("session.jsonl")
        try Data("{}\n".utf8).write(to: log)
        try Data("ignore".utf8).write(to: sessions.appendingPathComponent("note.txt"))

        let locations = try LogPathResolver.jsonlLocations(
            defaultRoots: [root.appendingPathComponent("archive/team-a/sessions")],
            additionalPatterns: ["~/archive/*/sessions", "~/archive/**/session.jsonl"],
            providerID: .codex,
            homeDirectory: root
        )

        #expect(locations.map(\.url.path) == [log.path])
    }

    @Test func refusesWildcardEnumerationFromFilesystemRoot() {
        #expect(throws: LogPathPatternError.unsafeWildcardRoot) {
            try LogPathResolver.expand(pattern: "/*.jsonl")
        }
    }

    @Test func relativePatternsAreRejected() {
        #expect(throws: LogPathPatternError.invalidPattern) {
            try LogPathResolver.expand(pattern: "logs/**/*.jsonl")
        }
    }
}
