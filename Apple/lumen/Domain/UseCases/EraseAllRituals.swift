import Foundation

/// Wipes every persisted ritual + clears the "user has any ritual" flag so
/// the Dashboard collapses back to its Idle/Empty state on next refresh.
struct EraseAllRituals: Sendable {
    let repository: any RitualRepository

    init(repository: any RitualRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteAll()
        UserDefaults.standard.set(false, forKey: "lumen.hasAnyRitual")
    }
}
