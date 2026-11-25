//
//  URLSessionTrustHandler.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 25/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A `ServerTrustHandler` that can cross concurrency boundaries: the
/// existential type the transport stores and hands to its delegate.
typealias URLSessionTrustHandler = any Sendable & ServerTrustHandler
