import Foundation

/// Resolves AI provider API keys with BYOK precedence.
///
/// Order:
/// 1. User key snapshot (mirrored from Keychain via `setUserKey`),
///    when its provider matches the requested provider.
/// 2. Build-time key from `Secrets.xcconfig` via `Bundle.main.object(forInfoDictionaryKey:)`.
///
/// User-key access goes through a private actor singleton so we never need
/// a lock. Bundle-only paths are sync — the bundle plist is read-only and
/// thread-safe — so MainActor `init` callsites can resolve them without `await`.
enum APIKeyResolver {
    /// Provider identifiers used to scope the user key lookup.
    enum Provider: String, Sendable {
        case openai
        case anthropic
        case elevenlabs
    }

    private actor Storage {
        var userKeys: [Provider: String] = [:]

        func set(_ key: String?, for provider: Provider) {
            if let key {
                userKeys[provider] = key
            } else {
                userKeys.removeValue(forKey: provider)
            }
        }

        func userKey(for provider: Provider) -> String? {
            userKeys[provider]?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func reset() { userKeys.removeAll() }
    }

    private static let storage = Storage()

    /// Mirror the Keychain value for `provider`. Pass nil to clear.
    static func setUserKey(_ key: String?, for provider: Provider) async {
        await storage.set(key, for: provider)
    }

    /// User-key-aware lookup. Falls back to bundle plist.
    static func resolve(infoKey: String) async throws -> String {
        if let provider = providerFor(infoKey: infoKey),
           let userKey = await storage.userKey(for: provider),
           isValid(userKey) {
            return userKey
        }
        return try resolveBundleOnly(infoKey: infoKey)
    }

    /// User-key-aware presence check. Falls back to bundle plist.
    static func isPresent(infoKey: String) async -> Bool {
        if let provider = providerFor(infoKey: infoKey),
           let userKey = await storage.userKey(for: provider),
           isValid(userKey) {
            return true
        }
        return isPresentInBundle(infoKey: infoKey)
    }

    /// Sync, bundle-only lookup. For sync init paths that cannot await
    /// (e.g. CompositionRoot.init building TTS at app launch).
    /// Cannot see user-overridden keys.
    static func resolveBundleOnly(infoKey: String) throws -> String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            throw AIError.missingAPIKey
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid(key) else {
            throw AIError.missingAPIKey
        }
        return key
    }

    static func isPresentInBundle(infoKey: String) -> Bool {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            return false
        }
        return isValid(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Test seam — clear the in-process user key snapshot.
    static func _resetUserKeysForTesting() async {
        await storage.reset()
    }

    // MARK: - Helpers

    private static func providerFor(infoKey: String) -> Provider? {
        switch infoKey {
        case "OPENAI_API_KEY": .openai
        case "ANTHROPIC_API_KEY": .anthropic
        case "ELEVENLABS_API_KEY": .elevenlabs
        default: nil
        }
    }

    private static func isValid(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        if key.hasPrefix("REPLACE_ME") { return false }
        if key.hasPrefix("$(") { return false }
        if key == "MISSING_IN_CI" { return false }
        return true
    }
}
