import Foundation

struct SynthesisAttempt: Sendable {
    let response: AIResponse
    let latencyMs: Int
    let tokenIn: Int?
    let tokenOut: Int?
}

protocol AIProviderClient: Sendable {
    var name: String { get }
    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt
}
