//
//  TrustChainNode.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated protocol TrustChainNode: Hashable {
    var data: Data { get }

    static func extracted(from certificate: SecCertificate) -> Self?
}
