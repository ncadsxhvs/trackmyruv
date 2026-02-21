//
//  AuthViewModel.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation
import AuthenticationServices
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
                if let token = try await authService.restorePreviousSignIn() {
                    sessionToken = token
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

    /// Handle Apple Sign-In completion from SignInWithAppleButton
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let (user, token) = try await authService.handleAppleSignIn(result: result)
                currentUser = user
                sessionToken = token
            } catch let error as AuthError where error == .appleSignInCancelled {
                // User cancelled — don't show error
            } catch {
                errorMessage = error.localizedDescription
                currentUser = nil
                sessionToken = nil
            }

            isLoading = false
        }
    }

    /// Delete account permanently
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await APIService.shared.deleteAccount()
            signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Sign out and clear all cached data
    func signOut() {
        authService.signOut()
        currentUser = nil
        sessionToken = nil
        clearAllCaches()
    }

    /// Clear all cached data (visits, favorites, etc.)
    private func clearAllCaches() {
        SecureCache.deleteAll()
        UserDefaults.standard.removeObject(forKey: "cached_visits_timestamp")
        UserDefaults.standard.removeObject(forKey: "cached_favorites_version")
    }
}

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.appleSignInCancelled, .appleSignInCancelled): return true
        case (.noRootViewController, .noRootViewController): return true
        case (.noUser, .noUser): return true
        case (.noIDToken, .noIDToken): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.keychainError, .keychainError): return true
        default: return false
        }
    }
}
