//
//  ContentView.swift
//  RVU Tracker
//
//  Main authenticated view with tab navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            // Home Tab (placeholder)
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Visits Tab (placeholder)
            VisitsPlaceholderView()
                .tabItem {
                    Label("Visits", systemImage: "list.bullet.clipboard.fill")
                }

            // Entry Tab (placeholder)
            EntryPlaceholderView()
                .tabItem {
                    Label("New Visit", systemImage: "plus.circle.fill")
                }

            // Analytics Tab (placeholder)
            AnalyticsPlaceholderView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color("PrimaryColor"))
    }
}

// MARK: - Home View

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("PrimaryColor"))

                Text("Welcome to RVU Tracker")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Track your medical procedures and RVUs")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Home")
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let user = authViewModel.currentUser {
                        HStack {
                            // User Avatar
                            Circle()
                                .fill(Color("PrimaryColor").opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user.initials)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("PrimaryColor"))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)

                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextSecondary"))

                                Text("Signed in with \(user.provider.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Settings") {
                    Button(action: {
                        // TODO: Open settings
                    }) {
                        Label("Preferences", systemImage: "gearshape")
                    }

                    Button(action: {
                        // TODO: Open about
                    }) {
                        Label("About", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        authViewModel.signOut()
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Placeholder Views

struct VisitsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(Color("SecondaryColor"))
                Text("Visits List")
                    .font(.title2)
                    .padding(.top)
                Text("Coming in Milestone 5")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
            .navigationTitle("Visits")
        }
    }
}

struct EntryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color("SecondaryColor"))
                Text("New Visit Entry")
                    .font(.title2)
                    .padding(.top)
                Text("Coming in Milestone 4")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
            .navigationTitle("New Visit")
        }
    }
}

struct AnalyticsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(Color("SecondaryColor"))
                Text("Analytics Dashboard")
                    .font(.title2)
                    .padding(.top)
                Text("Coming in Milestone 9")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
