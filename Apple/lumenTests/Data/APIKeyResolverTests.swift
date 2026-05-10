import Testing
@testable import lumen

@Suite("APIKeyResolver")
struct APIKeyResolverTests {

    init() async throws {
        await APIKeyResolver._resetUserKeysForTesting()
    }

    @Test("user key takes precedence over bundle key")
    func userKeyTakesPrecedenceOverBundleKey() async throws {
        // The user-configured key should always win over the build-time
        // Info.plist value, regardless of whether the host bundle has a key.
        await APIKeyResolver.setUserKey("sk-proj-USER-OVERRIDE-1234567", for: .openai)
        let resolved = try await APIKeyResolver.resolve(infoKey: "OPENAI_API_KEY")
        #expect(resolved == "sk-proj-USER-OVERRIDE-1234567")
        await APIKeyResolver._resetUserKeysForTesting()
    }

    @Test("user key does not bleed across providers")
    func userKeyDoesNotBleedAcrossProviders() async throws {
        // Setting an OpenAI user key must not affect the Anthropic resolution path.
        await APIKeyResolver.setUserKey("sk-proj-OPENAI-USER-1234567", for: .openai)

        // Whatever Anthropic returns (real bundle key or `missingAPIKey` throw),
        // it must NOT be the OpenAI user key.
        do {
            let anthropic = try await APIKeyResolver.resolve(infoKey: "ANTHROPIC_API_KEY")
            #expect(anthropic != "sk-proj-OPENAI-USER-1234567")
        } catch {
            // Throwing missingAPIKey when there's no Anthropic key anywhere is fine.
            guard case AIError.missingAPIKey = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
        await APIKeyResolver._resetUserKeysForTesting()
    }

    @Test("clearing user key falls back to bundle key or throws")
    func clearUserKey() async throws {
        await APIKeyResolver.setUserKey("sk-proj-USER-1234567", for: .openai)
        await APIKeyResolver.setUserKey(nil, for: .openai)

        // After clearing, resolution falls back to the bundle key (if present)
        // or throws missingAPIKey. Either way it must NOT return the user key.
        do {
            let resolved = try await APIKeyResolver.resolve(infoKey: "OPENAI_API_KEY")
            #expect(resolved != "sk-proj-USER-1234567")
        } catch AIError.missingAPIKey {
            // OK — bundle has no key either, expected fallback.
        }
        await APIKeyResolver._resetUserKeysForTesting()
    }
}
