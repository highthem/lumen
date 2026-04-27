import Foundation
import Observation

@MainActor
@Observable
final class PresenceTimerViewModel {
    var remaining: TimeInterval = 60.0
    var quote: Quote?
    var isComplete = false

    private let quoteProvider: any QuoteProviding
    private var countdownTask: Task<Void, Never>?

    init(quoteProvider: any QuoteProviding) {
        self.quoteProvider = quoteProvider
    }

    func start() async {
        quote = quoteProvider.random(lang: "fr")

        countdownTask?.cancel()
        countdownTask = Task {
            while remaining > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remaining = max(0, remaining - 1)
            }
            isComplete = true
        }
        await countdownTask?.value
    }

    func skip() {
        countdownTask?.cancel()
        isComplete = true
    }
}
