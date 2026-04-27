import Foundation

final class JSONQuoteProvider: QuoteProviding, @unchecked Sendable {

    private let quotes: [Quote]
    private let queue = DispatchQueue(label: "com.lumen.quoteprovider", qos: .userInitiated)
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        guard let url = Bundle.main.url(forResource: "Quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
            self.quotes = []
            return
        }
        self.quotes = decoded
    }

    func random(lang: String) -> Quote? {
        queue.sync {
            let filtered = quotes.filter { $0.lang == lang }
            guard !filtered.isEmpty else { return nil }

            let recentKey = "lumen.quotes.recent.\(lang)"
            var recentMap = loadRecentMap(key: recentKey)
            pruneOldEntries(&recentMap)

            let candidates = filtered.filter { recentMap[$0.id.uuidString] == nil }
            let pool = candidates.isEmpty ? filtered : candidates

            guard let chosen = pool.randomElement() else { return nil }

            recentMap[chosen.id.uuidString] = Date().timeIntervalSince1970
            saveRecentMap(recentMap, key: recentKey)
            return chosen
        }
    }

    // MARK: - Helpers

    private func loadRecentMap(key: String) -> [String: TimeInterval] {
        guard let data = userDefaults.data(forKey: key),
              let map = try? JSONDecoder().decode([String: TimeInterval].self, from: data) else {
            return [:]
        }
        return map
    }

    private func saveRecentMap(_ map: [String: TimeInterval], key: String) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func pruneOldEntries(_ map: inout [String: TimeInterval]) {
        let cutoff = Date().timeIntervalSince1970 - (7 * 24 * 3600)
        map = map.filter { $0.value > cutoff }
    }
}
