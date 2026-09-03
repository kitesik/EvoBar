import EvoBarCore
import Foundation

public struct ResolvedEntitlements: Equatable, Sendable {
    public let ownedAnimalIDs: Set<AnimalDefinitionID>
    public let activeProductIDs: Set<ProductID>

    public func owns(_ animalID: AnimalDefinitionID) -> Bool {
        ownedAnimalIDs.contains(animalID)
    }
}

public enum EntitlementResolver {
    public static func resolve(
        starterGrant: AnimalDefinitionID?,
        snapshot: EntitlementSnapshot,
        storefront: StorefrontManifest
    ) -> ResolvedEntitlements {
        var animalIDs = Set<AnimalDefinitionID>()
        if let starterGrant { animalIDs.insert(starterGrant) }
        for product in storefront.products where snapshot.activeProductIDs.contains(product.id) {
            animalIDs.formUnion(product.grantsAnimalIDs)
        }
        return ResolvedEntitlements(
            ownedAnimalIDs: animalIDs,
            activeProductIDs: snapshot.activeProductIDs
        )
    }
}
