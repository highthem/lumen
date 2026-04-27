import Foundation
import UserNotifications

enum LumenNotificationCategory: String {
    case alarm = "LUMEN_ALARM"
}

enum LumenNotificationAction: String {
    case snooze = "LUMEN_SNOOZE"
    case silence = "LUMEN_SILENCE"
}

extension LumenNotificationCategory {
    static func registerAll() {
        let snoozeAction = UNNotificationAction(
            identifier: LumenNotificationAction.snooze.rawValue,
            title: "Snooze 5 min",
            options: []
        )
        let silenceAction = UNNotificationAction(
            identifier: LumenNotificationAction.silence.rawValue,
            title: "Silence",
            options: [.destructive]
        )
        let alarmCategory = UNNotificationCategory(
            identifier: LumenNotificationCategory.alarm.rawValue,
            actions: [snoozeAction, silenceAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}
