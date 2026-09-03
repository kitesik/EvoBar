import EvoBarCore
import Foundation

public enum MockPurchaseScenario: Equatable, Sendable {
    case success
    case userCancelled
    case failed(code: String)
    case pending
    case offline
}

public enum MockPurchaseError: Error, Equatable {
    case offline
}

public actor MockPurchaseService: PurchaseService {
    private let storefront: StorefrontManifest
    private var scenario: MockPurchaseScenario
    private var activeProductIDs: Set<ProductID>
    private var continuation: AsyncStream<PurchaseEvent>.Continuation?

    public init(
        storefront: StorefrontManifest,
        scenario: MockPurchaseScenario = .success,
        activeProductIDs: Set<ProductID> = []
    ) {
        self.storefront = storefront
        self.scenario = scenario
        self.activeProductIDs = activeProductIDs
    }

    public func setScenario(_ scenario: MockPurchaseScenario) {
        self.scenario = scenario
    }

    public func events() -> AsyncStream<PurchaseEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    public func products(for ids: Set<ProductID>) throws -> [StoreProduct] {
        if scenario == .offline { throw MockPurchaseError.offline }
        return storefront.products
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

    public func purchase(_ productID: ProductID) -> PurchaseResult {
        switch scenario {
        case .success:
            activeProductIDs.insert(productID)
            continuation?.yield(.entitlementsChanged)
            return .purchased(productID)
        case .userCancelled:
            return .userCancelled
        case .failed(let code):
            return .failed(code: code)
        case .pending:
            return .pending(productID)
        case .offline:
            return .failed(code: "offline")
        }
    }

    public func restorePurchases() throws -> EntitlementSnapshot {
        if scenario == .offline { throw MockPurchaseError.offline }
        continuation?.yield(.entitlementsChanged)
        return EntitlementSnapshot(activeProductIDs: activeProductIDs)
    }

    public func currentEntitlements() throws -> EntitlementSnapshot {
        if scenario == .offline { throw MockPurchaseError.offline }
        return EntitlementSnapshot(activeProductIDs: activeProductIDs)
    }

    public func revoke(_ productID: ProductID) {
        activeProductIDs.remove(productID)
        continuation?.yield(.productRevoked(productID))
    }
}
