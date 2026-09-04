import CryptoKit
import EvoBarCore
import EvoBarPurchases
import Foundation
import Testing

@Suite struct PurchaseTests {
    @Test func individualBundleAndAllEntitlements() throws {
        let storefront = try ManifestLoader.bundledStorefront()
        let individual = EntitlementResolver.resolve(
            starterGrant: "cat",
            snapshot: EntitlementSnapshot(activeProductIDs: ["evobar.animal.fox"]),
            storefront: storefront
        )
        #expect(individual.ownedAnimalIDs == ["cat", "fox"])
        let bundle = EntitlementResolver.resolve(
            starterGrant: "cat",
            snapshot: EntitlementSnapshot(activeProductIDs: ["evobar.bundle.forest"]),
            storefront: storefront
        )
        #expect(bundle.ownedAnimalIDs.isSuperset(of: ["cat", "fox", "red-panda", "raven"]))
        let all = EntitlementResolver.resolve(
            starterGrant: nil,
            snapshot: EntitlementSnapshot(activeProductIDs: ["evobar.all-animals"]),
            storefront: storefront
        )
        #expect(all.ownedAnimalIDs.count == 10)
    }

    @Test func mockPurchaseScenarios() async throws {
        let service = MockPurchaseService(storefront: try ManifestLoader.bundledStorefront())
        #expect(await service.purchase("evobar.animal.otter") == .purchased("evobar.animal.otter"))
        #expect(try await service.currentEntitlements().activeProductIDs.contains("evobar.animal.otter"))
        await service.setScenario(.userCancelled)
        #expect(await service.purchase("evobar.animal.fox") == .userCancelled)
        await service.setScenario(.failed(code: "declined"))
        #expect(await service.purchase("evobar.animal.fox") == .failed(code: "declined"))
    }

