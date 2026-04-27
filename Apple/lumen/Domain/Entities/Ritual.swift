import Foundation

enum RitualState: String, Sendable, Codable, Hashable {
    case notStarted
    case partial
    case completed
}

nonisolated struct Ritual: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let date: Date
    var state: RitualState
    var answers: [QuestionnaireAnswer]
    var synthesisId: UUID?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        state: RitualState = .notStarted,
        answers: [QuestionnaireAnswer] = [],
        synthesisId: UUID? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.answers = answers
        self.synthesisId = synthesisId
        self.completedAt = completedAt
    }
}
