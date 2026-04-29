//
//  Config.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//
import Foundation

final class Config {
    static let shared = Config()

    #if IS_AMI_STAGING
        let BASE_URL = URL(string: "https://ami-back-staging.osc-fr1.scalingo.io/")!
        let OIDC_HOSTS = [
            "fcp-low.sbx.dev-franceconnect.fr",
            "fip1-low.sbx.fcp.fournisseur-d-identite.fr", // Démo eIDAS faible
            "auth.vip.cnav.fr", // CNAV
            "franceconnect.gouv.fr", // Utilisé par le bouton "Revenir sur AMI" de dev-franceconnect.fr
            "ami-fc-proxy-dev.osc-fr1.scalingo.io", // Utilisé par le bouton "Revenir sur AMI" de dev-franceconnect.fr
        ]
    #elseif IS_AMI_PRODUCTION
        let BASE_URL = URL(string: "https://ami-back-prod.osc-secnum-fr1.scalingo.io/")!
        let OIDC_HOSTS = [
            "oidc.franceconnect.gouv.fr",
            "cfspart-idp.impots.gouv.fr", // FI impots.gouv.fr
            "fc.assure.ameli.fr", // FI Assurance maladie
            "authent.lidentitenumerique.laposte.fr", // FI L'identité Numérique La Poste
            "idp.msa.fr", // FI MSA
            "idp.yris.eu", // FI Yris (plus disponbile à partir du 01/07/2026)
            "idp.france-identite.gouv.fr", // FI Francae Identité
            "oidc.a3bc.io", // FI trustme
        ]
    #endif

    private init() {}
}
