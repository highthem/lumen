#if DEBUG
import Foundation

// MARK: - Sample fixtures

extension Alarm {
    static var preview: Alarm {
        let time = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        return Alarm(time: time, recurrence: .weekdays, soundId: "alarm-aube")
    }

    static var previewList: [Alarm] {
        let cal = Calendar.current
        let morning = cal.date(bySettingHour: 6, minute: 45, second: 0, of: Date()) ?? Date()
        let weekend = cal.date(bySettingHour: 9, minute: 30, second: 0, of: Date()) ?? Date()
        return [
            Alarm(time: morning, recurrence: .weekdays, soundId: "alarm-aube"),
            Alarm(time: weekend, recurrence: .everyday, soundId: "alarm-bois", isActive: false)
        ]
    }
}

extension Ritual {
    static var preview: Ritual {
        Ritual(
            date: Date(),
            state: .completed,
            answers: [
                QuestionnaireAnswer(ritualId: UUID(), payload: .mood(level: 7, tag: "posé")),
                QuestionnaireAnswer(ritualId: UUID(), payload: .energy(level: .charged)),
                QuestionnaireAnswer(ritualId: UUID(), payload: .priority(category: .energy, note: "Énergie")),
                QuestionnaireAnswer(ritualId: UUID(), payload: .gratitude(text: "Le silence avant que les enfants se lèvent."))
            ]
        )
    }
}

extension AIResponse {
    static var preview: AIResponse {
        AIResponse(
            ritualId: UUID(),
            intention: "présence",
            focus: ["Garde une priorité simple.", "Laisse de la place au corps."],
            reminder: "Reviens à ton souffle avant de répondre.",
            provider: .openai,
            mode: .auto
        )
    }
}

extension DashboardSnapshot {
    static var preview: DashboardSnapshot {
        DashboardSnapshot(
            date: Date(),
            mood: MoodSummary(level: 7, tag: "posé"),
            energy: .charged,
            priority: PrioritySummary(category: .energy, note: "Bloquer 90 min sur le brief"),
            gratitude: "Le silence avant que les enfants se lèvent.",
            presence: .completed,
            sleep: SleepSummary(
                bedtime: Date().addingTimeInterval(-8 * 3600),
                wakeTime: Date(),
                totalAsleep: 7 * 3600 + 12 * 60,
                deep: 90 * 60,
                rem: 110 * 60,
                core: 4 * 3600,
                awake: 20 * 60
            ),
            aiIntention: "présence"
        )
    }
}

extension Quote {
    static var preview: Quote {
        Quote(text: "Inspire. Expire. Tu es là.", author: "Lumen", lang: "fr")
    }
}

// MARK: - Repository stubs (in-memory)

actor PreviewAlarmRepository: AlarmRepository {
    private var storage: [UUID: Alarm]

    init(seed: [Alarm] = Alarm.previewList) {
        self.storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    func all() async throws -> [Alarm] { Array(storage.values) }
    func fetch(id: UUID) async throws -> Alarm? { storage[id] }
    func save(_ alarm: Alarm) async throws { storage[alarm.id] = alarm }
    func update(_ alarm: Alarm) async throws { storage[alarm.id] = alarm }
    func delete(id: UUID) async throws { storage.removeValue(forKey: id) }
    func setActive(id: UUID, isActive: Bool) async throws {
        guard var alarm = storage[id] else { return }
        alarm.isActive = isActive
        storage[id] = alarm
    }
}

actor PreviewRitualRepository: RitualRepository {
    private var ritual: Ritual

    init(seed: Ritual = .preview) { self.ritual = seed }

    func fetchOrCreateToday() async throws -> Ritual { ritual }
    func fetch(id: UUID) async throws -> Ritual? { id == ritual.id ? ritual : nil }
    func fetchByDate(_ date: Date) async throws -> Ritual? { ritual }
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws {
        ritual.answers.append(answer)
    }
    func updatePresence(ritualId: UUID, state: PresenceState) async throws {
        ritual.presence = state
    }
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws {
        ritual.synthesisId = response.id
    }
    func update(_ ritual: Ritual) async throws { self.ritual = ritual }
}

actor PreviewEthicalLogRepository: EthicalLogRepository {
    func save(_ log: EthicalLog) async throws {}
    func fetchAll() async throws -> [EthicalLog] { [] }
    func fetchAll(limit: Int, offset: Int) async throws -> [EthicalLog] { [] }
    func deleteAll() async throws {}
    func exportJSON() async throws -> Data { Data("[]".utf8) }
}

// MARK: - Service stubs

struct PreviewQuoteProvider: QuoteProviding {
    func random(lang: String) async -> Quote? { .preview }
}

actor PreviewRateLimiter: RateLimiting {
    func canProceed(action: AIAction) async -> Bool { true }
    func consume(action: AIAction) async {}
    func reset() async {}
    func remainingSlots(action: AIAction) async -> Int { 3 }
}

struct PreviewAISynthesisService: AISynthesisService {
    let mode: AIResponseMode

    init(mode: AIResponseMode = .auto) { self.mode = mode }

    func synthesize(
        answers: [QuestionnaireAnswer],
        ritualId: UUID,
        mode: AIResponseMode,
        context: RitualContext
    ) async throws -> AIResponseResult {
        let response = AIResponse(
            ritualId: ritualId,
            intention: "présence",
            focus: ["Garde une priorité simple.", "Laisse de la place au corps."],
            reminder: "Reviens à ton souffle avant de répondre.",
            provider: .openai,
            mode: mode
        )
        return .ready(response)
    }
}
#endif
