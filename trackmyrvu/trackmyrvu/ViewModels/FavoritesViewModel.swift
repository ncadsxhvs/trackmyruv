//
//  FavoritesViewModel.swift
//  trackmyrvu
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
    private let currentCacheVersion = 4

    init() {
        let cachedVersion = userDefaults.integer(forKey: cacheVersionKey)
        if cachedVersion != currentCacheVersion {
            clearCache()
            userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        } else {
            loadFromCache()
        }
    }

    // MARK: - Query Methods

    func isFavorited(_ hcpcs: String) -> Bool {
        favorites.contains(where: { $0.hcpcs == hcpcs })
    }

    func getFavorite(hcpcs: String) -> Favorite? {
        favorites.first(where: { $0.hcpcs == hcpcs })
    }

    // MARK: - Load Favorites

    func loadFavorites() async {
        isLoading = true
        errorMessage = nil

        do {
            favorites = try await apiService.fetchFavorites()
            saveToCache()
        } catch is CancellationError {
            // View was recreated, ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URL request cancelled due to view recreation, ignore
        } catch let error as APIError where error == .tokenExpired {
            errorMessage = "Session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Add Favorite

    func addFavorite(code: RVUCode) async -> Bool {
        guard !isFavorited(code.hcpcs) else { return true }

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

    func removeFavorite(hcpcs: String) async -> Bool {
        do {
            if let index = favorites.firstIndex(where: { $0.hcpcs == hcpcs }) {
                favorites.remove(at: index)
            }

            try await apiService.deleteFavorite(hcpcs: hcpcs)
            saveToCache()
            return true
        } catch {
            await loadFavorites()
            errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(code: RVUCode) async -> Bool {
        if isFavorited(code.hcpcs) {
            return await removeFavorite(hcpcs: code.hcpcs)
        } else {
            return await addFavorite(code: code)
        }
    }

    // MARK: - Reorder

    func reorder(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)

        Task {
            await syncOrder()
        }
    }

    func delete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let hcpcs = favorites[index].hcpcs
                await removeFavorite(hcpcs: hcpcs)
            }
        }
    }

    // MARK: - Sync Order

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
            saveToCache()
        } catch {
            errorMessage = "Failed to sync order: \(error.localizedDescription)"
            await loadFavorites()
        }
    }

    // MARK: - Local Cache

    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            userDefaults.set(encoded, forKey: cacheKey)
            userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        }
    }

    private func loadFromCache() {
        guard let data = userDefaults.data(forKey: cacheKey) else { return }

        do {
            favorites = try JSONDecoder().decode([Favorite].self, from: data)
        } catch {
            clearCache()
        }
    }

    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
        favorites = []
    }
}
