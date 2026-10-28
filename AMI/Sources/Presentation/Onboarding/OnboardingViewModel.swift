//
//  OnboardingViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 16/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Combine
import Foundation

extension OnboardingView {
    @Observable
    class ViewModel: NSObject {
        enum Action {
            case activate
            case later
            case close
        }

        private var cancellables = Set<AnyCancellable>() // For auto cancelation
        enum Event {
            case isDismissed
        }

        let notificationManager: NotificationManager

        // TODO: use an `AsyncStream` rather than a Combine `PassthroughSubject`.
        typealias EventReceiverType = (Event) -> Void
        private let eventsStream = PassthroughSubject<Event, Never>()
        var eventReceiver: EventReceiverType? {
            didSet {
                if let eventReceiver {
                    eventsStream.sink(receiveValue: eventReceiver)
                        .store(in: &cancellables)
                }
            }
        }

        init(notificationManager: NotificationManager) {
            self.notificationManager = notificationManager
        }

        func processAction(_ action: Action) {
            switch action {
            case .activate:
                viewWillDismiss()
                registerForRemoteNotifications()
            case .later:
                viewWillDismiss()
            case .close:
                viewWillDismiss()
            }
        }

        private func registerForRemoteNotifications() {
            Task {
                await notificationManager.registerForRemoteNotifications()
            }
        }

        private func viewWillDismiss() {
            eventsStream.send(.isDismissed)
        }
    }
}
