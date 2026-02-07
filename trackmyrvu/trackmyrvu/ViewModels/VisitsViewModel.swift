//
//  VisitsViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import Foundation

/// Loads visit history from the backend
@Observable
@MainActor
class VisitsViewModel {
    var visits: [Visit] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    func loadVisits() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            visits = try await apiService.fetchVisits()
        } catch let error as APIError where error == .tokenExpired {
            // Token expired, user should be signed out automatically
            errorMessage = "Session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// Helper for comparing APIError
extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case (.notAuthenticated, .notAuthenticated):
            return true
        case (.tokenExpired, .tokenExpired):
            return true
        case (.server(let lStatus, _), .server(let rStatus, _)):
            return lStatus == rStatus
        case (.decoding, .decoding):
            return true
        default:
            return false
        }
    }
}
