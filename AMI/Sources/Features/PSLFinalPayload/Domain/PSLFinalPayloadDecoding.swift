//
//  PSLFinalPayloadDecoding.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

protocol PSLFinalPayloadDecoding: Sendable {
    func decode(_ payload: Data) throws(PSLFinalPayloadError) -> PSLFinalPayloadType
}

enum PSLFinalPayloadError: Error, Equatable, Sendable {
    case invalidFormat
}
