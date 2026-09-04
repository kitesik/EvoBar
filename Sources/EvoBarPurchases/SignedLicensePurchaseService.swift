import AppKit
import CryptoKit
import EvoBarCore
import Foundation

public struct LicensePayload: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let licenseID: String
    public let appBundleID: String
    public let productIDs: Set<ProductID>
    public let issuedAt: Date
    public let expiresAt: Date?

    public init(
        schemaVersion: Int = 1,
        licenseID: String,
        appBundleID: String,
        productIDs: Set<ProductID>,
        issuedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.licenseID = licenseID
        self.appBundleID = appBundleID
        self.productIDs = productIDs
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }
}

public struct SignedLicenseEnvelope: Codable, Equatable, Sendable {
    public let payload: Data
    public let signature: Data

    public init(payload: Data, signature: Data) {
        self.payload = payload
        self.signature = signature
    }
}

public enum SignedLicenseError: Error, Equatable {
    case oversizedLicense
    case malformedEnvelope
    case invalidPublicKey
    case invalidSignature
    case unsupportedSchema
    case wrongApplication
    case invalidLicenseID
    case futureIssueDate
    case expired
    case unknownProductIDs(Set<ProductID>)
    case missingLicense
}

public struct SignedLicenseVerifier: Sendable {
    public static let supportedSchemaVersion = 1
    public static let maximumEnvelopeBytes = 1_048_576
    public static let maximumPayloadBytes = 65_536

    private let publicKeyData: Data
    private let appBundleID: String
    private let allowedProductIDs: Set<ProductID>
    private let maximumClockSkew: TimeInterval

    public init(
        publicKeyData: Data,
        appBundleID: String,
        allowedProductIDs: Set<ProductID>,
        maximumClockSkew: TimeInterval = 5 * 60
    ) {
        self.publicKeyData = publicKeyData
        self.appBundleID = appBundleID
        self.allowedProductIDs = allowedProductIDs
        self.maximumClockSkew = maximumClockSkew
    }

    public func verify(envelopeData: Data, now: Date = Date()) throws -> EntitlementSnapshot {
        guard envelopeData.count <= Self.maximumEnvelopeBytes else {
            throw SignedLicenseError.oversizedLicense
        }
        let envelope: SignedLicenseEnvelope
        do {
            envelope = try JSONDecoder().decode(SignedLicenseEnvelope.self, from: envelopeData)
        } catch {
            throw SignedLicenseError.malformedEnvelope
        }
        guard envelope.payload.count <= Self.maximumPayloadBytes else {
            throw SignedLicenseError.oversizedLicense
        }

        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        } catch {
            throw SignedLicenseError.invalidPublicKey
        }
        guard publicKey.isValidSignature(envelope.signature, for: envelope.payload) else {
            throw SignedLicenseError.invalidSignature
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload: LicensePayload
        do {
            payload = try decoder.decode(LicensePayload.self, from: envelope.payload)
        } catch {
            throw SignedLicenseError.malformedEnvelope
        }

        guard payload.schemaVersion == Self.supportedSchemaVersion else {
            throw SignedLicenseError.unsupportedSchema
        }
        guard payload.appBundleID == appBundleID else {
            throw SignedLicenseError.wrongApplication
        }
        guard !payload.licenseID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SignedLicenseError.invalidLicenseID
        }
        guard payload.issuedAt <= now.addingTimeInterval(maximumClockSkew) else {
            throw SignedLicenseError.futureIssueDate
        }
        if let expiresAt = payload.expiresAt, expiresAt <= now {
            throw SignedLicenseError.expired
        }
        let unknown = payload.productIDs.subtracting(allowedProductIDs)
        guard unknown.isEmpty else {
            throw SignedLicenseError.unknownProductIDs(unknown)
        }

        return EntitlementSnapshot(activeProductIDs: payload.productIDs, capturedAt: now)
    }
}

public protocol LicenseStoring: Sendable {
    func load() async throws -> Data?
    func save(_ data: Data) async throws
}

public actor FileLicenseStore: LicenseStoring {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let size = attributes[.size] as? NSNumber,
           size.intValue > SignedLicenseVerifier.maximumEnvelopeBytes {
            throw SignedLicenseError.oversizedLicense
        }
        return try Data(contentsOf: fileURL)
    }

    public func save(_ data: Data) throws {
        guard data.count <= SignedLicenseVerifier.maximumEnvelopeBytes else {
            throw SignedLicenseError.oversizedLicense
        }
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }
}

public protocol PurchaseLinkOpening: Sendable {
    func open(_ url: URL) async -> Bool
}

public struct SystemPurchaseLinkOpener: PurchaseLinkOpening {
    public init() {}

    public func open(_ url: URL) async -> Bool {
        await MainActor.run { NSWorkspace.shared.open(url) }
    }
}

public actor SignedLicensePurchaseService: PurchaseService {
    private let storefront: StorefrontManifest
    private let verifier: SignedLicenseVerifier
    private let licenseStore: any LicenseStoring
    private let checkoutBaseURL: URL
    private let linkOpener: any PurchaseLinkOpening
    private var continuation: AsyncStream<PurchaseEvent>.Continuation?

    public init(
        storefront: StorefrontManifest,
        publicKeyData: Data,
        appBundleID: String,
        licenseStore: any LicenseStoring,
        checkoutBaseURL: URL,
        linkOpener: any PurchaseLinkOpening = SystemPurchaseLinkOpener()
    ) {
        self.storefront = storefront
        self.verifier = SignedLicenseVerifier(
            publicKeyData: publicKeyData,
            appBundleID: appBundleID,
            allowedProductIDs: Set(storefront.products.map(\.id))
        )
        self.licenseStore = licenseStore
        self.checkoutBaseURL = checkoutBaseURL
        self.linkOpener = linkOpener
    }

    public func events() -> AsyncStream<PurchaseEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    public func products(for ids: Set<ProductID>) -> [StoreProduct] {
        storefront.products
            .filter { ids.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                StoreProduct(
                    id: $0.id,
                    displayName: $0.fallbackName,
                    displayPrice: "$\($0.fallbackPriceUSD)",
                    kind: $0.kind
                )
            }
    }

    public func purchase(_ productID: ProductID) async -> PurchaseResult {
        guard storefront.products.contains(where: { $0.id == productID }) else {
            return .failed(code: "unknown_product")
        }
        guard let url = checkoutURL(for: productID), await linkOpener.open(url) else {
            return .failed(code: "checkout_unavailable")
        }
        return .pending(productID)
    }

    public func restorePurchases() async throws -> EntitlementSnapshot {
        try await currentEntitlements()
    }

    public func currentEntitlements() async throws -> EntitlementSnapshot {
        guard let data = try await licenseStore.load() else {
            return EntitlementSnapshot(activeProductIDs: [])
        }
        return try verifier.verify(envelopeData: data)
    }

    @discardableResult
    public func importLicense(_ data: Data, now: Date = Date()) async throws -> EntitlementSnapshot {
        let entitlements = try verifier.verify(envelopeData: data, now: now)
        try await licenseStore.save(data)
        continuation?.yield(.entitlementsChanged)
        return entitlements
    }

    private func checkoutURL(for productID: ProductID) -> URL? {
        guard checkoutBaseURL.scheme?.lowercased() == "https",
              var components = URLComponents(url: checkoutBaseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "product_id", value: productID.rawValue))
        items.append(URLQueryItem(name: "source", value: "evobar"))
        components.queryItems = items
        return components.url
    }
}
