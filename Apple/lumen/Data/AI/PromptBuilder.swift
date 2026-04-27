import Foundation
import CryptoKit

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

    nonisolated static func build(answers: [QuestionnaireAnswer]) -> (system: String, user: String) {
        var lines: [String] = []
        for answer in answers {
            switch answer.payload {
            case .mood(let level, let tag):
                var line = "Humeur : \(level)/10"
                if let tag { line += " (\(tag))" }
                lines.append(line)
            case .priority(let category, let note):
                var line = "Priorité (\(category.displayName))"
                if let note { line += " : \(note)" }
                lines.append(line)
            case .gratitude(let text):
                lines.append("Gratitude : \(text)")
            case .intention(let word):
                lines.append("Intention : \(word)")
            }
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
