import Foundation

protocol NetworkReachability: Sendable {
    var isReachable: Bool { get async }
}
