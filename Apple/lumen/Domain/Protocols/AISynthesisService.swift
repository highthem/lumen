import Foundation

enum AIResponseResult: Sendable {
    case ready(AIResponse)
    case queued(estimatedDelivery: Date?)
}

protocol AISynthesisService: Sendable {
    func synthesize(
        answers: [QuestionnaireAnswer],
        ritualId: UUID,
        mode: AIResponseMode,
        context: RitualContext
    ) async throws -> AIResponseResult
}

extension AISynthesisService {
    /// Convenience overload — calls through with an empty context.
    func synthesize(
        answers: [QuestionnaireAnswer],
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> AIResponseResult {
        try await synthesize(answers: answers, ritualId: ritualId, mode: mode, context: RitualContext())
    }
}
