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
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    if let user = authViewModel.currentUser {
                        ProfileHeaderView(user: user)
                    }

                    // RVU summary section
                    RVUSummaryView()

                    // Quick actions section
                    QuickActionsView()

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
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            // Profile image
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            // User info
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - RVU Summary

struct RVUSummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                SummaryCard(title: "Total RVUs", value: "—", color: .blue)
                SummaryCard(title: "This Month", value: "—", color: .green)
                SummaryCard(title: "Encounters", value: "—", color: .orange)
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
                    // TODO: Navigate to entry view
                }

                ActionButton(
                    title: "Visit History",
                    icon: "list.bullet.rectangle",
                    color: .green
                ) {
                    // TODO: Navigate to history view
                }

                ActionButton(
                    title: "Analytics",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    // TODO: Navigate to analytics view
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
            profileImageURL: nil,
            givenName: "Jane",
            familyName: "Smith"
        )
        return vm
    }())
}
