import Foundation

struct AppRuntimeEnvironment: Equatable {
    let smokeTestOutputURL: URL?

    var isSmokeTesting: Bool { smokeTestOutputURL != nil }

    var storeURL: URL? {
        smokeTestOutputURL?
            .deletingLastPathComponent()
            .appendingPathComponent("state", isDirectory: true)
            .appendingPathComponent("EvoBar-v1.json")
    }

    var licenseURL: URL? {
        smokeTestOutputURL?
            .deletingLastPathComponent()
            .appendingPathComponent("state", isDirectory: true)
            .appendingPathComponent("license.v1.json")
    }

    static var current: AppRuntimeEnvironment {
        let value = ProcessInfo.processInfo.environment["EVOBAR_SMOKE_TEST_OUTPUT"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.hasPrefix("/"), value != "/" else {
            return AppRuntimeEnvironment(smokeTestOutputURL: nil)
        }
        return AppRuntimeEnvironment(
            smokeTestOutputURL: URL(fileURLWithPath: value).standardizedFileURL
        )
    }
}

struct AppConfiguration: Decodable {
    struct SignedLicenseConfiguration: Decodable {
        let checkoutURL: URL
        let publicKeyBase64: String

        var publicKeyData: Data? {
            guard checkoutURL.scheme?.lowercased() == "https",
                  let data = Data(base64Encoded: publicKeyBase64),
                  data.count == 32 else {
                return nil
            }
            return data
        }
    }

    let schemaVersion: Int
    let distribution: String
    let storefront: String
    let signedLicense: SignedLicenseConfiguration?

    static func bundled() throws -> AppConfiguration {
        guard let url = Bundle.module.url(forResource: "app-config", withExtension: "json") else {
            throw AppConfigurationError.missingResource
        }
        let configuration = try JSONDecoder().decode(
            AppConfiguration.self,
            from: Data(contentsOf: url)
        )
        guard configuration.schemaVersion == 1 else {
            throw AppConfigurationError.unsupportedSchema
        }
        guard configuration.distribution == "direct" else {
            throw AppConfigurationError.unsupportedDistribution
        }
        switch configuration.storefront {
        case "mock-debug":
            guard configuration.signedLicense == nil else {
                throw AppConfigurationError.invalidStorefront
            }
        case "signed-license":
            guard configuration.signedLicense?.publicKeyData != nil else {
                throw AppConfigurationError.invalidStorefront
            }
        default:
            throw AppConfigurationError.invalidStorefront
        }
        return configuration
    }
}

enum AppConfigurationError: Error {
    case missingResource
    case unsupportedSchema
    case unsupportedDistribution
    case invalidStorefront
}
