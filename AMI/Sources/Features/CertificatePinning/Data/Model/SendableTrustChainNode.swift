//
//  SendableTrustChainNode.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

/// `TrustChainNode` + `Sendable`: the existential used at Data/DI
/// boundaries.
///
/// Stated here rather than on the Model protocol on purpose: `Sendable`
/// is a Data-layer portability concern, not part of the domain contract.
typealias SendableTrustChainNode = Sendable & TrustChainNode
