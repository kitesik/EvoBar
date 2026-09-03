import EvoBarInfrastructure
import Foundation
import Testing

@Suite struct CredentialStoreContractTests {
    @Test func inMemoryContractReplacesAndDeletesOpaqueData() async throws {
        let store: any CredentialStore = MemoryCredentialStore()
        let key = CredentialKey(service: "com.evobar.tests", account: "provider")
        #expect(try await store.data(for: key) == nil)
        try await store.save(Data("first".utf8), for: key)
        #expect(try await store.data(for: key) == Data("first".utf8))
        try await store.save(Data("second".utf8), for: key)
        #expect(try await store.data(for: key) == Data("second".utf8))
        try await store.delete(key)
        #expect(try await store.data(for: key) == nil)
    }
}

private actor MemoryCredentialStore: CredentialStore {
    private var values: [CredentialKey: Data] = [:]

    func data(for key: CredentialKey) -> Data? { values[key] }
    func save(_ data: Data, for key: CredentialKey) { values[key] = data }
    func delete(_ key: CredentialKey) { values[key] = nil }
}
