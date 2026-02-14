//
//  HomeView.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import SwiftUI

/// Home screen for authenticated users
struct HomeView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var visitsViewModel = VisitsViewModel()
    @State private var showSignOutConfirmation = false
    @State private var navigationPath = NavigationPath()
    @State private var showNewVisit = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // RVU summary section
                    RVUSummaryView(visits: visitsViewModel.visits, isLoading: visitsViewModel.isLoading)

                    // Quick actions section
                    QuickActionsView(
                        navigationPath: $navigationPath,
                        showNewVisit: $showNewVisit
                    )

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("RVU Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "visitHistory":
                    VisitHistoryView()
                case "analytics":
                    AnalyticsView()
                default:
                    Text("Unknown destination")
                }
            }
            .sheet(isPresented: $showNewVisit, onDismiss: {
                Task { await visitsViewModel.loadVisits() }
            }) {
                NewVisitView()
            }
            .task {
                // Load visit history when home view appears
                await visitsViewModel.loadVisits()
            }
        }
    }
}

// MARK: - RVU Summary

struct RVUSummaryView: View {
    let visits: [Visit]
    let isLoading: Bool

    private var totalRVU: Double {
        visits.reduce(0) { $0 + $1.totalWorkRVU }
    }

    private var thisMonthRVU: Double {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        return visits.filter { visit in
            // Parse date string (YYYY-MM-DD or full ISO)
            let dateOnly = String(visit.date.prefix(10))
            let parts = dateOnly.split(separator: "-")
            guard parts.count == 3,
                  let y = Int(parts[0]), let m = Int(parts[1]) else { return false }
            return y == year && m == month
        }
        .reduce(0) { $0 + $1.totalWorkRVU }
    }

    private var totalEncounters: Int {
        visits.filter { !$0.isNoShow }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(.primary)

            if isLoading && visits.isEmpty {
                HStack(spacing: 12) {
                    SummaryCard(title: "Total RVUs", value: "—", color: .blue)
                    SummaryCard(title: "This Month", value: "—", color: .green)
                    SummaryCard(title: "Encounters", value: "—", color: .orange)
                }
                .redacted(reason: .placeholder)
            } else {
                HStack(spacing: 12) {
                    SummaryCard(title: "Total RVUs", value: String(format: "%.1f", totalRVU), color: .blue)
                    SummaryCard(title: "This Month", value: String(format: "%.1f", thisMonthRVU), color: .green)
                    SummaryCard(title: "Encounters", value: "\(totalEncounters)", color: .orange)
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var showNewVisit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ActionButton(
                    title: "New Visit Entry",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showNewVisit = true
                }

                ActionButton(
                    title: "Visit History",
                    icon: "list.bullet.rectangle",
                    color: .green
                ) {
                    navigationPath.append("visitHistory")
                }

                ActionButton(
                    title: "Analytics",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    navigationPath.append("analytics")
                }

            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(authViewModel: {
        let vm = AuthViewModel()
        vm.currentUser = User(
            id: "123",
            email: "doctor@example.com",
            name: "Dr. Jane Smith",
            image: nil
        )
        return vm
    }())
}
