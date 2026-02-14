//
//  AuthViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation
import SwiftUI

/// Observable view model for authentication state
@Observable
@MainActor
class AuthViewModel {
    var currentUser: User?
    var sessionToken: String?
    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService.shared

    var isSignedIn: Bool {
        currentUser != nil && sessionToken != nil
    }

    init() {
        checkAuthStatus()
    }

    /// Check if user is already signed in
    func checkAuthStatus() {
        Task {
            do {
                // Try to restore session token from keychain
                if let token = try await authService.restorePreviousSignIn() {
                    sessionToken = token
                    // Token exists, create placeholder user
                    // Real user data will be fetched from API
                    currentUser = User(id: "", email: "", name: nil, image: nil)
                } else {
                    currentUser = nil
                    sessionToken = nil
                }
            } catch {
                currentUser = nil
                sessionToken = nil
            }
        }
    }

    /// Sign in with Google and authenticate with backend
    func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            let (user, token) = try await authService.signIn()
            currentUser = user
            sessionToken = token
        } catch {
            errorMessage = error.localizedDescription
            currentUser = nil
            sessionToken = nil
        }

        isLoading = false
    }

    /// Sign out and clear all cached data
    func signOut() {
        authService.signOut()
        currentUser = nil
        sessionToken = nil

        // Clear all UserDefaults cache
        clearAllCaches()
    }

    /// Clear all cached data (visits, favorites, etc.)
    private func clearAllCaches() {
        // Clear all Keychain-stored caches (visits, favorites)
        SecureCache.deleteAll()

        // Clear non-sensitive metadata from UserDefaults
        UserDefaults.standard.removeObject(forKey: "cached_visits_timestamp")
        UserDefaults.standard.removeObject(forKey: "cached_favorites_version")
    }
}
