import Foundation

struct MoodSummary: Sendable, Codable, Hashable {
    let level: Int
    let tag: String?
}

struct PrioritySummary: Sendable, Codable, Hashable {
    /// Free-text answer the user dictated or typed at Q3 (V11 voice-first
    /// shape). Replaces the V8-V10 category/note tuple.
    let text: String
}

struct DashboardSnapshot: Sendable, Codable, Hashable {
    let date: Date
    var mood: MoodSummary?
    var energy: EnergyLevel?
    var priority: PrioritySummary?
    var gratitude: String?
    var presence: PresenceState
    var sleep: SleepSummary?
    /// Synthesis output displayed in the hero card above the grid.
    var aiIntention: String?

    init(
        date: Date,
        mood: MoodSummary? = nil,
        energy: EnergyLevel? = nil,
        priority: PrioritySummary? = nil,
        gratitude: String? = nil,
        presence: PresenceState = .notStarted,
        sleep: SleepSummary? = nil,
        aiIntention: String? = nil
    ) {
        self.date = date
        self.mood = mood
        self.energy = energy
        self.priority = priority
        self.gratitude = gratitude
        self.presence = presence
        self.sleep = sleep
        self.aiIntention = aiIntention
    }
}
