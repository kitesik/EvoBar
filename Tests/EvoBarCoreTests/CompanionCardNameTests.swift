import EvoBarCore
import Foundation
import Testing

/// The card's file name carries the companion's name and nothing else, and
/// survives a name that is punctuation or another script.
@Suite struct CompanionCardNameTests {
    private func name(_ value: String) -> String {
        // Mirrors CompanionCardExporter.fileName, which lives in the app target.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let trimmed = String(mapped).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "EvoBar-\(trimmed.isEmpty ? "companion" : trimmed).png"
    }

    @Test func fileNamesAreSafeAndNeverEmpty() {
        #expect(name("Mochi") == "EvoBar-Mochi.png")
        #expect(name("호준") == "EvoBar-호준.png")
        #expect(name("a/b:c") == "EvoBar-a-b-c.png")
        #expect(name("...") == "EvoBar-companion.png")
        #expect(name("") == "EvoBar-companion.png")
    }
}
