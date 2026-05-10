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
    var presence: PresenceState
    var synthesisId: UUID?
    var synthesisInsights: [DashboardCategory: String]?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        state: RitualState = .notStarted,
        answers: [QuestionnaireAnswer] = [],
        presence: PresenceState = .notStarted,
        synthesisId: UUID? = nil,
        synthesisInsights: [DashboardCategory: String]? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.answers = answers
        self.presence = presence
        self.synthesisId = synthesisId
        self.synthesisInsights = synthesisInsights?.isEmpty == true ? nil : synthesisInsights
        self.completedAt = completedAt
    }
}
