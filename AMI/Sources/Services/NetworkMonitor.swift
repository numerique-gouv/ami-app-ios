import Foundation
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Network status changed to \(path.status)")
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}

extension NWPath.Status: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .requiresConnection: "requires connection"
        case .satisfied: "satisfied"
        case .unsatisfied: "unsatisfied"
        @unknown default: "unknown NWPath.Status"
        }
    }
}
