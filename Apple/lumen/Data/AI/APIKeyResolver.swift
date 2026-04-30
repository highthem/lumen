import Foundation

/// Resolves AI provider API keys with BYOK precedence.
///
/// Order:
/// 1. User key snapshot (mirrored from Keychain via `setUserKey`),
///    when its provider matches the requested provider.
/// 2. Build-time key from `Secrets.xcconfig` via `Bundle.main.object(forInfoDictionaryKey:)`.
///
/// All entry points are `nonisolated` so the AI clients (which run on
/// background tasks) can resolve keys without main-actor hops.
nonisolated enum APIKeyResolver {
    /// Provider identifiers used to scope the user key lookup.
    enum Provider: String, Sendable {
        case openai
        case anthropic
    }

    // Lock-protected snapshot accessed from any thread.
    private static let lock = NSLock()
    nonisolated(unsafe) private static var userKeys: [Provider: String] = [:]

    /// Mirror the Keychain value for `provider`. Pass nil to clear.
    static func setUserKey(_ key: String?, for provider: Provider) {
        lock.lock()
        defer { lock.unlock() }
        if let key {
            userKeys[provider] = key
        } else {
            userKeys.removeValue(forKey: provider)
        }
    }

    static func resolve(infoKey: String) throws -> String {
        if let provider = providerFor(infoKey: infoKey),
           let userKey = userKey(for: provider),
           isValid(userKey) {
            return userKey
        }
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            throw AIError.missingAPIKey
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid(key) else {
            throw AIError.missingAPIKey
        }
        return key
    }

    static func isPresent(infoKey: String) -> Bool {
        if let provider = providerFor(infoKey: infoKey),
           let userKey = userKey(for: provider),
           isValid(userKey) {
            return true
        }
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            return false
        }
        return isValid(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Test seam — clear the in-process user key snapshot.
    static func _resetUserKeysForTesting() {
        lock.lock()
        defer { lock.unlock() }
        userKeys.removeAll()
    }

    // MARK: - Helpers

    private static func providerFor(infoKey: String) -> Provider? {
        switch infoKey {
        case "OPENAI_API_KEY": .openai
        case "ANTHROPIC_API_KEY": .anthropic
        default: nil
        }
    }

    private static func userKey(for provider: Provider) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return userKeys[provider]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isValid(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        if key.hasPrefix("REPLACE_ME") { return false }
        if key.hasPrefix("$(") { return false }
        if key == "MISSING_IN_CI" { return false }
        return true
    }
}
