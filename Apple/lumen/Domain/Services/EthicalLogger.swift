import Foundation

actor EthicalLogger {

    private let repository: any EthicalLogRepository
    private let clock: any LumenClock

    init(repository: any EthicalLogRepository, clock: any LumenClock = SystemClock()) {
        self.repository = repository
        self.clock = clock
    }

    func logSynthesis(
        provider: AIProvider,
        mode: AIResponseMode,
        latencyMs: Int?,
        tokenIn: Int?,
        tokenOut: Int?,
        promptHash: String,
        flags: [ContentSafetyFlag]
    ) async throws {
        let privacyScope: String
        switch provider {
        case .apple:
            privacyScope = "device_only"
        case .queued:
            privacyScope = "pending"
        default:
            privacyScope = "user_input_only"
        }

        let log = EthicalLog(
            timestamp: clock.now(),
            provider: provider.rawValue,
            mode: mode.rawValue,
            latencyMs: latencyMs,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            promptHash: promptHash,
            contentSafetyFlags: flags.map(\.rawValue),
            privacyScope: privacyScope
        )
        try await repository.save(log)
    }

    func logSafetyShortCircuit(promptHash: String, flags: [ContentSafetyFlag]) async throws {
        let log = EthicalLog(
            timestamp: clock.now(),
            provider: "support-template",
            mode: "fallbackTemplate",
            promptHash: promptHash,
            contentSafetyFlags: flags.map(\.rawValue),
            privacyScope: "local_user_data_only"
        )
        try await repository.save(log)
    }

    func logQueued(promptHash: String) async throws {
        let log = EthicalLog(
            timestamp: clock.now(),
            provider: "queued",
            mode: "fallbackQueued",
            promptHash: promptHash,
            privacyScope: "pending"
        )
        try await repository.save(log)
    }

    /// Records which TTS provider rendered a synthesis. The text being read is never logged —
    /// only the provider identifier ("elevenlabs" / "apple-on-device") and, on fallback,
    /// a short reason string.
    func logTTS(provider: String, success: Bool, fallbackReason: String?) async throws {
        var flags: [String] = []
        if !success { flags.append("tts_failed") }
        if let fallbackReason { flags.append("tts_fallback:\(fallbackReason)") }

        let privacyScope = (provider == "elevenlabs") ? "user_input_only" : "device_only"

        let log = EthicalLog(
            timestamp: clock.now(),
            provider: "tts",
            mode: "tts",
            promptHash: "",
            contentSafetyFlags: flags,
            privacyScope: privacyScope,
            ttsProvider: provider
        )
        try await repository.save(log)
    }
}
