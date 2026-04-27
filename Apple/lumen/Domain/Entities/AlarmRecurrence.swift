import Foundation

nonisolated enum AlarmRecurrence: Equatable, Sendable, Hashable {
    case none
    case weekdays
    case everyday
    case custom(Set<Weekday>)

    var asWeekdaySet: Set<Weekday> {
        switch self {
        case .none:
            return []
        case .weekdays:
            return [.mon, .tue, .wed, .thu, .fri]
        case .everyday:
            return Set(Weekday.allCases)
        case .custom(let days):
            return days
        }
    }
}

nonisolated extension AlarmRecurrence: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case days
    }

    private enum TypeValue: String, Codable {
        case none, weekdays, everyday, custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(TypeValue.none, forKey: .type)
        case .weekdays:
            try container.encode(TypeValue.weekdays, forKey: .type)
        case .everyday:
            try container.encode(TypeValue.everyday, forKey: .type)
        case .custom(let days):
            try container.encode(TypeValue.custom, forKey: .type)
            try container.encode(days, forKey: .days)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type_ = try container.decode(TypeValue.self, forKey: .type)
        switch type_ {
        case .none:
            self = .none
        case .weekdays:
            self = .weekdays
        case .everyday:
            self = .everyday
        case .custom:
            let days = try container.decode(Set<Weekday>.self, forKey: .days)
            self = .custom(days)
        }
    }
}
