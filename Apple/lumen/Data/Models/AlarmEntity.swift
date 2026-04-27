import Foundation
import SwiftData

@Model
final class AlarmEntity {
    @Attribute(.unique) var id: UUID
    var time: Date
    var recurrenceData: Data
    var soundId: String
    var isActive: Bool
    var snoozeCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(from alarm: Alarm) {
        self.id = alarm.id
        self.time = alarm.time
        self.recurrenceData = (try? JSONEncoder().encode(alarm.recurrence)) ?? Data()
        self.soundId = alarm.soundId
        self.isActive = alarm.isActive
        self.snoozeCount = alarm.snoozeCount
        self.createdAt = alarm.createdAt
        self.updatedAt = alarm.updatedAt
    }

    func toDomain() -> Alarm {
        let recurrence = (try? JSONDecoder().decode(AlarmRecurrence.self, from: recurrenceData)) ?? .none
        return Alarm(
            id: id,
            time: time,
            recurrence: recurrence,
            soundId: soundId,
            isActive: isActive,
            snoozeCount: snoozeCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from alarm: Alarm) {
        time = alarm.time
        recurrenceData = (try? JSONEncoder().encode(alarm.recurrence)) ?? Data()
        soundId = alarm.soundId
        isActive = alarm.isActive
        snoozeCount = alarm.snoozeCount
        updatedAt = alarm.updatedAt
    }
}
