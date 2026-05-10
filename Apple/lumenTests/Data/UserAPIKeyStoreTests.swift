import Testing
@testable import lumen

@Suite("UserAPIKeyStore")
@MainActor
struct UserAPIKeyStoreTests {

    @Test("isValidKey accepts correct prefix for each provider")
    func isValidKeyAcceptsCorrectPrefix() {
        #expect(UserAPIKeyStore.isValidKey("sk-proj-abcdefghijklmnopqrstuv", for: .openai))
        #expect(UserAPIKeyStore.isValidKey("sk-ant-api03-abcdefghijklmnopqrstuv", for: .anthropic))
    }

    @Test("isValidKey rejects wrong prefix")
    func isValidKeyRejectsWrongPrefix() {
        #expect(!UserAPIKeyStore.isValidKey("xyz-not-a-key-1234567890", for: .openai))
        // Anthropic key fed to OpenAI provider should be rejected.
        #expect(!UserAPIKeyStore.isValidKey("sk-ant-api03-abcdefghijklmnopqrstuv", for: .openai))
    }

    @Test("isValidKey rejects too-short keys")
    func isValidKeyRejectsTooShort() {
        #expect(!UserAPIKeyStore.isValidKey("sk-short", for: .openai))
        #expect(!UserAPIKeyStore.isValidKey("", for: .openai))
    }

    @Test("mask hides the middle section of a key")
    func maskHidesMiddleSection() {
        let masked = UserAPIKeyStore.mask("sk-proj-7K2nP8mLqR4vXc9wA3bN6yE1fH5jD0sZ")
        #expect(masked.hasPrefix("sk-proj"))
        #expect(masked.hasSuffix("D0sZ"))
        #expect(masked.contains("•"))
    }
}
