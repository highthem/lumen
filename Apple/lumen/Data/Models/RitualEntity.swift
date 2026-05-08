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
    /// `PresenceState.rawValue` — bridged via the `presence` computed accessor.
    /// Default value keeps the migration light (no VersionedSchema needed).
    var presenceRaw: String = PresenceState.notStarted.rawValue
    var synthesisId: UUID?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \PendingSynthesisEntity.ritual)
    var pendingSynthesis: PendingSynthesisEntity?

    init(from ritual: Ritual) {
        self.id = ritual.id
        self.date = ritual.date
        self.state = ritual.state
        self.answersData = (try? JSONEncoder().encode(ritual.answers)) ?? Data()
        self.presenceRaw = ritual.presence.rawValue
        self.synthesisId = ritual.synthesisId
        self.completedAt = ritual.completedAt
    }

    var answers: [QuestionnaireAnswer] {
        get { (try? JSONDecoder().decode([QuestionnaireAnswer].self, from: answersData)) ?? [] }
        set { answersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var presence: PresenceState {
        get { PresenceState(rawValue: presenceRaw) ?? .notStarted }
        set { presenceRaw = newValue.rawValue }
    }

    func toDomain() -> Ritual {
        Ritual(
            id: id,
            date: date,
            state: state,
            answers: answers,
            presence: presence,
            synthesisId: synthesisId,
            completedAt: completedAt
        )
    }
}
