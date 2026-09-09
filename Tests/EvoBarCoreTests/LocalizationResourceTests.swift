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

    @Test func staticSwiftUIStringsArePresentInLocalizationCatalog() throws {
        let catalog = try loadCatalog(locale: "en")
        let appSources = repositoryRoot.appendingPathComponent("Sources/EvoBarApp", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(
            at: appSources,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "swift" }
        var keys: Set<String> = []
        for file in files {
            keys.formUnion(try Self.staticUIStrings(in: try String(contentsOf: file, encoding: .utf8)))
        }

        let missing = keys.subtracting(catalog.keys).sorted()
        #expect(missing.isEmpty, "Missing localization keys: \(missing.joined(separator: " | "))")
    }

    /// The scanner must read view initializers, not any identifier that happens
    /// to end in one of their names: a test harness calling `insertText("...")`
    /// is not a `Text` literal.
    @Test func staticStringScannerStopsAtIdentifierBoundaries() throws {
        let source = #"""
        Text("Meet EvoBar")
        TextField("Companion name", text: $name)
        Button("Check again") { model.detectProviders() }
        .help("Open official status page")
        editor.insertText("evobar-fixture-search-no-match", replacementRange: range)
        myLabel("not a view")
        Text("\(interpolated) value")
        Text("12:00")
        """#
        let keys = try Self.staticUIStrings(in: source)
        #expect(keys == ["Meet EvoBar", "Companion name", "Check again", "Open official status page"])
    }

    /// Literal first arguments of SwiftUI views and modifiers that localize
    /// their string as a key. Interpolations and letterless strings are skipped.
    private static func staticUIStrings(in source: String) throws -> Set<String> {
        let pattern = #"(?<![A-Za-z0-9_])(?:Text|Label|Button|Toggle|Picker|Section|Link|ContentUnavailableView|TextField|help|alert)\(\s*\"((?:\\.|[^\"\\])*)\""#
        let regex = try NSRegularExpression(pattern: pattern)
        var keys: Set<String> = []
        let range = NSRange(source.startIndex..., in: source)
        for match in regex.matches(in: source, range: range) {
            guard let capture = Range(match.range(at: 1), in: source) else { continue }
            let key = String(source[capture])
            guard !key.contains(#"\("#), key.unicodeScalars.contains(where: CharacterSet.letters.contains) else {
                continue
            }
            keys.insert(key)
        }
        return keys
    }

    @Test func redesignedUIKeysAreLocalizedAndRespectCopyStyle() throws {
        let catalog = try loadCatalog(locale: "en")
        let appSources = repositoryRoot.appendingPathComponent("Sources/EvoBarApp")
        let files = try FileManager.default.contentsOfDirectory(at: appSources, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        let pattern = #"L10n\.(?:text|format)\(\s*"(ui\.[^"]+)""#
        let regex = try NSRegularExpression(pattern: pattern)
        var keys: Set<String> = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            for match in regex.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                if let range = Range(match.range(at: 1), in: source) { keys.insert(String(source[range])) }
            }
        }
        #expect(keys.count >= 40)
        #expect(keys.subtracting(catalog.keys).isEmpty)
        for locale in locales {
            let translations = try loadCatalog(locale: locale)
            for key in keys {
                let value = try #require(translations[key])
                #expect(!value.isEmpty)
                #expect(!value.contains(" · "))
            }
        }
    }

    @Test func directDistributionStorefrontConfigurationIsSafe() throws {
        let url = repositoryRoot
            .appendingPathComponent("Sources/EvoBarApp/Resources/app-config.json")
        let object = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        )
        #expect(object["schemaVersion"] as? Int == 1)
        #expect(object["distribution"] as? String == "direct")
        let storefront = try #require(object["storefront"] as? String)
        #expect(["mock-debug", "signed-license"].contains(storefront))

        if storefront == "signed-license" {
            let license = try #require(object["signedLicense"] as? [String: Any])
            let checkout = try #require(URL(string: license["checkoutURL"] as? String ?? ""))
            #expect(checkout.scheme == "https")
            let key = try #require(Data(base64Encoded: license["publicKeyBase64"] as? String ?? ""))
            #expect(key.count == 32)
        } else {
            #expect((object["signedLicense"] as? NSNull) != nil)
        }
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func loadCatalog(locale: String) throws -> [String: String] {
        let url = repositoryRoot
            .appendingPathComponent("Sources/EvoBarApp/Resources/\(locale).lproj/Localizable.strings")
        let data = try Data(contentsOf: url)
        return try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        )
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
