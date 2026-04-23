import Combine
import Foundation
import Network

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum EventType {
        case connected
        case notConnected
    }

    typealias EventReceiverType = (EventType) -> Void
    private let eventsStream = PassthroughSubject<EventType, Never>()
    private var cancellables = Set<AnyCancellable>() // For auto cancelation
    var eventReceiver: EventReceiverType? {
        didSet {
            if let eventReceiver {
                eventsStream.sink(receiveValue: eventReceiver)
                    .store(in: &cancellables)
            }
        }
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.eventsStream.send(path.status == .satisfied ? .connected : .notConnected)
        }
        monitor.start(queue: queue)
    }
}
