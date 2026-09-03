import EvoBarCore
import EvoBarPurchases
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
}
