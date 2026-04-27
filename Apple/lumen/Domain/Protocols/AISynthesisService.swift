import Foundation

enum AIResponseResult: Sendable {
    case ready(AIResponse)
    case queued(estimatedDelivery: Date?)
}

protocol AISynthesisService: Sendable {
    func synthesize(answers: [QuestionnaireAnswer], ritualId: UUID, mode: AIResponseMode) async throws -> AIResponseResult
}
