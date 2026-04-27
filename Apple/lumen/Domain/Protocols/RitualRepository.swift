import Foundation

protocol RitualRepository: Sendable {
    func fetchOrCreateToday() async throws -> Ritual
    func fetch(id: UUID) async throws -> Ritual?
    func fetchByDate(_ date: Date) async throws -> Ritual?
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws
    func update(_ ritual: Ritual) async throws
}
