import Foundation
import Network

final class NetworkMonitor: NetworkReachability, @unchecked Sendable {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.lumen.networkmonitor")
    private let lock = NSLock()
    nonisolated(unsafe) private var _isReachable: Bool = false
    nonisolated(unsafe) private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    var isReachable: Bool {
        lock.withLock { _isReachable }
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let reachable = path.status == .satisfied
            self.lock.withLock { self._isReachable = reachable }
            self.lock.withLock {
                for continuation in self.continuations.values {
                    continuation.yield(reachable)
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    func updates() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.lock.withLock {
                self.continuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.continuations.removeValue(forKey: id)
                }
            }
            // Emit current state immediately
            continuation.yield(self.isReachable)
        }
    }
}
