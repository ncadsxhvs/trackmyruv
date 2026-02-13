//
//  AnalyticsViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-12.
//

import Foundation

/// Analytics view model - displays total RVU from all visits
@Observable
@MainActor
class AnalyticsViewModel {
    var totalRVU: Double = 0.0
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    /// Load total RVU from all visits
    func loadTotalRVU() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch all visits and calculate total RVU
            let visits = try await apiService.fetchVisits()
            totalRVU = visits.reduce(0.0) { $0 + $1.totalWorkRVU }
            print("📊 [Analytics] Total RVU calculated: \(totalRVU)")
        } catch let error as APIError where error == .tokenExpired {
            errorMessage = "Session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
            totalRVU = 0.0
        }

        isLoading = false
    }

    /// Refresh analytics data
    func refresh() async {
        await loadTotalRVU()
    }
}
