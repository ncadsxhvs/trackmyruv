//
//  AuthService.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation
import GoogleSignIn
import UIKit

/// Error types for authentication
enum AuthError: Error, LocalizedError {
    case noRootViewController
    case signInFailed(Error)
    case noUser

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Cannot present sign-in UI: no root view controller"
        case .signInFailed(let error):
            return "Sign-in failed: \(error.localizedDescription)"
        case .noUser:
            return "No user data available"
        }
    }
}

/// Service to handle Google Sign-In integration
@MainActor
class AuthService {
    static let shared = AuthService()

    private let userDefaultsKey = "savedUser"

    private init() {}

    /// Sign in with Google
    func signIn() async throws -> User {
        guard let rootViewController = getRootViewController() else {
            throw AuthError.noRootViewController
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            let googleUser = result.user
            let user = try convertToUser(googleUser)
            saveUser(user)
            return user

        } catch {
            throw AuthError.signInFailed(error)
        }
    }

    /// Sign out from Google
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        clearSavedUser()
    }

    /// Restore previous sign-in session
    func restorePreviousSignIn() async throws -> User? {
        // Try to restore Google session
        if let googleUser = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() {
            let user = try convertToUser(googleUser)
            saveUser(user)
            return user
        }

        // Fall back to saved user from UserDefaults
        return loadSavedUser()
    }

    // MARK: - Private Helpers

    private func convertToUser(_ googleUser: GIDGoogleUser) throws -> User {
        guard let profile = googleUser.profile else {
            throw AuthError.noUser
        }

        return User(
            id: googleUser.userID ?? "",
            email: profile.email,
            name: profile.name,
            profileImageURL: profile.imageURL(withDimension: 120)?.absoluteString,
            givenName: profile.givenName,
            familyName: profile.familyName
        )
    }

    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadSavedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }

    private func clearSavedUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}
