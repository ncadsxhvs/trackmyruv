//
//  APIService.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import Foundation

/// API client to talk to the Next.js backend using JWT Bearer token auth
actor APIService {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession

    init() {
        #if DEBUG
        // Use production API when local backend is not available
        // Change to http://localhost:3001/api when running backend locally
        let base = URL(string: "https://www.trackmyrvu.com/api")!
        #else
        let base = URL(string: "https://www.trackmyrvu.com/api")!
        #endif

        self.baseURL = base

        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }

    // MARK: - Visits

    func fetchVisits() async throws -> [Visit] {
        let url = baseURL.appending(path: "visits")
        let request = try await makeAuthenticatedRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401 - token expired or invalid
        if httpResponse.statusCode == 401 {
            throw APIError.tokenExpired
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(
                status: httpResponse.statusCode,
                message: decodeAPIErrorMessage(from: data)
            )
        }

        do {
            return try Self.decoder.decode([Visit].self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    // MARK: - Authenticated Requests

    private func makeAuthenticatedRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> URLRequest {
        // Get token from keychain via AuthService
        guard let token = await MainActor.run(body: { AuthService.shared.loadTokenFromKeychain() }) else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Helpers

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private func decodeAPIErrorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = object as? [String: Any],
              let message = dict["error"] as? String else {
            return nil
        }
        return message
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String?)
    case decoding(Error)
    case notAuthenticated
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .server(let status, let message):
            if let message, !message.isEmpty {
                return "Request failed (\(status)): \(message)"
            } else {
                return "Request failed with status code \(status)"
            }
        case .decoding:
            return "Unable to parse server response"
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .tokenExpired:
            return "Session expired. Please sign in again."
        }
    }
}
