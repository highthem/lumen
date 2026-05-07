import Foundation
import SwiftData

@Model
final class PendingSynthesisEntity {
    @Attribute(.unique) var id: UUID
    var ritual: RitualEntity?
    /// JSON-encoded `[QuestionnaireAnswer]` — see `RitualEntity` for rationale.
    var answersData: Data
    var enqueuedAt: Date

    init(
        id: UUID = UUID(),
        ritual: RitualEntity? = nil,
        answers: [QuestionnaireAnswer],
        enqueuedAt: Date = Date()
    ) {
        self.id = id
        self.ritual = ritual
        self.answersData = (try? JSONEncoder().encode(answers)) ?? Data()
        self.enqueuedAt = enqueuedAt
    }

    var answers: [QuestionnaireAnswer] {
        get { (try? JSONDecoder().decode([QuestionnaireAnswer].self, from: answersData)) ?? [] }
        set { answersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
