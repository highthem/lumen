import Foundation
import UserNotifications

final class NotificationScheduler: AlarmScheduling {
    private let soundInstaller: NotificationSoundInstaller
    private let contentBuilder: AlarmNotificationContentBuilder

    init(soundProvider: any SoundProviding, soundInstaller: NotificationSoundInstaller) {
        self.soundInstaller = soundInstaller
        let selector = AlarmNotificationSoundSelector(
            soundProvider: soundProvider,
            installedSoundName: { soundId in
                soundInstaller.installedName(for: soundId)
            }
        )
        self.contentBuilder = AlarmNotificationContentBuilder(soundSelector: selector)
    }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(_ alarm: Alarm) async throws {
        let center = UNUserNotificationCenter.current()
        await logSoundSettingIfNeeded(center: center)

        let existingIds = existingIdentifiers(for: alarm.id)
        center.removePendingNotificationRequests(withIdentifiers: existingIds)
        center.removeDeliveredNotifications(withIdentifiers: existingIds)

        let content = contentBuilder.content(for: alarm).notificationContent

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)

        switch alarm.recurrence {
        case .none:
            var fireDate = alarm.time
            if fireDate <= Date() {
                fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
            }
            let fullComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: fullComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )
            try await center.add(request)

        case .everyday:
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )
            try await center.add(request)

        case .weekdays:
            let days = AlarmRecurrence.weekdays.asWeekdaySet
            try await scheduleForDays(days, alarm: alarm, baseContent: content, baseComponents: dateComponents, center: center)

        case .custom(let days):
            try await scheduleForDays(days, alarm: alarm, baseContent: content, baseComponents: dateComponents, center: center)
        }
    }

    private func scheduleForDays(
        _ days: Set<Weekday>,
        alarm: Alarm,
        baseContent: UNMutableNotificationContent,
        baseComponents: DateComponents,
        center: UNUserNotificationCenter
    ) async throws {
        for day in days {
            var components = baseComponents
            components.weekday = day.rawValue
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "\(alarm.id.uuidString)-\(day.rawValue)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: baseContent,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    func cancel(id: UUID) async throws {
        let center = UNUserNotificationCenter.current()
        let prefix = id.uuidString
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered.map(\.request.identifier).filter { $0.hasPrefix(prefix) }
        center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
    }

    func cancelAll() async throws {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func snooze(_ alarm: Alarm, minutes: Int) async throws {
        let center = UNUserNotificationCenter.current()
        await logSoundSettingIfNeeded(center: center)
        let content = contentBuilder.content(for: alarm).notificationContent

        let fireDate = Date().addingTimeInterval(Double(minutes * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-snooze",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    private func logSoundSettingIfNeeded(center: UNUserNotificationCenter) async {
        let settings = await center.notificationSettings()
        if settings.soundSetting == .disabled {
            LumenLog.notifications.warning("Notification sound setting is disabled for Lumen; alarm notification may be silent")
        }
    }

    private func existingIdentifiers(for id: UUID) -> [String] {
        let base = id.uuidString
        var ids = [base, "\(base)-snooze"]
        for day in Weekday.allCases {
            ids.append("\(base)-\(day.rawValue)")
        }
        return ids
    }
}
