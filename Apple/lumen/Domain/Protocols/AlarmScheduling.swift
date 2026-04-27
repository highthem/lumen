import Foundation

protocol AlarmScheduling: Sendable {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func schedule(_ alarm: Alarm) async throws
    func cancel(id: UUID) async throws
    func cancelAll() async throws
    func snooze(id: UUID, minutes: Int) async throws
}
