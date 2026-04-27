import Foundation

protocol AlarmRepository: Sendable {
    func all() async throws -> [Alarm]
    func fetch(id: UUID) async throws -> Alarm?
    func save(_ alarm: Alarm) async throws
    func update(_ alarm: Alarm) async throws
    func delete(id: UUID) async throws
    func setActive(id: UUID, isActive: Bool) async throws
}
