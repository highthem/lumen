import Foundation
import Observation

/// User-facing wrapper around `KeychainStore` for BYOK API keys.
/// Owns the user's selected provider (`.openai` or `.anthropic`) and
/// the persisted key for that provider. UI and the resolver consult
/// this store instead of going to Keychain directly.
@MainActor
@Observable
final class UserAPIKeyStore {
    enum Provider: String, CaseIterable, Sendable {
        case openai
        case anthropic

        var displayName: String {
            switch self {
            case .openai: "OpenAI"
            case .anthropic: "Anthropic"
            }
        }

        var keyPrefix: String {
            switch self {
            case .openai: "sk-"
            case .anthropic: "sk-ant-"
            }
        }

        var placeholder: String {
            switch self {
            case .openai: "sk-proj-..."
            case .anthropic: "sk-ant-api03-..."
            }
        }

        var keychainAccount: String {
            "user-\(rawValue)-api-key"
        }

        var resolverProvider: APIKeyResolver.Provider {
            switch self {
            case .openai: .openai
            case .anthropic: .anthropic
            }
        }
    }

    private(set) var provider: Provider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: providerKey) }
    }

    /// True when the *current provider* has a saved key in Keychain.
    private(set) var hasKey: Bool = false

    /// Masked representation of the saved key for display, e.g. "sk-proj-7K2…ZwA3".
    private(set) var maskedKey: String?

    private let keychain: KeychainStore
    private let providerKey = "lumen.userKeys.provider"

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        let storedRaw = UserDefaults.standard.string(forKey: providerKey)
        self.provider = Provider(rawValue: storedRaw ?? "") ?? .openai
    }

    func load() async {
        // Sync the resolver snapshot from Keychain on launch so AI clients
        // pick up the user key on the very first synthesis call.
        for provider in Provider.allCases {
            let value = (try? await keychain.read(account: provider.keychainAccount)) ?? nil
            await APIKeyResolver.setUserKey(value, for: provider.resolverProvider)
        }
        let key = await readCurrentKey()
        hasKey = (key != nil)
        maskedKey = key.map(Self.mask)
    }

    func selectProvider(_ provider: Provider) async {
        guard provider != self.provider else { return }
        self.provider = provider
        await load()
    }

    func save(_ key: String) async throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidKey(trimmed, for: provider) else {
            throw UserAPIKeyError.invalidFormat
        }
        try await keychain.save(account: provider.keychainAccount, value: trimmed)
        await APIKeyResolver.setUserKey(trimmed, for: provider.resolverProvider)
        hasKey = true
        maskedKey = Self.mask(trimmed)
    }

    func clear() async throws {
        try await keychain.delete(account: provider.keychainAccount)
        await APIKeyResolver.setUserKey(nil, for: provider.resolverProvider)
        hasKey = false
        maskedKey = nil
    }

    /// Returns the current provider's key, or nil if none saved.
    func readCurrentKey() async -> String? {
        do {
            return try await keychain.read(account: provider.keychainAccount)
        } catch {
            return nil
        }
    }

    // MARK: - Validation

    /// Quick prefix-based sanity check. Live validation happens via the
    /// AI client `ping()` calls — that's where we tell "valid format" from
    /// "actually accepted by the provider".
    static func isValidKey(_ key: String, for provider: Provider) -> Bool {
        guard key.count >= 20 else { return false }
        switch provider {
        case .openai:
            // OpenAI: `sk-...` or `sk-proj-...`, but NOT `sk-ant-...`
            return key.hasPrefix("sk-") && !key.hasPrefix("sk-ant-")
        case .anthropic:
            return key.hasPrefix("sk-ant-")
        }
    }

    static func mask(_ key: String) -> String {
        guard key.count > 11 else { return String(repeating: "•", count: key.count) }
        let prefix = key.prefix(7)
        let suffix = key.suffix(4)
        return "\(prefix)\(String(repeating: "•", count: max(4, key.count - 11)))\(suffix)"
    }
}

enum UserAPIKeyError: Error, LocalizedError {
    case invalidFormat
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Format de clé invalide."
        case .unknown(let message):
            return message
        }
    }
}
