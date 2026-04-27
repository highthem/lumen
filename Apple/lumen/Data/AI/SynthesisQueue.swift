import Foundation
import SwiftData
import UserNotifications

actor SynthesisQueue {

    private let modelContainer: ModelContainer
    private let ritualRepository: any RitualRepository

    init(modelContainer: ModelContainer, ritualRepository: any RitualRepository) {
        self.modelContainer = modelContainer
        self.ritualRepository = ritualRepository
    }

    func enqueue(answers: [QuestionnaireAnswer], ritualId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let entity = PendingSynthesisEntity(ritualId: ritualId, answers: answers)
        context.insert(entity)
        try context.save()
    }

    func processOnReachability(via cloudClients: [any AIProviderClient]) async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<PendingSynthesisEntity>(
            sortBy: [SortDescriptor(\.enqueuedAt)]
        )
        guard let entities = try? context.fetch(descriptor) else { return }

        for entity in entities {
            let answers = entity.decodeAnswers()
            let ritualId = entity.ritualId
            let prompt = PromptBuilder.build(answers: answers)

            var succeeded = false
            for client in cloudClients {
                if let attempt = try? await client.synthesize(prompt: prompt, ritualId: ritualId, mode: .fallbackQueued) {
                    try? await ritualRepository.attachSynthesis(attempt.response, ritualId: ritualId)
                    context.delete(entity)
                    try? context.save()
                    await notifyUser()
                    succeeded = true
                    break
                }
            }

            if !succeeded { break }
        }
    }

    // MARK: - Helpers

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
