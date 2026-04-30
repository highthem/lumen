import XCTest
@testable import lumen

@MainActor
final class UserAPIKeyStoreTests: XCTestCase {
    func testIsValidKeyAcceptsCorrectPrefix() {
        XCTAssertTrue(UserAPIKeyStore.isValidKey("sk-proj-abcdefghijklmnopqrstuv", for: .openai))
        XCTAssertTrue(UserAPIKeyStore.isValidKey("sk-ant-api03-abcdefghijklmnopqrstuv", for: .anthropic))
    }

    func testIsValidKeyRejectsWrongPrefix() {
        XCTAssertFalse(UserAPIKeyStore.isValidKey("xyz-not-a-key-1234567890", for: .openai))
        // Anthropic key fed to OpenAI provider should be rejected.
        XCTAssertFalse(UserAPIKeyStore.isValidKey("sk-ant-api03-abcdefghijklmnopqrstuv", for: .openai))
    }

    func testIsValidKeyRejectsTooShort() {
        XCTAssertFalse(UserAPIKeyStore.isValidKey("sk-short", for: .openai))
        XCTAssertFalse(UserAPIKeyStore.isValidKey("", for: .openai))
    }

    func testMaskHidesMiddleSection() {
        let masked = UserAPIKeyStore.mask("sk-proj-7K2nP8mLqR4vXc9wA3bN6yE1fH5jD0sZ")
        XCTAssertTrue(masked.hasPrefix("sk-proj"))
        XCTAssertTrue(masked.hasSuffix("D0sZ"))
        XCTAssertTrue(masked.contains("•"))
    }
}
