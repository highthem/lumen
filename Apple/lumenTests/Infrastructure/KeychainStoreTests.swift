import XCTest
@testable import lumen

final class KeychainStoreTests: XCTestCase {
    private var store: KeychainStore!
    private let account = "lumen-test-key-\(UUID().uuidString)"

    override func setUp() async throws {
        try await super.setUp()
        store = KeychainStore(service: "com.lumen.morning.tests")
        // Best effort cleanup of any leftover from a previous run.
        try? await store.delete(account: account)
    }

    override func tearDown() async throws {
        try? await store.delete(account: account)
        try await super.tearDown()
    }

    func testSaveReadDeleteRoundTrip() async throws {
        // Initial read returns nil
        let initial = try await store.read(account: account)
        XCTAssertNil(initial)

        // Save
        try await store.save(account: account, value: "sk-proj-VALID-TEST-KEY-xyz")
        let stored = try await store.read(account: account)
        XCTAssertEqual(stored, "sk-proj-VALID-TEST-KEY-xyz")

        // Update overwrites
        try await store.save(account: account, value: "sk-proj-OVERWRITE-KEY-xyz")
        let updated = try await store.read(account: account)
        XCTAssertEqual(updated, "sk-proj-OVERWRITE-KEY-xyz")

        // Delete clears
        try await store.delete(account: account)
        let cleared = try await store.read(account: account)
        XCTAssertNil(cleared)
    }

    func testDeleteMissingItemDoesNotThrow() async throws {
        try await store.delete(account: "nonexistent-account-\(UUID().uuidString)")
    }
}
