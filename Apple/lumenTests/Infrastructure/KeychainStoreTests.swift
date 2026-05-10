import Foundation
import Testing
@testable import lumen

@Suite("KeychainStore")
struct KeychainStoreTests {
    private let store: KeychainStore
    private let account: String

    init() async throws {
        store = KeychainStore(service: "com.lumen.morning.tests")
        account = "lumen-test-key-\(UUID().uuidString)"
        // Best effort cleanup of any leftover from a previous run.
        try? await store.delete(account: account)
    }

    @Test("save / read / delete round-trip")
    func saveReadDeleteRoundTrip() async throws {
        defer { Task { try? await store.delete(account: account) } }

        // Initial read returns nil
        let initial = try await store.read(account: account)
        #expect(initial == nil)

        // Save
        try await store.save(account: account, value: "sk-proj-VALID-TEST-KEY-xyz")
        let stored = try await store.read(account: account)
        #expect(stored == "sk-proj-VALID-TEST-KEY-xyz")

        // Update overwrites
        try await store.save(account: account, value: "sk-proj-OVERWRITE-KEY-xyz")
        let updated = try await store.read(account: account)
        #expect(updated == "sk-proj-OVERWRITE-KEY-xyz")

        // Delete clears
        try await store.delete(account: account)
        let cleared = try await store.read(account: account)
        #expect(cleared == nil)
    }

    @Test("deleting a missing item does not throw")
    func deleteMissingItemDoesNotThrow() async throws {
        try await store.delete(account: "nonexistent-account-\(UUID().uuidString)")
    }
}
