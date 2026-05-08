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
    Tu es Lumen, un compagnon calme qui aide à commencer la journée avec intention. \
    Synthétise les réflexions matinales en une guidance brève et personnelle. \
    Réponds uniquement en JSON valide avec exactement ces clés : \
    "intention" — UNE seule phrase calme en français, max 14 mots, sans point d'exclamation, qui peut se lire comme une citation autonome (c'est ce que l'utilisateur verra en grand sur l'écran), \
    "focus" — un tableau de 2 à 3 pistes d'action concrètes, chaque élément max 100 caractères (utilisées en synthèse audio), \
    "reminder" — un rappel doux, max 80 caractères. \
    Ton mirroir, jamais coach. Pas de superlatifs, pas de félicitations.
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
            case .priority(let text):
                lines.append("Priorité : \(text)")
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
