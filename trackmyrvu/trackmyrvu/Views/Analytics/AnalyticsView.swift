//
//  AnalyticsView.swift
//  trackmyrvu
//

import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.allVisits.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.allVisits.isEmpty {
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
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                dateRangeSection
                periodPicker
                statCards

                Picker("Tab", selection: $viewModel.activeTab) {
                    ForEach(AnalyticsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch viewModel.activeTab {
                case .summary:
                    AnalyticsChartView(
                        summaries: viewModel.periodSummaries,
                        selectedIndex: viewModel.selectedPeriodIndex,
                        onBarTapped: { index in
                            viewModel.selectBar(at: index)
                        }
                    )
                    .padding(.horizontal)

                case .breakdown:
                    HCPCSBreakdownView(
                        breakdowns: viewModel.periodBreakdowns,
                        isFiltered: viewModel.selectedPeriodIndex != nil,
                        onShowAll: { viewModel.clearBarFilter() }
                    )
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Date Range

    private var dateRangeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("From")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                    .labelsHidden()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("To")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.period) {
            ForEach(AnalyticsPeriod.allCases) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel.period) {
            viewModel.onPeriodChanged()
        }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        StatCardsView(
            totalRVU: viewModel.totalRVU,
            totalEncounters: viewModel.totalEncounters,
            totalNoShows: viewModel.totalNoShows,
            avgRVUPerEncounter: viewModel.avgRVUPerEncounter
        )
        .padding(.horizontal)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error

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
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
