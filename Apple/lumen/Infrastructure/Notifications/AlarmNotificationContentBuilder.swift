import Foundation
import UserNotifications

struct AlarmNotificationSoundSelector: Sendable {
    private let soundProvider: any SoundProviding
    private let installedSoundName: @Sendable (String) -> String?

    init(
        soundProvider: any SoundProviding,
        installedSoundName: @escaping @Sendable (String) -> String?
    ) {
        self.soundProvider = soundProvider
        self.installedSoundName = installedSoundName
    }

    func soundName(for alarm: Alarm) -> String? {
        guard let entry = soundProvider.sound(id: alarm.soundId), entry.kind == .alarm else {
            LumenLog.notifications.warning("Alarm sound id \(alarm.soundId) not found in alarm catalog; falling back to default")
            return nil
        }

        guard entry.resourceExtension.lowercased() == "caf" else {
            LumenLog.notifications.warning("Alarm sound \(entry.filename) is not a CAF notification sound; falling back to default")
            return nil
        }

        guard let filename = installedSoundName(alarm.soundId) else {
            LumenLog.notifications.warning("Alarm sound \(entry.filename) could not be installed for notifications; falling back to default")
            return nil
        }

        return filename
    }
}

struct AlarmNotificationContent {
    let notificationContent: UNMutableNotificationContent
    let selectedSoundName: String?
}

struct AlarmNotificationContentBuilder: Sendable {
    private let soundSelector: AlarmNotificationSoundSelector

    init(soundSelector: AlarmNotificationSoundSelector) {
        self.soundSelector = soundSelector
    }

    func content(for alarm: Alarm) -> AlarmNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Lumen"
        content.body = "Bonjour."
        content.categoryIdentifier = LumenNotificationCategory.alarm.rawValue
        content.interruptionLevel = .timeSensitive

        let soundName = soundSelector.soundName(for: alarm)
        if let soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
            LumenLog.notifications.info("Scheduling alarm notification with sound \(soundName)")
        } else {
            content.sound = .default
        }

        return AlarmNotificationContent(notificationContent: content, selectedSoundName: soundName)
    }
}
