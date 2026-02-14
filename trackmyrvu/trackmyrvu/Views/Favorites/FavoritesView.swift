//
//  FavoritesView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import SwiftUI

/// View displaying favorite HCPCS codes with drag-to-reorder
struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()
    @State private var isEditMode = false
    @State private var hasLoaded = false

    /// Callback when user taps a favorite to add to visit
    let onSelect: (RVUCode) -> Void

    private let cacheService = RVUCacheService.shared

    var body: some View {
        Group {
            // Content
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.favorites.isEmpty {
                emptyState
            } else {
                    favoritesList
            }
        }
        .task(id: hasLoaded) {
            guard !hasLoaded else { return }
            await cacheService.loadCodes()
            await viewModel.loadFavorites()
            hasLoaded = true
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading favorites...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                Task {
                    await viewModel.loadFavorites()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No favorites yet")
                .font(.headline)

            Text("Star frequently used codes for quick access")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Favorites List

    private var favoritesList: some View {
        ForEach(viewModel.favorites) { favorite in
            FavoriteRow(
                favorite: favorite,
                isEditMode: isEditMode,
                rvuCode: lookupCode(hcpcs: favorite.hcpcs)
            ) {
                // Look up full details and call onSelect
                if let code = lookupCode(hcpcs: favorite.hcpcs) {
                    onSelect(code)
                }
            }
        }
        .onDelete { indexSet in
            viewModel.delete(at: indexSet)
        }
        .onMove { source, destination in
            viewModel.reorder(from: source, to: destination)
        }
    }

    /// Look up full HCPCS code details from cache
    private func lookupCode(hcpcs: String) -> RVUCode? {
        cacheService.codes.first(where: { $0.hcpcs == hcpcs })
    }
}

// MARK: - Favorite Row

struct FavoriteRow: View {
    let favorite: Favorite
    let isEditMode: Bool
    let rvuCode: RVUCode?
    let onTap: () -> Void

    var body: some View {
        Button(action: isEditMode ? {} : onTap) {
            HStack(spacing: 12) {
                // Star icon
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)

                // HCPCS and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.hcpcs)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let code = rvuCode {
                        Text(code.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }

                Spacer()

                // Work RVU
                if let code = rvuCode {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", code.workRVU))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)

                        Text("RVU")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(isEditMode || rvuCode == nil)
    }
}

// MARK: - Previews

#Preview("With Favorites") {
    NavigationStack {
        VStack {
            FavoritesView { code in
                print("Selected: \(code.hcpcs)")
            }

            Spacer()
        }
    }
}

#Preview("Empty State") {
    NavigationStack {
        VStack {
            FavoritesView { code in
                print("Selected: \(code.hcpcs)")
            }

            Spacer()
        }
    }
}