    @Test func signedLicenseAcceptsOnlyAuthenticKnownEntitlements() throws {
        let storefront = try ManifestLoader.bundledStorefront()
        let privateKey = Curve25519.Signing.PrivateKey()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let verifier = SignedLicenseVerifier(
            publicKeyData: privateKey.publicKey.rawRepresentation,
            appBundleID: "com.evobar.app",
            allowedProductIDs: Set(storefront.products.map(\.id))
        )
        let payload = LicensePayload(
            licenseID: "license-test-1",
            appBundleID: "com.evobar.app",
            productIDs: ["evobar.animal.fox", "evobar.bundle.waterside"],
            issuedAt: now.addingTimeInterval(-60)
        )
        let data = try signedEnvelope(payload: payload, privateKey: privateKey)

        let snapshot = try verifier.verify(envelopeData: data, now: now)
        #expect(snapshot.activeProductIDs == payload.productIDs)

        let envelope = try JSONDecoder().decode(SignedLicenseEnvelope.self, from: data)
        var tamperedPayload = envelope.payload
        tamperedPayload.append(0)
        let tampered = try JSONEncoder().encode(
            SignedLicenseEnvelope(payload: tamperedPayload, signature: envelope.signature)
        )
        #expect(throws: SignedLicenseError.invalidSignature) {
            try verifier.verify(envelopeData: tampered, now: now)
        }
        #expect(throws: SignedLicenseError.oversizedLicense) {
            try verifier.verify(
                envelopeData: Data(count: SignedLicenseVerifier.maximumEnvelopeBytes + 1),
                now: now
            )
        }
    }

    @Test func signedLicenseRejectsWrongAppExpiryFutureDatesAndUnknownProducts() throws {
        let storefront = try ManifestLoader.bundledStorefront()
        let privateKey = Curve25519.Signing.PrivateKey()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let verifier = SignedLicenseVerifier(
            publicKeyData: privateKey.publicKey.rawRepresentation,
            appBundleID: "com.evobar.app",
            allowedProductIDs: Set(storefront.products.map(\.id))
        )

        let cases: [(LicensePayload, SignedLicenseError)] = [
            (
                LicensePayload(
                    licenseID: "wrong-app",
                    appBundleID: "com.example.other",
                    productIDs: ["evobar.animal.fox"],
                    issuedAt: now
                ),
                .wrongApplication
            ),
            (
                LicensePayload(
                    licenseID: "expired",
                    appBundleID: "com.evobar.app",
                    productIDs: ["evobar.animal.fox"],
                    issuedAt: now.addingTimeInterval(-3_600),
                    expiresAt: now
                ),
                .expired
            ),
            (
                LicensePayload(
                    licenseID: "future",
                    appBundleID: "com.evobar.app",
                    productIDs: ["evobar.animal.fox"],
                    issuedAt: now.addingTimeInterval(301)
                ),
                .futureIssueDate
            ),
            (
                LicensePayload(
                    licenseID: "unknown-product",
                    appBundleID: "com.evobar.app",
                    productIDs: ["evobar.fake.product"],
                    issuedAt: now
                ),
                .unknownProductIDs(["evobar.fake.product"])
            ),
        ]

        for (payload, expectedError) in cases {
            let data = try signedEnvelope(payload: payload, privateKey: privateKey)
            #expect(throws: expectedError) {
                try verifier.verify(envelopeData: data, now: now)
            }
        }
    }

    @Test func signedLicenseServiceOpensCheckoutAndPersistsVerifiedLicense() async throws {
        let storefront = try ManifestLoader.bundledStorefront()
        let privateKey = Curve25519.Signing.PrivateKey()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = TestLicenseStore()
        let opener = TestPurchaseLinkOpener()
        let service = SignedLicensePurchaseService(
            storefront: storefront,
            publicKeyData: privateKey.publicKey.rawRepresentation,
            appBundleID: "com.evobar.app",
            licenseStore: store,
            checkoutBaseURL: URL(string: "https://store.example.test/checkout?campaign=launch")!,
            linkOpener: opener
        )

        #expect(await service.purchase("evobar.animal.fox") == .pending("evobar.animal.fox"))
        let openedURL = try #require(await opener.lastOpenedURL())
        let components = try #require(URLComponents(url: openedURL, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.contains(URLQueryItem(name: "campaign", value: "launch")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "product_id", value: "evobar.animal.fox")) == true)

        let insecureService = SignedLicensePurchaseService(
            storefront: storefront,
            publicKeyData: privateKey.publicKey.rawRepresentation,
            appBundleID: "com.evobar.app",
            licenseStore: store,
            checkoutBaseURL: URL(string: "http://store.example.test/checkout")!,
            linkOpener: opener
        )
        #expect(await insecureService.purchase("evobar.animal.fox") == .failed(code: "checkout_unavailable"))

        let payload = LicensePayload(
            licenseID: "license-test-service",
            appBundleID: "com.evobar.app",
            productIDs: ["evobar.animal.fox"],
            issuedAt: now
        )
        let data = try signedEnvelope(payload: payload, privateKey: privateKey)
        let imported = try await service.importLicense(data, now: now)
        #expect(imported.activeProductIDs == ["evobar.animal.fox"])
        #expect(await store.load() == data)
    }

    private func signedEnvelope(
        payload: LicensePayload,
        privateKey: Curve25519.Signing.PrivateKey
    ) throws -> Data {
        let payloadEncoder = JSONEncoder()
        payloadEncoder.dateEncodingStrategy = .iso8601
        payloadEncoder.outputFormatting = [.sortedKeys]
        let payloadData = try payloadEncoder.encode(payload)
        let signature = try privateKey.signature(for: payloadData)
        return try JSONEncoder().encode(
            SignedLicenseEnvelope(payload: payloadData, signature: signature)
        )
    }
}

private actor TestLicenseStore: LicenseStoring {
    private var data: Data?

    func load() -> Data? { data }
    func save(_ data: Data) { self.data = data }
}

private actor TestPurchaseLinkOpener: PurchaseLinkOpening {
    private var url: URL?

    func open(_ url: URL) -> Bool {
        self.url = url
        return true
    }

    func lastOpenedURL() -> URL? { url }
}
