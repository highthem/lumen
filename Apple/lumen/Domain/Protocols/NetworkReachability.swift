import Foundation

protocol NetworkReachability: Sendable {
    var isReachable: Bool { get }
    func updates() -> AsyncStream<Bool>
}
