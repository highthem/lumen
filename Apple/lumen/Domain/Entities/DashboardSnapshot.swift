import Foundation

enum SleepFeeling: String, Sendable, Codable, Hashable {
    case rested
    case ok
    case tired
}

struct BodyCheckin: Sendable, Codable, Hashable {
    var sleepFeeling: SleepFeeling?
    var hydrationNote: String?

    init(sleepFeeling: SleepFeeling? = nil, hydrationNote: String? = nil) {
        self.sleepFeeling = sleepFeeling
        self.hydrationNote = hydrationNote
    }
}

struct DashboardSnapshot: Sendable, Codable, Hashable {
    let date: Date
    var energy: String?
    var intention: String?
    var bodyCheckin: BodyCheckin
    var relations: String?
    var work: String?
    var gratitude: String?

    init(
        date: Date,
        energy: String? = nil,
        intention: String? = nil,
        bodyCheckin: BodyCheckin = BodyCheckin(),
        relations: String? = nil,
        work: String? = nil,
        gratitude: String? = nil
    ) {
        self.date = date
        self.energy = energy
        self.intention = intention
        self.bodyCheckin = bodyCheckin
        self.relations = relations
        self.work = work
        self.gratitude = gratitude
    }
}
