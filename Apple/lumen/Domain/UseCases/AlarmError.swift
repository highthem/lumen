import Foundation

enum AlarmError: Error, Equatable, Sendable {
    case snoozeCapReached
    case notFound
    case persistenceFailed
    case schedulingFailed
}
