import XCTest
@testable import lumen

final class APIKeyResolverTests: XCTestCase {
    override func setUp() {
        super.setUp()
        APIKeyResolver._resetUserKeysForTesting()
    }

    override func tearDown() {
        APIKeyResolver._resetUserKeysForTesting()
        super.tearDown()
    }

    func testUserKeyTakesPrecedenceOverBundleKey() throws {
        // The user-configured key should always win over the build-time
        // Info.plist value, regardless of whether the host bundle has a key.
        APIKeyResolver.setUserKey("sk-proj-USER-OVERRIDE-1234567", for: .openai)
        let resolved = try APIKeyResolver.resolve(infoKey: "OPENAI_API_KEY")
        XCTAssertEqual(resolved, "sk-proj-USER-OVERRIDE-1234567")
    }

    func testUserKeyDoesNotBleedAcrossProviders() throws {
        // Setting an OpenAI user key must not affect the Anthropic resolution path.
        APIKeyResolver.setUserKey("sk-proj-OPENAI-USER-1234567", for: .openai)

        // Whatever Anthropic returns (real bundle key or `missingAPIKey` throw),
        // it must NOT be the OpenAI user key.
        do {
            let anthropic = try APIKeyResolver.resolve(infoKey: "ANTHROPIC_API_KEY")
            XCTAssertNotEqual(anthropic, "sk-proj-OPENAI-USER-1234567")
        } catch {
            // Throwing missingAPIKey when there's no Anthropic key anywhere is fine.
            guard case AIError.missingAPIKey = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func testClearUserKey() throws {
        APIKeyResolver.setUserKey("sk-proj-USER-1234567", for: .openai)
        APIKeyResolver.setUserKey(nil, for: .openai)

        // After clearing, resolution falls back to the bundle key (if present)
        // or throws missingAPIKey. Either way it must NOT return the user key.
        do {
            let resolved = try APIKeyResolver.resolve(infoKey: "OPENAI_API_KEY")
            XCTAssertNotEqual(resolved, "sk-proj-USER-1234567")
        } catch AIError.missingAPIKey {
            // OK — bundle has no key either, expected fallback.
        }
    }
}
