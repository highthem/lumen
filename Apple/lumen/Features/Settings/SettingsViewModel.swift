import Foundation
import Observation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case dark
    case light

    /// UserDefaults key shared between the Settings VM and the root SwiftUI view.
    static let storageKey = "lumen.settings.appearance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Système"
        case .dark:   return "Sombre"
        case .light:  return "Clair"
        }
    }

    /// `nil` means "follow system" — that's what `.preferredColorScheme(nil)` expects.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

struct SpeedOption: Identifiable, Hashable, Sendable {
    let id: Double
    let label: String
}

@MainActor
@Observable
final class SettingsViewModel {
    var voiceModeEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceModeEnabled, forKey: voiceDefaultKey) }
    }
    var selectedVoiceId: String {
        didSet { UserDefaults.standard.set(selectedVoiceId, forKey: voiceIdKey) }
    }
    var selectedSpeed: SpeedOption
    var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: AppAppearance.storageKey) }
    }
    var availableVoices: [TTSVoice] = []

    let speedOptions: [SpeedOption] = [
        SpeedOption(id: 0.8, label: "Lent"),
        SpeedOption(id: 1.0, label: "Normal"),
        SpeedOption(id: 1.2, label: "Rapide")
    ]

    private let tts: any TextToSpeeching
    private let exportLogs: ExportEthicalLogs
    private let eraseLogs: EraseEthicalLogs
    private let voiceDefaultKey = "lumen.settings.voiceDefault"
    private let voiceIdKey = "lumen.settings.voiceId"

    init(tts: any TextToSpeeching, exportLogs: ExportEthicalLogs, eraseLogs: EraseEthicalLogs) {
        self.tts = tts
        self.exportLogs = exportLogs
        self.eraseLogs = eraseLogs

        // M1: default ON when key has never been set
        self.voiceModeEnabled = (UserDefaults.standard.object(forKey: "lumen.settings.voiceDefault") as? Bool) ?? true

        let storedAppearance = UserDefaults.standard.string(forKey: AppAppearance.storageKey)
            .flatMap { AppAppearance(rawValue: $0) } ?? .system
        self.appearance = storedAppearance

        self.selectedSpeed = SpeedOption(id: 1.0, label: "Normal")

        // M2: pick FR voice by default; resolved in load() when voices are available
        let persisted = UserDefaults.standard.string(forKey: "lumen.settings.voiceId")
        self.selectedVoiceId = persisted ?? ""
    }

    func load() {
        availableVoices = tts.availableVoices()
        let persisted = UserDefaults.standard.string(forKey: voiceIdKey)
        if let persisted, availableVoices.contains(where: { $0.id == persisted }) {
            selectedVoiceId = persisted
        } else {
            let preferred = availableVoices.first(where: { $0.lang.hasPrefix("fr") })
            selectedVoiceId = preferred?.id ?? availableVoices.first?.id ?? ""
        }
    }

    func exportLogsFile() async throws -> URL {
        let data = try await exportLogs.execute()

        // Stamp the filename with the current date so multiple exports don't
        // collide and the receiving app shows a meaningful name.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let stamp = formatter.string(from: Date())

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lumen-ethical-logs-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    func eraseAllLogs() async throws {
        try await eraseLogs.execute()
    }
}
