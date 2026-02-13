//
//  StatCardsView.swift
//  trackmyrvu
//

import SwiftUI

struct StatCardsView: View {
    let totalRVU: Double
    let totalEncounters: Int
    let totalNoShows: Int
    let avgRVUPerEncounter: Double

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCardView(
                title: "Total RVUs",
                value: String(format: "%.1f", totalRVU),
                icon: "chart.bar.fill",
                color: .blue
            )
            StatCardView(
                title: "Encounters",
                value: "\(totalEncounters)",
                icon: "person.fill",
                color: .green
            )
            StatCardView(
                title: "No Shows",
                value: "\(totalNoShows)",
                icon: "xmark.circle.fill",
                color: .orange
            )
            StatCardView(
                title: "Avg RVU/Enc",
                value: String(format: "%.2f", avgRVUPerEncounter),
                icon: "divide.circle.fill",
                color: .purple
            )
        }
    }
}

private struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
