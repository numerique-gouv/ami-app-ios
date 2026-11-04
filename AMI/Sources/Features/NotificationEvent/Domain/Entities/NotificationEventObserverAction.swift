//
//  NotificationEventObserverAction.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

typealias NotificationEventObserverAction = @Sendable (NotificationEvent) async -> Void
