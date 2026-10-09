//
//  AppRoute.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// An application screen, identified without reference to any router,
/// UI framework, or navigation state.
///
/// Domain-level vocabulary: features name routes (e.g. as a promoted
/// URL's native destination); the app's router (when built) maps
/// routes to concrete screens. This type knows nothing about screens.
enum AppRoute: Hashable, Sendable {
    case franceConnect
    case amiApplication
    case amiNotificationsSettings
    case allowNotifications
    case service(ServiceProvider)
}
