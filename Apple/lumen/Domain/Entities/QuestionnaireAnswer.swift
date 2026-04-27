import Foundation

enum QuestionnaireStep: String, Sendable, Codable, Hashable {
    case mood
    case priority
    case gratitude
    case intention
}

nonisolated enum AnswerPayload: Sendable, Codable, Hashable {
    case mood(level: Int, tag: String?)
    case priority(category: DashboardCategory, note: String?)
    case gratitude(text: String)
    case intention(word: String)

    nonisolated var step: QuestionnaireStep {
        switch self {
        case .mood:      return .mood
        case .priority:  return .priority
        case .gratitude: return .gratitude
        case .intention: return .intention
        }
    }

    // MARK: - Manual Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case level, tag
        case category, note
        case text
        case word
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mood(let level, let tag):
            try container.encode("mood", forKey: .type)
            try container.encode(level, forKey: .level)
            try container.encodeIfPresent(tag, forKey: .tag)
        case .priority(let category, let note):
            try container.encode("priority", forKey: .type)
            try container.encode(category, forKey: .category)
            try container.encodeIfPresent(note, forKey: .note)
        case .gratitude(let text):
            try container.encode("gratitude", forKey: .type)
            try container.encode(text, forKey: .text)
        case .intention(let word):
            try container.encode("intention", forKey: .type)
            try container.encode(word, forKey: .word)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "mood":
            let level = try container.decode(Int.self, forKey: .level)
            let tag = try container.decodeIfPresent(String.self, forKey: .tag)
            self = .mood(level: level, tag: tag)
        case "priority":
            let category = try container.decode(DashboardCategory.self, forKey: .category)
            let note = try container.decodeIfPresent(String.self, forKey: .note)
            self = .priority(category: category, note: note)
        case "gratitude":
            let text = try container.decode(String.self, forKey: .text)
            self = .gratitude(text: text)
        case "intention":
            let word = try container.decode(String.self, forKey: .word)
            self = .intention(word: word)
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown AnswerPayload type: \(type)"))
        }
    }
}

nonisolated struct QuestionnaireAnswer: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let ritualId: UUID
    let payload: AnswerPayload
    let createdAt: Date

    var step: QuestionnaireStep { payload.step }

    init(id: UUID = UUID(), ritualId: UUID, payload: AnswerPayload, createdAt: Date = Date()) {
        self.id = id
        self.ritualId = ritualId
        self.payload = payload
        self.createdAt = createdAt
    }
}
