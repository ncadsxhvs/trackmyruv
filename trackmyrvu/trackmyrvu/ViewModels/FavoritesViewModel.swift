//
//  FavoritesViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import Foundation
import SwiftUI

/// Manages favorites state and API interactions
@Observable
@MainActor
class FavoritesViewModel {
    private(set) var favorites: [Favorite] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let apiService = APIService.shared
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_favorites"
    private let cacheVersionKey = "cached_favorites_version"
    private let currentCacheVersion = 4 // Fixed CodingKeys conflict with snake_case decoder

    init() {
        // Clear cache if version mismatch (model changed)
        let cachedVersion = userDefaults.integer(forKey: cacheVersionKey)
        if cachedVersion != currentCacheVersion {
            print("🔄 [Favorites] Cache version mismatch (\(cachedVersion) != \(currentCacheVersion)), clearing cache")
            clearCache()
            userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        } else {
            loadFromCache()
        }
    }

    // MARK: - Query Methods

    /// Check if a HCPCS code is favorited
    func isFavorited(_ hcpcs: String) -> Bool {
        favorites.contains(where: { $0.hcpcs == hcpcs })
    }

    /// Get favorite by HCPCS code
    func getFavorite(hcpcs: String) -> Favorite? {
        favorites.first(where: { $0.hcpcs == hcpcs })
    }

    // MARK: - Load Favorites

    /// Load favorites from server
    func loadFavorites() async {
        isLoading = true
        errorMessage = nil

        print("🔄 [Favorites] Loading favorites from server...")

        do {
            favorites = try await apiService.fetchFavorites()
            print("✅ [Favorites] Loaded \(favorites.count) favorites: \(favorites.map { $0.hcpcs })")
            saveToCache()
        } catch is CancellationError {
            print("⚠️ [Favorites] Request cancelled (view recreated)")
        } catch let urlError as URLError where urlError.code == .cancelled {
            print("⚠️ [Favorites] URL request cancelled (view recreated)")
        } catch let error as APIError where error == .tokenExpired {
            print("❌ [Favorites] Token expired")
            errorMessage = "Session expired. Please sign in again."
        } catch {
            print("❌ [Favorites] Error: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Add Favorite

    /// Add a favorite from RVUCode
    func addFavorite(code: RVUCode) async -> Bool {
        // Check if already favorited
        guard !isFavorited(code.hcpcs) else {
            return true
        }

        let request = CreateFavoriteRequest(hcpcs: code.hcpcs)

        do {
            let newFavorite = try await apiService.createFavorite(request)
            favorites.append(newFavorite)
            saveToCache()
            return true
        } catch {
            errorMessage = "Failed to add favorite: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Remove Favorite

    /// Remove favorite by HCPCS code
    func removeFavorite(hcpcs: String) async -> Bool {
        do {
            // Optimistically remove from list
            if let index = favorites.firstIndex(where: { $0.hcpcs == hcpcs }) {
                favorites.remove(at: index)
            }

            try await apiService.deleteFavorite(hcpcs: hcpcs)
            saveToCache()
            return true
        } catch {
            // Restore on error by reloading
            await loadFavorites()
            errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Toggle Favorite

    /// Toggle favorite (add if not exists, remove if exists)
    func toggleFavorite(code: RVUCode) async -> Bool {
        if isFavorited(code.hcpcs) {
            return await removeFavorite(hcpcs: code.hcpcs)
        } else {
            return await addFavorite(code: code)
        }
    }

    // MARK: - Reorder

    /// Reorder favorites after drag-and-drop
    func reorder(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)

        // Update sort orders
        for (index, favorite) in favorites.enumerated() {
            // Note: We're just reordering the array locally
            // The actual sortOrder will be updated when syncing
        }

        Task {
            await syncOrder()
        }
    }

    /// Delete favorites at indices
    func delete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let hcpcs = favorites[index].hcpcs
                await removeFavorite(hcpcs: hcpcs)
            }
        }
    }

    // MARK: - Sync Order

    /// Sync reordered favorites to server
    private func syncOrder() async {
        let orders = favorites.enumerated().map { index, favorite in
            ReorderFavoritesRequest.FavoriteOrder(
                hcpcs: favorite.hcpcs,
                sortOrder: index
            )
        }

        let request = ReorderFavoritesRequest(favorites: orders)

        do {
            try await apiService.reorderFavorites(request)

            // Update local favorites with new sort order
            for (index, _) in favorites.enumerated() {
                // Create new favorites array with updated sort orders
                // Note: Server will return updated favorites on next fetch
            }

            saveToCache()
        } catch {
            errorMessage = "Failed to sync order: \(error.localizedDescription)"
            // Reload to get correct order from server
            await loadFavorites()
        }
    }

    // MARK: - Local Cache

    /// Save favorites to UserDefaults for offline access
    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            userDefaults.set(encoded, forKey: cacheKey)
            userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        }
    }

    /// Load favorites from UserDefaults cache
    private func loadFromCache() {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            print("📭 [Favorites] No cached data found")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([Favorite].self, from: data)
            favorites = decoded
            print("✅ [Favorites] Loaded \(decoded.count) favorites from cache")
        } catch {
            print("❌ [Favorites] Failed to decode cache: \(error)")
            print("🗑️ [Favorites] Clearing corrupted cache")
            clearCache()
        }
    }

    /// Clear cache
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
        favorites = []
    }
}
