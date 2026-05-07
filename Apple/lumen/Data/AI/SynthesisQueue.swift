import Foundation
import SwiftData
import UserNotifications

@ModelActor
actor SynthesisQueue {

    func enqueue(answers: [QuestionnaireAnswer], ritualId: UUID) async throws {
        let ritual = try modelContext.fetch(
            FetchDescriptor<RitualEntity>(predicate: #Predicate { $0.id == ritualId })
        ).first
        let entity = PendingSynthesisEntity(ritual: ritual, answers: answers)
        modelContext.insert(entity)
        try modelContext.save()
    }

    func processOnReachability(
        via cloudClients: [any AIProviderClient],
        ritualRepository: any RitualRepository
    ) async {
        let descriptor = FetchDescriptor<PendingSynthesisEntity>(
            sortBy: [SortDescriptor(\.enqueuedAt)]
        )
        guard let entities = try? modelContext.fetch(descriptor) else { return }

        for entity in entities {
            guard let ritualId = entity.ritual?.id else {
                modelContext.delete(entity)
                try? modelContext.save()
                continue
            }
            let answers = entity.answers
            let prompt = PromptBuilder.build(answers: answers)

            var succeeded = false
            for client in cloudClients {
                if let attempt = try? await client.synthesize(prompt: prompt, ritualId: ritualId, mode: .fallbackQueued) {
                    try? await ritualRepository.attachSynthesis(attempt.response, ritualId: ritualId)
                    modelContext.delete(entity)
                    try? modelContext.save()
                    await notifyUser()
                    succeeded = true
                    break
                }
            }

            if !succeeded { break }
        }
    }

    private func notifyUser() async {
        let content = UNMutableNotificationContent()
        content.title = "Ta synthèse de ce matin est prête"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lumen.synthesis.ready.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
