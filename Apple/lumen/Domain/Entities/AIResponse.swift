import Foundation

enum AIProvider: String, Sendable, Codable, Hashable {
    case openai
    case anthropic
    case apple
    case supportTemplate
    case queued
}

enum AIResponseMode: String, Sendable, Codable, Hashable {
    case auto
    case manualRegenerate
    case fallbackOnDevice
    case fallbackQueued
    case fallbackTemplate
    case askLumen
}

nonisolated struct AIResponse: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let ritualId: UUID
    /// The single calm phrase the V11 synthesis screen renders as a 48pt
    /// serif hero. Persistently stored as `intention` for backwards-compat
    /// with the V10 prompt JSON shape (the prompt now asks the model to
    /// keep this to ≤14 words and treat it as a standalone quote).
    let intention: String
    /// Supplementary lines from the V10 shape — preserved on disk for any
    /// downstream consumer (TTS narration, future "expand" affordance) but
    /// no longer rendered as separate blocks on the synthesis screen.
    let focus: [String]
    let reminder: String
    let provider: AIProvider
    let mode: AIResponseMode
    let generatedAt: Date

    /// V11 facade: the synthesis screen renders this single line as the
    /// hero quote. Mapping is intentionally trivial — the prompt change
    /// (in PromptBuilder.systemPrompt) is what shortens the underlying
    /// `intention` to a one-sentence quote.
    var heroQuote: String { intention }

    init(
        id: UUID = UUID(),
        ritualId: UUID,
        intention: String,
        focus: [String],
        reminder: String,
        provider: AIProvider,
        mode: AIResponseMode,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.ritualId = ritualId
        self.intention = intention
        self.focus = focus
        self.reminder = reminder
        self.provider = provider
        self.mode = mode
        self.generatedAt = generatedAt
    }
}
