import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class SettingsAdvancedViewModel {
    enum FieldState: Equatable {
        case empty
        case editing            // user is typing or has pasted, not yet tested/saved
        case testing            // ping in flight
        case invalid(String)    // server rejected the key
        case valid              // key passed live test (or already saved & not modified)
        case saved              // key persisted in Keychain
    }

    var provider: UserAPIKeyStore.Provider
    var keyDraft: String = ""
    var state: FieldState = .empty

    private let keyStore: UserAPIKeyStore
    private let openAIClient: OpenAIClient
    private let anthropicClient: AnthropicClient
    private let usesDeterministicValidation: Bool

    init(
        keyStore: UserAPIKeyStore,
        openAIClient: OpenAIClient,
        anthropicClient: AnthropicClient,
        usesDeterministicValidation: Bool = false
    ) {
        self.keyStore = keyStore
        self.openAIClient = openAIClient
        self.anthropicClient = anthropicClient
        self.usesDeterministicValidation = usesDeterministicValidation
        self.provider = keyStore.provider
    }

    func onAppear() async {
        await keyStore.load()
        provider = keyStore.provider
        if keyStore.hasKey, let masked = keyStore.maskedKey {
            keyDraft = masked
            state = .saved
        } else {
            keyDraft = ""
            state = .empty
        }
    }

    func selectProvider(_ provider: UserAPIKeyStore.Provider) async {
        self.provider = provider
        await keyStore.selectProvider(provider)
        if keyStore.hasKey, let masked = keyStore.maskedKey {
            keyDraft = masked
            state = .saved
        } else {
            keyDraft = ""
            state = .empty
        }
    }

    func onKeyChanged(_ newValue: String) {
        keyDraft = newValue
        if newValue.isEmpty {
            state = .empty
        } else if isMaskOf(savedKey: keyStore.maskedKey, value: newValue) {
            state = .saved
        } else {
            state = .editing
        }
    }

    func pasteFromClipboard() {
        if let pasted = UIPasteboardBridge.string?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pasted.isEmpty {
            onKeyChanged(pasted)
        }
    }

    /// Run a live ping against the provider. Updates state to .valid / .invalid.
    func testKey() async {
        let trimmed = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard UserAPIKeyStore.isValidKey(trimmed, for: provider) else {
            state = .invalid("Format invalide. Vérifie le préfixe et la longueur.")
            return
        }
        if usesDeterministicValidation {
            state = trimmed.localizedCaseInsensitiveContains("fake")
                ? .invalid("Clé refusée par \(provider.displayName). Vérifie qu'elle est complète et active.")
                : .valid
            return
        }
        state = .testing
        do {
            let ok: Bool = switch provider {
            case .openai:    try await openAIClient.ping(apiKey: trimmed)
            case .anthropic: try await anthropicClient.ping(apiKey: trimmed)
            }
            state = ok ? .valid : .invalid("Clé refusée par \(provider.displayName). Vérifie qu'elle est complète et active.")
        } catch {
            state = .invalid("Impossible de tester la clé. Vérifie ta connexion.")
        }
    }

    /// Save the current draft to Keychain. Should be called only when state is .valid.
    func save() async {
        let trimmed = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await keyStore.save(trimmed)
            keyDraft = keyStore.maskedKey ?? trimmed
            state = .saved
        } catch {
            state = .invalid((error as? UserAPIKeyError)?.errorDescription ?? "Impossible d'enregistrer la clé.")
        }
    }

    func clearKey() async {
        do {
            try await keyStore.clear()
            keyDraft = ""
            state = .empty
        } catch {
            state = .invalid("Impossible de supprimer la clé.")
        }
    }

    var canTest: Bool {
        switch state {
        case .editing: return !keyDraft.isEmpty
        case .saved, .valid, .empty, .invalid, .testing: return false
        }
    }

    var canSave: Bool {
        if case .valid = state { return true }
        return false
    }

    private func isMaskOf(savedKey: String?, value: String) -> Bool {
        guard let saved = savedKey else { return false }
        return saved == value
    }
}

/// Tiny indirection so the pasteboard read can be no-op'd in tests.
private enum UIPasteboardBridge {
    static var string: String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #else
        return nil
        #endif
    }
}
