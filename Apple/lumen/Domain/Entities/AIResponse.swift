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
    let intention: String
    let focus: [String]
    let reminder: String
    let provider: AIProvider
    let mode: AIResponseMode
    let generatedAt: Date

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
