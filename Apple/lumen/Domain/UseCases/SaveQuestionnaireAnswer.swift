import Foundation

struct SaveQuestionnaireAnswer: Sendable {
    private let ritualRepository: any RitualRepository

    init(ritualRepository: any RitualRepository) {
        self.ritualRepository = ritualRepository
    }

    @discardableResult
    func execute(ritualId: UUID, payload: AnswerPayload) async throws -> QuestionnaireAnswer {
        let answer = QuestionnaireAnswer(ritualId: ritualId, payload: payload)
        try await ritualRepository.appendAnswer(answer, ritualId: ritualId)
        return answer
    }
}
