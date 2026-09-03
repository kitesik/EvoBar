import EvoBarCore
import Foundation

public struct StoreProduct: Equatable, Identifiable, Sendable {
    public let id: ProductID
    public let displayName: String
    public let displayPrice: String
    public let kind: StoreProductKind
}

public enum PurchaseResult: Equatable, Sendable {
    case purchased(ProductID)
    case pending(ProductID)
    case userCancelled
    case failed(code: String)
}

public enum PurchaseEvent: Equatable, Sendable {
    case entitlementsChanged
    case productRevoked(ProductID)
}

public struct EntitlementSnapshot: Equatable, Sendable {
    public let activeProductIDs: Set<ProductID>
    public let capturedAt: Date

    public init(activeProductIDs: Set<ProductID>, capturedAt: Date = Date()) {
        self.activeProductIDs = activeProductIDs
        self.capturedAt = capturedAt
    }
}

public protocol PurchaseService: Sendable {
    func events() async -> AsyncStream<PurchaseEvent>
    func products(for ids: Set<ProductID>) async throws -> [StoreProduct]
    func purchase(_ productID: ProductID) async -> PurchaseResult
    func restorePurchases() async throws -> EntitlementSnapshot
    func currentEntitlements() async throws -> EntitlementSnapshot
}
