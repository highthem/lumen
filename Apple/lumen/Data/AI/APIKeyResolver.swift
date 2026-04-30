import Foundation

enum APIKeyResolver {
    static func resolve(infoKey: String) throws -> String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            throw AIError.missingAPIKey
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid(key) else {
            throw AIError.missingAPIKey
        }
        return key
    }

    static func isPresent(infoKey: String) -> Bool {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String else {
            return false
        }
        return isValid(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func isValid(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        if key.hasPrefix("REPLACE_ME") { return false }
        if key.hasPrefix("$(") { return false }
        if key == "MISSING_IN_CI" { return false }
        return true
    }
}
