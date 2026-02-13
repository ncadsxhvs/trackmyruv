//
//  AnalyticsView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-12.
//

import SwiftUI

/// Simple analytics view showing total RVU from all visits
struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                contentView
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadTotalRVU()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Total RVU Card
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Total RVU")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.2f", viewModel.totalRVU))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
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
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
}
