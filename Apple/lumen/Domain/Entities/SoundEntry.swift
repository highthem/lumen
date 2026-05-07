import Foundation

enum SoundKind: String, Codable, Sendable {
    case alarm
    case breathing
}

struct SoundEntry: Identifiable, Sendable, Codable {
    let id: String
    let displayKey: String
    let kind: SoundKind
    let filename: String
    let durationSeconds: Int
    let lufsTarget: Int
    let isDefault: Bool
    let ambiance: String?

    var displayName: String {
        let last = displayKey.components(separatedBy: ".").last ?? id
        return last.prefix(1).uppercased() + last.dropFirst()
    }

    var resourceName: String { (filename as NSString).deletingPathExtension }
    var resourceExtension: String { (filename as NSString).pathExtension }
}
