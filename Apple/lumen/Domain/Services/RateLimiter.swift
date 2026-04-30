import Foundation

// UserDefaults is @MainActor in Swift 6; wrap access in nonisolated(unsafe)
// so the actor can mutate it from its own executor without races (single-writer via actor).
actor RateLimiter: RateLimiting {

    private let autoCountKey      = "lumen.ratelimiter.autoCount"
    private let regenCountKey     = "lumen.ratelimiter.regenCount"
    private let askLumenCountKey  = "lumen.ratelimiter.askLumenCount"
    private let lastResetKey      = "lumen.ratelimiter.lastResetEpoch"
    // Legacy key from before the regen/askLumen split — read once on migration.
    private let legacySharedKey   = "lumen.ratelimiter.sharedCount"

    private let autoCap     = 1
    private let regenCap    = 3
    private let askLumenCap = 3

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
        store.set(0, forKey: regenCountKey)
        store.set(0, forKey: askLumenCountKey)
        store.set(0, forKey: legacySharedKey)
        store.set(now.timeIntervalSince1970, forKey: lastResetKey)
    }

    // MARK: - RateLimiting

    func canProceed(action: AIAction) async -> Bool {
        resetIfNeeded()
        return remainingSlots(action: action) > 0
    }

    func consume(action: AIAction) async {
        resetIfNeeded()
        let key = key(for: action)
        store.set(store.integer(forKey: key) + 1, forKey: key)
    }

    func reset() async {
        store.set(0, forKey: autoCountKey)
        store.set(0, forKey: regenCountKey)
        store.set(0, forKey: askLumenCountKey)
        store.set(0, forKey: legacySharedKey)
        store.set(clock.now().timeIntervalSince1970, forKey: lastResetKey)
    }

    func remainingSlots(action: AIAction) -> Int {
        let cap = cap(for: action)
        let used = store.integer(forKey: key(for: action))
        return max(0, cap - used)
    }

    /// One-shot reset hook for app upgrades. Callers can use this when changing
    /// the rate-limit shape (e.g. splitting a shared counter) so existing users
    /// don't get stuck on yesterday's stale state.
    func resetAllForMigration() async {
        await reset()
    }

    // MARK: - Helpers

    private func key(for action: AIAction) -> String {
        switch action {
        case .autoSynthesis:        return autoCountKey
        case .manualRegeneration:   return regenCountKey
        case .askLumenDashboard:    return askLumenCountKey
        }
    }

    private func cap(for action: AIAction) -> Int {
        switch action {
        case .autoSynthesis:        return autoCap
        case .manualRegeneration:   return regenCap
        case .askLumenDashboard:    return askLumenCap
        }
    }
}
