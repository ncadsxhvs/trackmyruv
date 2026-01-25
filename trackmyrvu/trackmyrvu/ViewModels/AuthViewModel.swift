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
    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService.shared

    var isSignedIn: Bool {
        currentUser != nil
    }

    init() {
        checkAuthStatus()
    }

    /// Check if user is already signed in
    func checkAuthStatus() {
        Task {
            do {
                currentUser = try await authService.restorePreviousSignIn()
            } catch {
                // No previous session, user needs to sign in
                currentUser = nil
            }
        }
    }

    /// Sign in with Google
    func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            currentUser = try await authService.signIn()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Sign out
    func signOut() {
        authService.signOut()
        currentUser = nil
    }
}
