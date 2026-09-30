//
//  ReceivePSLFinalPayloadUseCase.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Decodes a raw PSF final payload and saves it.
struct ReceivePSLFinalPayloadUseCase: Sendable {
    private let decoder: any PSLFinalPayloadDecoding
    private let repository: any PSLFinalPayloadRepository

    init(decoder: any PSLFinalPayloadDecoding, repository: any PSLFinalPayloadRepository) {
        self.decoder = decoder
        self.repository = repository
    }

    /// - Parameter payload: Raw PSF final payload data (JSON bytes).
    /// - Returns: The saved `PSLFinalPayloadType`.
    /// - Throws: `ReceivePSLFinalPayloadError` if decoding or saving fails.
    func execute(payload: Data) async throws(ReceivePSLFinalPayloadError) -> PSLFinalPayloadType {
        let pslPayload: PSLFinalPayloadType
        do {
            pslPayload = try decoder.decode(payload)
        } catch {
            throw .decodingFailed(error)
        }

        do {
            try await repository.save(pslPayload)
        } catch {
            throw .savingFailed
        }

        return pslPayload
    }
}

enum ReceivePSLFinalPayloadError: Error, Equatable, Sendable {
    case decodingFailed(PSLFinalPayloadError)
    case savingFailed
}
