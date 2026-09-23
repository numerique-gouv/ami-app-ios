//
//  ShakeDetector.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 23/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

// Define Shake notification name.
extension UIDevice {
    static let deviceDidShakeNotificationName = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    // Override `motionEnded(_:with:) on UIWIndow level because UIWindow is always in the responder chain.
    // It is possible to override this method in extension because it is an objective-C method.
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotificationName, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// Define View modifier.
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .task {
                for await _ in NotificationCenter.default.notifications(named: UIDevice.deviceDidShakeNotificationName) {
                    action()
                }
            }
    }
}

extension View {
    // Define helper to DeviceShakeViewModifier.
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
}
