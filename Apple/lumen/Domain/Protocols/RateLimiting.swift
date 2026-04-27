import Foundation

protocol RateLimiting: Sendable {
    func canProceed(action: AIAction) async -> Bool
    func consume(action: AIAction) async
    func reset() async
}
