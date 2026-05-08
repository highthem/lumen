import Foundation
import CryptoKit

/// Optional context surfaced alongside questionnaire answers when building the
/// LLM prompt. Defaults make the type opt-in for callers that don't care.
struct RitualContext: Sendable, Hashable {
    var presence: PresenceState
    var sleep: SleepSummary?

    init(presence: PresenceState = .notStarted, sleep: SleepSummary? = nil) {
        self.presence = presence
        self.sleep = sleep
    }
}

enum PromptBuilder {

    nonisolated static let systemPrompt: String = """
    Tu es Lumen, un assistant bienveillant qui aide les gens à commencer leur journée avec intention et clarté. \
    Ton rôle est de synthétiser les réflexions matinales d'un utilisateur en une guidance personnelle, chaleureuse et concise. \
    Réponds uniquement en JSON valide avec exactement les clés suivantes : \
    "intention" (une phrase d'intention pour la journée, max 120 caractères), \
    "focus" (un tableau de 2 à 3 pistes d'action concrètes, chaque élément max 100 caractères), \
    "reminder" (un rappel bienveillant, max 80 caractères). \
    Utilise la langue de l'utilisateur. Sois chaleureux, encourageant et pragmatique.
    """

    nonisolated static func build(
        answers: [QuestionnaireAnswer],
        context: RitualContext = RitualContext()
    ) -> (system: String, user: String) {
        var lines: [String] = []
        for answer in answers {
            switch answer.payload {
            case .mood(let level, let tag):
                var line = "Humeur : \(level)/10"
                if let tag { line += " (\(tag))" }
                lines.append(line)
            case .energy(let level):
                lines.append("Énergie : \(level.displayName)")
            case .priority(let category, let note):
                var line = "Priorité (\(category.displayName))"
                if let note { line += " : \(note)" }
                lines.append(line)
            case .gratitude(let text):
                lines.append("Gratitude : \(text)")
            }
        }

        switch context.presence {
        case .completed:
            lines.append("Présence : 60 secondes — souligne brièvement, sans flatterie.")
        case .partial:
            lines.append("Présence : quelques secondes — reconnais l'effort, sans pression.")
        case .skipped:
            lines.append("Présence : sautée — invite doucement à essayer 30 secondes demain.")
        case .notStarted:
            break
        }

        if let sleep = context.sleep {
            let hours = Int(sleep.totalAsleep) / 3600
            let minutes = (Int(sleep.totalAsleep) % 3600) / 60
            lines.append("Sommeil : \(hours)h\(minutes)m, \(sleep.quality.displayName).")
        }

        let user = lines.joined(separator: "\n")
        return (systemPrompt, user)
    }

    nonisolated static func hash(system: String, user: String) -> String {
        let combined = system + "\n---\n" + user
        let data = Data(combined.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
