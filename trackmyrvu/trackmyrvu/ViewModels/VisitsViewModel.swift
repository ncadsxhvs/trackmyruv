//
//  VisitsViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import Foundation

/// Loads visit history from the backend with local caching
@Observable
@MainActor
class VisitsViewModel {
    var visits: [Visit] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared
    private let rvuCache = RVUCacheService.shared
    private let cacheKey = "cached_visits"
    private let cacheTimestampKey = "cached_visits_timestamp"
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    func loadVisits() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        // Ensure RVU cache is loaded for enrichment
        await rvuCache.loadCodes()

        // Load from cache first for instant display
        loadFromCache()

        // Then fetch fresh data from API
        do {
            let freshVisits = try await apiService.fetchVisits()
            visits = rvuCache.enrichVisitsWithRVU(freshVisits)
            saveToCache(visits)
        } catch let error as APIError where error == .tokenExpired {
            // Token expired, user should be signed out automatically
            errorMessage = "Session expired. Please sign in again."
        } catch {
            // If we have cached data, keep showing it
            if visits.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func deleteVisit(_ visit: Visit) async -> Bool {
        do {
            // Optimistically remove from list
            if let index = visits.firstIndex(where: { $0.id == visit.id }) {
                visits.remove(at: index)
            }

            // Delete on server
            try await apiService.deleteVisit(id: visit.id)

            // Update cache after successful deletion
            saveToCache(visits)

            return true
        } catch {
            // Restore on error by reloading
            await loadVisits()
            errorMessage = "Failed to delete visit: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Cache Management

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            print("📦 [Cache] No cached visits found")
            return
        }

        // Check if cache is expired
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let age = Date().timeIntervalSince(timestamp)
            if age > cacheExpirationSeconds {
                print("📦 [Cache] Cache expired (age: \(Int(age))s)")
                return
            }
            print("📦 [Cache] Cache age: \(Int(age))s (valid)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cachedVisits = try decoder.decode([Visit].self, from: data)
            visits = cachedVisits
            print("📦 [Cache] Loaded \(cachedVisits.count) visits from cache")
        } catch {
            print("📦 [Cache] Failed to decode cached visits: \(error)")
            // Clear corrupted cache
            UserDefaults.standard.removeObject(forKey: cacheKey)
            UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        }
    }

    private func saveToCache(_ visits: [Visit]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(visits)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            print("📦 [Cache] Saved \(visits.count) visits to cache")
        } catch {
            print("📦 [Cache] Failed to save visits to cache: \(error)")
        }
    }

    /// Clear cached visits (useful for sign out)
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        visits = []
        print("📦 [Cache] Cleared all cached visits")
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
