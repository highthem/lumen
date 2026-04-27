import Foundation

struct SupportResourcesProvider: Sendable {

    func template(for ritualId: UUID, locale: Locale = .current) -> AIResponse {
        AIResponse(
            id: UUID(),
            ritualId: ritualId,
            intention: "Tu n'es pas seul·e.",
            focus: [
                "Si tu as besoin de parler maintenant : 3114 (Suicide écoute, FR, 24/7).",
                "Crisis Text Line international : envoie HOME au 741741."
            ],
            reminder: "Prends soin de toi aujourd'hui.",
            provider: .supportTemplate,
            mode: .fallbackTemplate,
            generatedAt: Date()
        )
    }
}
