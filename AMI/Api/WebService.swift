//
//  WebService.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import Foundation

enum NetworkError: Error {
    case badRequest
    case decodingError
    case badUrl
}

@MainActor
class WebService: ObservableObject {
    @Published var reviewApps: [ReviewApp] = []
    
    func getReviewApps() async throws {
        guard let url = URL(string: Config.shared.BASE_URL + "/dev-utils/review-apps") else {
            throw NetworkError.badUrl
        }
                
        let request = URLRequest(url: url)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        let body = try decoder.decode([ReviewApp].self, from: data)
        self.reviewApps = body
    }
}

