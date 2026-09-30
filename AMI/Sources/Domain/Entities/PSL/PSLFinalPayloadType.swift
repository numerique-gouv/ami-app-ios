//
//  PSLFinalPayloadType.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct PSLFinalPayloadType {
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

/// PSLFinalPayloadType is `Identifiable`for free
/// because i`id` property is present and hashable.
extension PSLFinalPayloadType: Identifiable {}

/// Sample
/// {
///     "dateDebut": "2026-10-07",
///     "dateFin": "2026-10-16",
///     "id" : "SP2-OPTV-A-6-BHQ4CN6S",
///     "type" : "OperationTranquilliteVacances",
///     "partenaire" : "psl",
///     "SIType" : "PN",
///     "SIContact": "COMMISSARIAT DE POLICE DE NANTES",
///     "url" : "https://masecurite.interieur.gouv.fr/fr/trouver-un-commissariat-une-gendarmerie",
///     "recapPDF": "BASE64 string>"
/// }
