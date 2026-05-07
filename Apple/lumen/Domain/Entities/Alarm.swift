import Foundation

nonisolated struct Alarm: Identifiable, Equatable, Sendable, Codable, Hashable {
    let id: UUID
    var time: Date
    var recurrence: AlarmRecurrence
    var soundId: String
    var isActive: Bool
    var snoozeCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        time: Date,
        recurrence: AlarmRecurrence = .none,
        soundId: String = "alarm-aube",
        isActive: Bool = true,
        snoozeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.recurrence = recurrence
        self.soundId = soundId
        self.isActive = isActive
        self.snoozeCount = snoozeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
