//
//  HCPCSBreakdownView.swift
//  trackmyrvu
//

import SwiftUI

struct HCPCSBreakdownView: View {
    let breakdowns: [PeriodBreakdown]
    let isFiltered: Bool
    var onShowAll: (() -> Void)?

    var body: some View {
        if breakdowns.isEmpty {
            emptyState
        } else {
            breakdownList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No procedures for selected range")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var breakdownList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isFiltered {
                Button {
                    onShowAll?()
                } label: {
                    Label("Show All Periods", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                }
                .padding(.horizontal)
            }

            ForEach(breakdowns) { breakdown in
                VStack(alignment: .leading, spacing: 8) {
                    // Section header
                    HStack {
                        Text(breakdown.periodLabel)
                            .font(.headline)
                        Spacer()
                        Text("\(breakdown.rows.count) procedure\(breakdown.rows.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Rows
                    ForEach(breakdown.rows) { row in
                        HStack(spacing: 8) {
                            Text(row.hcpcs)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 60, alignment: .leading)

                            Text(row.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Spacer()

                            Text("x\(row.totalQuantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)

                            Text(String(format: "%.1f", row.totalWorkRVU))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .frame(width: 50, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }

                    Divider()
                }
            }
        }
    }
}
