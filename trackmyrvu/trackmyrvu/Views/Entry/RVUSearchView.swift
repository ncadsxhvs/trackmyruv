//
//  RVUSearchView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import SwiftUI

struct RVUSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String, String, Double) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [RVUCode] = []
    @State private var isSearching = false
    @State private var favoritesViewModel = FavoritesViewModel()

    private let cacheService = RVUCacheService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search HCPCS code or description", text: $searchQuery)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))

                Divider()

                // Search results
                if searchQuery.isEmpty {
                    emptyStateView
                } else if isSearching {
                    loadingView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search Procedures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // Load codes if not loaded
                if !cacheService.isLoaded {
                    await cacheService.loadCodes()
                }
                // Load favorites
                await favoritesViewModel.loadFavorites()
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                performSearch(newValue)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search for HCPCS codes")
                .font(.headline)
            Text("Enter a code (e.g., 99213) or description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No results found")
                .font(.headline)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var resultsList: some View {
        List {
            ForEach(searchResults) { code in
                Button {
                    onSelect(code.hcpcs, code.description, code.statusCode, code.workRVU)
                    dismiss()
                } label: {
                    RVUCodeRow(
                        code: code,
                        searchQuery: searchQuery,
                        isFavorited: favoritesViewModel.isFavorited(code.hcpcs),
                        onToggleFavorite: {
                            Task {
                                await favoritesViewModel.toggleFavorite(code: code)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }

            if searchResults.count >= 100 {
                Section {
                    Text("Showing first 100 results. Refine your search for more specific results.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        // Debounce search
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            // Check if query still matches
            guard query == searchQuery else { return }

            let results = cacheService.search(query: query, limit: 100)
            searchResults = results
            isSearching = false
        }
    }
}

struct RVUCodeRow: View {
    let code: RVUCode
    let searchQuery: String
    let isFavorited: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(code.hcpcs)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Star icon for favorites
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .font(.body)
                        .foregroundStyle(isFavorited ? .yellow : .gray)
                }
                .buttonStyle(.plain)

                Text(String(format: "%.2f RVU", code.workRVU))
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Text(code.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text("Status:")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(code.statusCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RVUSearchView { hcpcs, description, statusCode, workRVU in
        print("Selected: \(hcpcs) - \(description)")
    }
}
