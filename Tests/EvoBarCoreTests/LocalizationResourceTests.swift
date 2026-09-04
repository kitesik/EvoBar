import Foundation
import Testing

struct LocalizationResourceTests {
    private let locales = ["en", "ko", "ja", "es", "fr", "pt"]

    @Test func allSupportedLocalesHaveMatchingKeysAndFormatSpecifiers() throws {
        let resources = repositoryRoot
            .appendingPathComponent("Sources/EvoBarApp/Resources", isDirectory: true)
        let catalogs = try Dictionary(uniqueKeysWithValues: locales.map { locale in
            let url = resources
                .appendingPathComponent("\(locale).lproj", isDirectory: true)
                .appendingPathComponent("Localizable.strings")
            let data = try Data(contentsOf: url)
            let value = try #require(
                PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
            )
            return (locale, value)
        })

        let english = try #require(catalogs["en"])
        #expect(english.count >= 100)
        for locale in locales.dropFirst() {
            let catalog = try #require(catalogs[locale])
            #expect(Set(catalog.keys) == Set(english.keys))
            for key in english.keys {
                #expect(formatSpecifiers(in: catalog[key] ?? "") == formatSpecifiers(in: english[key] ?? ""))
            }
        }
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func formatSpecifiers(in value: String) -> [String] {
        let pattern = #"%(?:\d+\$)?(?:lld|ld|d|@)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap {
            Range($0.range, in: value).map { String(value[$0]) }
        }.sorted()
    }
}
