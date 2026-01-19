//
//  track_my_rvuApp.swift
//  RVU Tracker
//
//  App entry point with authentication flow
//

import SwiftUI

@main
struct RVUTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    // Main app content (authenticated)
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    // Sign-in screen (not authenticated)
                    SignInView()
                }
            }
            .onAppear {
                Task {
                    await authViewModel.checkAuthStatus()
                }
            }
        }
    }
}
