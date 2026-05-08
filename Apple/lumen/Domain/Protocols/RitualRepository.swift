import Foundation

protocol RitualRepository: Sendable {
    func fetchOrCreateToday() async throws -> Ritual
    func fetch(id: UUID) async throws -> Ritual?
    func fetchByDate(_ date: Date) async throws -> Ritual?
    /// All rituals whose `date` is at or after `date`, ascending.
    /// Powers the dashboard's 7-day streak window.
    func fetchSince(_ date: Date) async throws -> [Ritual]
    func appendAnswer(_ answer: QuestionnaireAnswer, ritualId: UUID) async throws
    func updatePresence(ritualId: UUID, state: PresenceState) async throws
    func attachSynthesis(_ response: AIResponse, ritualId: UUID) async throws
    func update(_ ritual: Ritual) async throws
    /// Wipes every persisted ritual. Used by Settings → Erase ritual history.
    func deleteAll() async throws
}
