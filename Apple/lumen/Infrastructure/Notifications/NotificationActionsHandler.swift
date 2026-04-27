import Foundation
import UserNotifications

@MainActor
final class NotificationActionsHandler: NSObject, UNUserNotificationCenterDelegate {
    let snooze: SnoozeAlarm
    let cancel: CancelAlarm
    let appState: AppStateMachine

    init(snooze: SnoozeAlarm, cancel: CancelAlarm, appState: AppStateMachine) {
        self.snooze = snooze
        self.cancel = cancel
        self.appState = appState
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let rawId = response.notification.request.identifier
        let baseId = extractBaseUUID(from: rawId)
        let actionId = response.actionIdentifier

        guard let uuid = UUID(uuidString: baseId) else {
            completionHandler()
            return
        }

        let snooze = self.snooze
        let cancel = self.cancel
        let appState = self.appState

        Task {
            switch actionId {
            case LumenNotificationAction.snooze.rawValue:
                try? await snooze.execute(alarmId: uuid)

            case LumenNotificationAction.silence.rawValue:
                try? await cancel.execute(alarmId: uuid)
                await appState.send(.alarmSilenced)

            default:
                await appState.send(.alarmFired(alarmId: uuid))
            }
            completionHandler()
        }
    }

    private nonisolated func extractBaseUUID(from identifier: String) -> String {
        let suffixes = ["-snooze"] + Weekday.allCases.map { "-\($0.rawValue)" }
        for suffix in suffixes {
            if identifier.hasSuffix(suffix) {
                return String(identifier.dropLast(suffix.count))
            }
        }
        return identifier
    }
}
