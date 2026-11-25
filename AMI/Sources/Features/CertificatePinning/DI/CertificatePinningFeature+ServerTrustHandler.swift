//
//  CertificatePinningFeature+ServerTrustHandler.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 25/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Plays the Core `ServerTrustHandler` role: `evaluate(challenge:)` already
/// matches the port's requirement, so the conformance adds no members.
extension CertificatePinningFeature: ServerTrustHandler {}
