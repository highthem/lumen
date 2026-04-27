import Foundation

enum UserFeedback: String, Sendable, Codable, Hashable {
    case positive
    case negative
}

nonisolated struct EthicalLog: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let provider: String
    let mode: String
    let latencyMs: Int?
    let tokenIn: Int?
    let tokenOut: Int?
    let promptHash: String
    let contentSafetyFlags: [String]
    let userFeedback: UserFeedback?
    let privacyScope: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        provider: String,
        mode: String,
        latencyMs: Int? = nil,
        tokenIn: Int? = nil,
        tokenOut: Int? = nil,
        promptHash: String,
        contentSafetyFlags: [String] = [],
        userFeedback: UserFeedback? = nil,
        privacyScope: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.provider = provider
        self.mode = mode
        self.latencyMs = latencyMs
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.promptHash = promptHash
        self.contentSafetyFlags = contentSafetyFlags
        self.userFeedback = userFeedback
        self.privacyScope = privacyScope
    }
}
