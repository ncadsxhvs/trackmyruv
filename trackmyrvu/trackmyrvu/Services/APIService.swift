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
        guard let base = URL(string: "https://www.trackmyrvu.com/api") else {
            fatalError("Invalid API base URL configuration")
        }
        self.baseURL = base

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
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

    func createVisit(_ visitRequest: CreateVisitRequest) async throws -> Visit {
        let url = baseURL.appending(path: "visits")

        // Encode request body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(visitRequest)

        let request = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
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
            return try Self.decoder.decode(Visit.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func updateVisit(id: String, _ visitRequest: CreateVisitRequest) async throws -> Visit {
        let url = baseURL.appending(path: "visits/\(encodedPath(id))")

        // Encode request body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(visitRequest)

        let request = try await makeAuthenticatedRequest(url: url, method: "PUT", body: body)
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
            return try Self.decoder.decode(Visit.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func deleteVisit(id: String) async throws {
        let url = baseURL.appending(path: "visits/\(encodedPath(id))")

        let request = try await makeAuthenticatedRequest(url: url, method: "DELETE")
        let (_, response) = try await session.data(for: request)

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
                message: nil
            )
        }
    }

    // MARK: - Favorites

    func fetchFavorites() async throws -> [Favorite] {
        let url = baseURL.appending(path: "favorites")
        let request = try await makeAuthenticatedRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

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
            return try Self.decoder.decode([Favorite].self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func createFavorite(_ request: CreateFavoriteRequest) async throws -> Favorite {
        let url = baseURL.appending(path: "favorites")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)

        let urlRequest = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

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
            return try Self.decoder.decode(Favorite.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func deleteFavorite(hcpcs: String) async throws {
        let url = baseURL.appending(path: "favorites/\(encodedPath(hcpcs))")

        let request = try await makeAuthenticatedRequest(url: url, method: "DELETE")
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.tokenExpired
        }

        // 204 or 404 both treated as success
        guard [204, 404].contains(httpResponse.statusCode) || (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(status: httpResponse.statusCode, message: nil)
        }
    }

    func reorderFavorites(_ request: ReorderFavoritesRequest) async throws {
        let url = baseURL.appending(path: "favorites/reorder")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)

        let urlRequest = try await makeAuthenticatedRequest(url: url, method: "PATCH", body: body)
        let (_, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.tokenExpired
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(status: httpResponse.statusCode, message: nil)
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

    // MARK: - URL Safety

    private func encodedPath(_ component: String) -> String {
        component.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? component
    }

    // MARK: - Helpers

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Custom date decoding to handle fractional seconds and date-only formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first (for datetime fields)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601 without fractional seconds (for datetime fields)
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try date-only format (YYYY-MM-DD) for analytics periodStart
            formatter.formatOptions = [.withFullDate]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }

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
        case .decoding(let underlying):
            return "Unable to parse server response: \(underlying.localizedDescription)"
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .tokenExpired:
            return "Session expired. Please sign in again."
        }
    }
}
