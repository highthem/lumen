import Foundation

enum QuestionnaireStep: String, Sendable, Codable, Hashable {
    case mood
    case energy
    case priority
    case gratitude

    /// Canonical sequential order used to determine questionnaire progress.
    static let sequentialOrder: [QuestionnaireStep] = [.mood, .energy, .priority, .gratitude]

    /// 1-based display index (mood = 1, energy = 2, priority = 3, gratitude = 4).
    var displayIndex: Int {
        (QuestionnaireStep.sequentialOrder.firstIndex(of: self) ?? 0) + 1
    }
}

nonisolated enum AnswerPayload: Sendable, Codable, Hashable {
    case mood(level: Int, tag: String?)
    case energy(level: EnergyLevel)
    case priority(text: String)        // V11+ — was: category + note (legacy decoded below)
    case gratitude(text: String)

    nonisolated var step: QuestionnaireStep {
        switch self {
        case .mood:      return .mood
        case .energy:    return .energy
        case .priority:  return .priority
        case .gratitude: return .gratitude
        }
    }

    // MARK: - Manual Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case level, tag
        case category, note   // legacy keys for V8-V10 priority payloads
        case text
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mood(let level, let tag):
            try container.encode("mood", forKey: .type)
            try container.encode(level, forKey: .level)
            try container.encodeIfPresent(tag, forKey: .tag)
        case .energy(let level):
            try container.encode("energy", forKey: .type)
            try container.encode(level, forKey: .level)
        case .priority(let text):
            try container.encode("priority", forKey: .type)
            try container.encode(text, forKey: .text)
        case .gratitude(let text):
            try container.encode("gratitude", forKey: .type)
            try container.encode(text, forKey: .text)
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
        case "energy":
            let level = try container.decode(EnergyLevel.self, forKey: .level)
            self = .energy(level: level)
        case "priority":
            // V11 shape: { type:"priority", text:"..." }
            if let text = try container.decodeIfPresent(String.self, forKey: .text) {
                self = .priority(text: text)
            } else {
                // Legacy V8-V10 shape: { type:"priority", category:"work", note:"..." }
                // Surface the category name (+ note if present) as free text so
                // existing rituals still display sensibly post-rewrite.
                let categoryRaw = try container.decode(String.self, forKey: .category)
                let note = try container.decodeIfPresent(String.self, forKey: .note)
                let displayed = legacyPriorityDisplay(category: categoryRaw, note: note)
                self = .priority(text: displayed)
            }
        case "gratitude":
            let text = try container.decode(String.self, forKey: .text)
            self = .gratitude(text: text)
        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown AnswerPayload type: \(type)"
            ))
        }
    }
}

/// Maps a pre-V11 priority `{category, note}` payload to a single free-text
/// representation. Standalone helper so the Codable init stays readable.
private nonisolated func legacyPriorityDisplay(category: String, note: String?) -> String {
    let label: String
    switch category {
    case "energy":    label = "Énergie"
    case "work":      label = "Travail"
    case "relations": label = "Relations"
    case "body":      label = "Corps"
    case "gratitude": label = "Gratitude"
    default:          label = category.capitalized
    }
    if let note, !note.isEmpty {
        return "\(label). \(note)"
    }
    return label
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
