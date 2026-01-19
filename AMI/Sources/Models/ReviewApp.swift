//
//  ReviewApp.swift
//  AMI
//
//  Created by Aline Bonnet on 07/12/2025.
//

import Foundation

struct ReviewApp: Decodable, Identifiable {
    var id: String = UUID().uuidString
    let url: String
    let title: String
    let number: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case number
        case description
    }
}
