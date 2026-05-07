import Foundation
import SwiftData

@Model
final class RitualEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var state: RitualState
    /// JSON-encoded `[QuestionnaireAnswer]`. SwiftData on iOS 17 cannot
    /// introspect Codable structs containing enum-with-associated-values
    /// (`AnswerPayload`), so we serialize manually.
    var answersData: Data
    var synthesisId: UUID?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \PendingSynthesisEntity.ritual)
    var pendingSynthesis: PendingSynthesisEntity?

    init(from ritual: Ritual) {
        self.id = ritual.id
        self.date = ritual.date
        self.state = ritual.state
        self.answersData = (try? JSONEncoder().encode(ritual.answers)) ?? Data()
        self.synthesisId = ritual.synthesisId
        self.completedAt = ritual.completedAt
    }

    var answers: [QuestionnaireAnswer] {
        get { (try? JSONDecoder().decode([QuestionnaireAnswer].self, from: answersData)) ?? [] }
        set { answersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    func toDomain() -> Ritual {
        Ritual(
            id: id,
            date: date,
            state: state,
            answers: answers,
            synthesisId: synthesisId,
            completedAt: completedAt
        )
    }
}
