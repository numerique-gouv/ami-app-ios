//
//  TrustChainNode+matches.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

extension TrustChainNode {
    /// Whether the node was extracted from the given certificate,
    /// i.e. whether this pin matches it.
    func matches(_ certificate: SecCertificate) -> Bool {
        Self.extracted(from: certificate) == self
    }
}
