import Foundation
import SwiftData

@ModelActor
actor SwiftDataRitualRepository: RitualRepository {

    func fetchOrCreateToday() async throws -> Ritual {
        let today = Calendar.current.startOfDay(for: Date())
        if let entity = try fetchEntity(forDay: today) {
            return entity.toDomain()
        }
        let ritual = Ritual(date: today)
        modelContext.insert(RitualEntity(from: ritual))
        try modelContext.save()
        return ritual
    }

    func fetch(id: UUID) async throws -> Ritual? {
        try fetchEntity(id: id)?.toDomain()
    }

    func fetchByDate(_ date: Date) async throws -> Ritual? {
        let day = Calendar.current.startOfDay(for: date)
        return try fetchEntity(forDay: day)?.toDomain()
    }

    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {
        guard let entity = try fetchEntity(id: ritualId) else { throw RitualError.notFound }

        var answers = entity.answers
        answers.append(answer)
        entity.answers = answers

        let isCompleted = answers.contains { $0.step == .gratitude }
        entity.state = isCompleted ? .completed : .partial
        if isCompleted && entity.completedAt == nil {
            entity.completedAt = Date()
        }
        try modelContext.save()
    }

    func updatePresence(ritualId: UUID, state: PresenceState) async throws {
        guard let entity = try fetchEntity(id: ritualId) else { throw RitualError.notFound }
        entity.presence = state
        try modelContext.save()
    }

    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        guard let entity = try fetchEntity(id: ritualId) else { throw RitualError.notFound }
        entity.synthesisId = response.id
        try modelContext.save()
    }

    func update(_ ritual: Ritual) async throws {
        guard let entity = try fetchEntity(id: ritual.id) else { throw RitualError.notFound }
        entity.date = ritual.date
        entity.state = ritual.state
        entity.answers = ritual.answers
        entity.presence = ritual.presence
        entity.synthesisId = ritual.synthesisId
        entity.completedAt = ritual.completedAt
        try modelContext.save()
    }

    private func fetchEntity(id: UUID) throws -> RitualEntity? {
        try modelContext.fetch(FetchDescriptor<RitualEntity>(predicate: #Predicate { $0.id == id })).first
    }

    private func fetchEntity(forDay day: Date) throws -> RitualEntity? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let descriptor = FetchDescriptor<RitualEntity>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor).first
    }
}

enum RitualError: Error, Sendable {
    case notFound
}
