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

        // Hop to MainActor so we can safely touch @MainActor-isolated state.
        // We only capture Sendable values (UUID + String) and call the handler
        // there — never blocking on UI-restoration work that might assert
        // when the scene is still being connected (lock-screen launch case).
        Task { @MainActor in
            await self.handle(actionId: actionId, alarmId: uuid)
            completionHandler()
        }
    }

    @MainActor
    private func handle(actionId: String, alarmId: UUID) async {
        switch actionId {
        case LumenNotificationAction.snooze.rawValue:
            try? await snooze.execute(alarmId: alarmId)

        case LumenNotificationAction.silence.rawValue:
            try? await cancel.execute(alarmId: alarmId)
            await appState.send(.alarmSilenced)

        default:
            // Default tap (or unknown action) — surface the ringing alarm.
            // RootView gates the actual fullScreenCover on scenePhase == .active
            // so this is safe even when the app is launching from lock screen.
            await appState.send(.alarmFired(alarmId: alarmId))
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
