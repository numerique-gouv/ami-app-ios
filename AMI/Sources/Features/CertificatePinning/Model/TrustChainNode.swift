//
//  TrustChainNode.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A unit of the trust chain a pin can match against.
///
/// Conformances expose their identifying material as `data` and re-derive
/// themselves from a live certificate via `extracted(from:)` — `nil` when
/// this node kind cannot be derived from the certificate. `Hashable` is
/// what lets `matches(_:)` compare an extracted node with a stored pin.
nonisolated protocol TrustChainNode: Hashable {
    var data: Data { get }

    static func extracted(from certificate: SecCertificate) -> Self?
}
