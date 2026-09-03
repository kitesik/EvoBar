import EvoBarCore
import Foundation

public actor DisabledPurchaseService: PurchaseService {
    public init() {}

    public func events() -> AsyncStream<PurchaseEvent> {
        AsyncStream { $0.finish() }
    }

    public func products(for ids: Set<ProductID>) -> [StoreProduct] { [] }
    public func purchase(_ productID: ProductID) -> PurchaseResult { .failed(code: "unavailable") }
    public func restorePurchases() -> EntitlementSnapshot { EntitlementSnapshot(activeProductIDs: []) }
    public func currentEntitlements() -> EntitlementSnapshot { EntitlementSnapshot(activeProductIDs: []) }
}
