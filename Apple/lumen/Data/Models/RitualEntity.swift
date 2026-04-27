import Foundation
import SwiftData

@Model
final class RitualEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var stateRaw: String
    var answersData: Data
    var synthesisId: UUID?
    var completedAt: Date?

    init(from ritual: Ritual) {
        self.id = ritual.id
        self.date = ritual.date
        self.stateRaw = ritual.state.rawValue
        self.answersData = (try? JSONEncoder().encode(ritual.answers)) ?? Data()
        self.synthesisId = ritual.synthesisId
        self.completedAt = ritual.completedAt
    }

    func toDomain() -> Ritual {
        let state = RitualState(rawValue: stateRaw) ?? .notStarted
        let answers = (try? JSONDecoder().decode([QuestionnaireAnswer].self, from: answersData)) ?? []
        return Ritual(
            id: id,
            date: date,
            state: state,
            answers: answers,
            synthesisId: synthesisId,
            completedAt: completedAt
        )
    }

    func update(from ritual: Ritual) {
        stateRaw = ritual.state.rawValue
        answersData = (try? JSONEncoder().encode(ritual.answers)) ?? Data()
        synthesisId = ritual.synthesisId
        completedAt = ritual.completedAt
    }
}
