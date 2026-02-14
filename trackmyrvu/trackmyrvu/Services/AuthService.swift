//
//  AuthService.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation
import GoogleSignIn
import UIKit
import Security

/// Error types for authentication
enum AuthError: Error, LocalizedError {
    case noRootViewController
    case signInFailed(Error)
    case noUser
    case noIDToken
    case invalidResponse
    case serverError(String)
    case keychainError

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Cannot present sign-in UI: no root view controller"
        case .signInFailed(let error):
            return "Sign-in failed: \(error.localizedDescription)"
        case .noUser:
            return "No user data available"
        case .noIDToken:
            return "Failed to get ID token from Google"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .keychainError:
            return "Failed to save token to keychain"
        }
    }
}

/// Backend authentication response
struct AuthResponse: Codable {
    let success: Bool
    let user: User
    let sessionToken: String
    let expiresIn: Int
}

/// Backend error response
struct ErrorResponse: Codable {
    let error: String
}

/// Service to handle Google Sign-In integration and backend authentication
@MainActor
class AuthService {
    static let shared = AuthService()

    private let baseURL: URL
    private let keychainAccount = "sessionToken"

    private init() {
        guard let url = URL(string: "https://www.trackmyrvu.com") else {
            fatalError("Invalid base URL configuration")
        }
        self.baseURL = url
    }

    // MARK: - Sign In with Google

    /// Sign in with Google and authenticate with backend
    func signIn() async throws -> (User, String) {
        guard let rootViewController = getRootViewController() else {
            throw AuthError.noRootViewController
        }

        do {
            // Configure Google Sign-In with both iOS and server client IDs
            guard let iOSClientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                  let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String else {
                throw AuthError.signInFailed(NSError(
                    domain: "AuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing GIDClientID or GIDServerClientID in Info.plist"]
                ))
            }

            // iOS client ID: for sign-in flow
            // Server client ID: ID token will be issued for this audience (backend can verify)
            let config = GIDConfiguration(clientID: iOSClientID, serverClientID: serverClientID)
            GIDSignIn.sharedInstance.configuration = config

            // Step 1: Sign in with Google
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            // Step 2: Get ID token
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.noIDToken
            }

            // Step 3: Authenticate with backend
            let (user, sessionToken) = try await authenticateWithBackend(idToken: idToken)

            // Step 4: Save token to keychain
            try saveTokenToKeychain(sessionToken)

            return (user, sessionToken)

        } catch {
            if let authError = error as? AuthError {
                throw authError
            }
            throw AuthError.signInFailed(error)
        }
    }

    // MARK: - Authenticate with Backend

    private func authenticateWithBackend(idToken: String) async throws -> (User, String) {
        let url = baseURL.appendingPathComponent("/api/auth/mobile/google")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["idToken": idToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw AuthError.serverError(errorResponse?.error ?? "Unknown error (status: \(httpResponse.statusCode))")
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        return (authResponse.user, authResponse.sessionToken)
    }

    // MARK: - Sign Out

    /// Sign out from Google and clear session
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        deleteTokenFromKeychain()
    }

    // MARK: - Restore Session

    /// Restore previous sign-in session from keychain
    func restorePreviousSignIn() async throws -> String? {
        // Check if we have a valid token in keychain
        if let token = loadTokenFromKeychain() {
            return token
        }

        // Try to restore Google session and re-authenticate
        if let googleUser = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() {
            guard let idToken = googleUser.idToken?.tokenString else {
                return nil
            }

            let (_, sessionToken) = try await authenticateWithBackend(idToken: idToken)
            try saveTokenToKeychain(sessionToken)
            return sessionToken
        }

        return nil
    }

    // MARK: - Token Management (Keychain)

    private func saveTokenToKeychain(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw AuthError.keychainError
        }

        // Delete old token first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new token with secure accessibility
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError
        }
    }

    func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Private Helpers

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}
