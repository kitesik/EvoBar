import Foundation

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
        return configuration
    }
}

enum AppConfigurationError: Error {
    case missingResource
    case unsupportedSchema
}
