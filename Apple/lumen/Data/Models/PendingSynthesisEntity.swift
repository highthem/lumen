import Foundation
import SwiftData

@Model
final class PendingSynthesisEntity {
    @Attribute(.unique) var id: UUID
    var ritualId: UUID
    var answersData: Data
    var enqueuedAt: Date

    init(id: UUID = UUID(), ritualId: UUID, answers: [QuestionnaireAnswer], enqueuedAt: Date = Date()) {
        self.id = id
        self.ritualId = ritualId
        self.answersData = (try? JSONEncoder().encode(answers)) ?? Data()
        self.enqueuedAt = enqueuedAt
    }

    func decodeAnswers() -> [QuestionnaireAnswer] {
        (try? JSONDecoder().decode([QuestionnaireAnswer].self, from: answersData)) ?? []
    }
}
