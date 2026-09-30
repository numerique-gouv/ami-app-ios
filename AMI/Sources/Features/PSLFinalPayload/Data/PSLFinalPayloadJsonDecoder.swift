//
//  PSLFinalPayloadJsonDecoder.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct PSLFinalPayloadJsonDecoder: PSLFinalPayloadDecoding {
    func decode(_ payload: Data) throws(PSLFinalPayloadError) -> PSLFinalPayloadType {
        do {
            let dto = try JSONDecoder().decode(PSLFinalPayloadDTO.self, from: payload)

            return PSLFinalPayloadType(id: dto.id,
                                       dateDebut: dto.dateDebut,
                                       dateFin: dto.dateFin,
                                       type: dto.type,
                                       partenaire: dto.partenaire,
                                       SIType: dto.SIType,
                                       SIContact: dto.SIContact,
                                       url: dto.url,
                                       recapPDF: dto.recapPDF)
        } catch {
            throw .invalidFormat
        }
    }

    /// The intermediate DTO structure.
    private struct PSLFinalPayloadDTO: Decodable {
        let id: String
        let dateDebut: String
        let dateFin: String
        let type: String
        let partenaire: String
        let SIType: String
        let SIContact: String
        let url: String
        let recapPDF: String
    }
}
