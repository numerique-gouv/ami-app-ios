//
//  ServerTrustURLSession.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 25/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A `URLSession` that routes every auth challenge to an injected
/// `ServerTrustHandler` (e.g. the CertificatePinning feature) instead of
/// letting the system decide alone.
///
/// With a `nil` handler the session degrades to plain system validation
/// (`.performDefaultHandling` on every challenge), so one session type
/// serves pinned and unpinned environments alike.
final class ServerTrustURLSession: Sendable {
    private let session: URLSession

    /// - Parameters:
    ///   - handler: decides the challenges; `nil` = system default validation only.
    ///   - configuration: session configuration (`.default` in the app).
    init(handler: URLSessionTrustHandler?, configuration: URLSessionConfiguration) {
        // URLSession holds its delegate strongly until the session is invalidated,
        // so the transient delegate does not need a stored reference here.
        session = URLSession(configuration: configuration,
                             delegate: ServerTrustURLSessionDelegate(handler: handler),
                             delegateQueue: nil)
    }

    /// Performs a data request under the session's trust policy.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
