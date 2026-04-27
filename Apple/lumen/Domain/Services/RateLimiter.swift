import Foundation

// UserDefaults is @MainActor in Swift 6; wrap all access in nonisolated(unsafe)
// so the actor can mutate it from its own executor without races (single-writer via actor).
actor RateLimiter: RateLimiting {

    private let autoCountKey   = "lumen.ratelimiter.autoCount"
    private let sharedCountKey = "lumen.ratelimiter.sharedCount"
    private let lastResetKey   = "lumen.ratelimiter.lastResetEpoch"
    private let autoCap        = 1
    private let sharedCap      = 3

    private let clock: any LumenClock
    nonisolated(unsafe) private let store: UserDefaults

    init(clock: any LumenClock = SystemClock(), userDefaults: UserDefaults = .standard) {
        self.clock = clock
        self.store = userDefaults
    }

    // MARK: - Day-boundary reset

    private func resetIfNeeded() {
        let now = clock.now()
        let epoch = store.double(forKey: lastResetKey)
        let lastReset = epoch == 0 ? Date.distantPast : Date(timeIntervalSince1970: epoch)

        guard !Calendar.current.isDate(now, inSameDayAs: lastReset) else { return }

        store.set(0, forKey: autoCountKey)
        store.set(0, forKey: sharedCountKey)
        store.set(now.timeIntervalSince1970, forKey: lastResetKey)
    }

    // MARK: - RateLimiting

    func canProceed(action: AIAction) async -> Bool {
        resetIfNeeded()
        switch action {
        case .autoSynthesis:
            return store.integer(forKey: autoCountKey) < autoCap
        case .manualRegeneration, .askLumenDashboard:
            return store.integer(forKey: sharedCountKey) < sharedCap
        }
    }

    func consume(action: AIAction) async {
        resetIfNeeded()
        switch action {
        case .autoSynthesis:
            let current = store.integer(forKey: autoCountKey)
            store.set(current + 1, forKey: autoCountKey)
        case .manualRegeneration, .askLumenDashboard:
            let current = store.integer(forKey: sharedCountKey)
            store.set(current + 1, forKey: sharedCountKey)
        }
    }

    func reset() async {
        store.set(0, forKey: autoCountKey)
        store.set(0, forKey: sharedCountKey)
        store.set(clock.now().timeIntervalSince1970, forKey: lastResetKey)
    }
}
