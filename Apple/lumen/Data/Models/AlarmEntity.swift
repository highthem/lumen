import Foundation
import SwiftData

@Model
final class AlarmEntity {
    @Attribute(.unique) var id: UUID
    var time: Date
    /// JSON-encoded `AlarmRecurrence`. SwiftData on iOS 17 cannot introspect
    /// Codable enums with associated values (`.custom(Set<Weekday>)`), so we
    /// serialize manually and decode at the domain boundary.
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

    var recurrence: AlarmRecurrence {
        get { (try? JSONDecoder().decode(AlarmRecurrence.self, from: recurrenceData)) ?? .none }
        set { recurrenceData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    func toDomain() -> Alarm {
        Alarm(
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
}
