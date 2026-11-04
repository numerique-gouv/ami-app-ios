//
//  NotificationEventHandler.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 04/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated protocol NotificationEventHandler {
    func handleReceivedNotificationEvent(event: NotificationEvent) async
}
