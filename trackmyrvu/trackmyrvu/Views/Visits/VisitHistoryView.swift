//
//  VisitHistoryView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import SwiftUI

struct VisitHistoryView: View {
    @State private var viewModel = VisitsViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                loadingRow
            } else if let error = viewModel.errorMessage {
                errorRow(error)
            } else if viewModel.visits.isEmpty {
                emptyRow
            } else {
                ForEach(viewModel.visits) { visit in
                    VisitRowView(visit: visit)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Visit History")
        .task {
            await viewModel.loadVisits()
        }
        .refreshable {
            await viewModel.loadVisits()
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Loading visits...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private func errorRow(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unable to load visits")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var emptyRow: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No visits yet")
                .font(.headline)
            Text("Create your first visit to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 48)
    }
}

struct VisitRowView: View {
    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Date, time, and no-show badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(visit.date))
                        .font(.headline)
                    if let time = visit.time, !time.isEmpty {
                        Text(time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if visit.isNoShow {
                    Text("No Show")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.orange.opacity(0.15))
                        )
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.2f RVU", visit.totalWorkRVU))
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("\(visit.procedures.count) procedure\(visit.procedures.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Notes
            if let notes = visit.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Procedures list (show up to 3)
            if !visit.procedures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(visit.procedures.prefix(3)) { procedure in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(procedure.hcpcs)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(procedure.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f", procedure.workRVU))
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Text("×\(procedure.quantity)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.05))
                        )
                    }

                    if visit.procedures.count > 3 {
                        Text("+\(visit.procedures.count - 3) more procedure\(visit.procedures.count - 3 == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse YYYY-MM-DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }

        return dateString
    }
}

#Preview {
    NavigationStack {
        VisitHistoryView()
    }
}
