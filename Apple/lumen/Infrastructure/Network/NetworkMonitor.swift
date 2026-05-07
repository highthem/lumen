import Foundation
import Network

actor NetworkMonitor: NetworkReachability {

    private let monitor = NWPathMonitor()
    // NWPathMonitor.start(queue:) requires a DispatchQueue — Apple-API
    // parameter, not used as our own synchronization primitive.
    private let nwQueue = DispatchQueue(label: "com.lumen.networkmonitor")

    private var _isReachable = false

    var isReachable: Bool { _isReachable }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let reachable = path.status == .satisfied
            Task { [weak self] in await self?.didUpdate(reachable: reachable) }
        }
        monitor.start(queue: nwQueue)
    }

    deinit {
        monitor.cancel()
    }

    private func didUpdate(reachable: Bool) {
        _isReachable = reachable
    }
}
