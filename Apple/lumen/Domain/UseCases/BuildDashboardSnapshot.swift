import Foundation

struct BuildDashboardSnapshot: Sendable {
    private let ritualRepository: any RitualRepository

    init(ritualRepository: any RitualRepository) {
        self.ritualRepository = ritualRepository
    }

    func execute(date: Date) async throws -> DashboardSnapshot {
        guard let ritual = try await ritualRepository.fetchByDate(date) else {
            return DashboardSnapshot(date: date)
        }

        var snapshot = DashboardSnapshot(date: date)

        for answer in ritual.answers {
            switch answer.payload {
            case .mood(let level, _):
                snapshot.energy = moodLabel(for: level)
            case .priority(let category, let note):
                switch category {
                case .energy:
                    if snapshot.energy == nil { snapshot.energy = note }
                case .intention:
                    snapshot.intention = note
                case .body:
                    snapshot.bodyCheckin = BodyCheckin(hydrationNote: note)
                case .relations:
                    snapshot.relations = note
                case .work:
                    snapshot.work = note
                case .gratitude:
                    snapshot.gratitude = note
                }
            case .gratitude(let text):
                snapshot.gratitude = text
            case .intention(let word):
                snapshot.intention = word
            }
        }

        return snapshot
    }

    private func moodLabel(for level: Int) -> String {
        switch level {
        case ..<3:  return "Faible"
        case 3..<6: return "Moyen"
        case 6..<8: return "Bien"
        default:    return "Excellent"
        }
    }
}
