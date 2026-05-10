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
    var synthesisInsightsData: Data?
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
        self.synthesisInsights = ritual.synthesisInsights
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

    var synthesisInsights: [DashboardCategory: String]? {
        get {
            guard let synthesisInsightsData else { return nil }
            let raw = try? JSONDecoder().decode([String: String].self, from: synthesisInsightsData)
            let decoded = raw?.reduce(into: [DashboardCategory: String]()) { result, entry in
                guard let category = DashboardCategory(rawValue: entry.key) else { return }
                result[category] = entry.value
            }
            return decoded?.isEmpty == true ? nil : decoded
        }
        set {
            guard let newValue, !newValue.isEmpty else {
                synthesisInsightsData = nil
                return
            }
            let raw = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.rawValue, $0.value) })
            synthesisInsightsData = try? JSONEncoder().encode(raw)
        }
    }

    func toDomain() -> Ritual {
        Ritual(
            id: id,
            date: date,
            state: state,
            answers: answers,
            presence: presence,
            synthesisId: synthesisId,
            synthesisInsights: synthesisInsights,
            completedAt: completedAt
        )
    }
}
