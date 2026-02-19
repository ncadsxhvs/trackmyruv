//
//  AuthService.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation
import GoogleSignIn
import AuthenticationServices
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
    case appleSignInCancelled
    case appleSignInFailed(String)

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
        case .appleSignInCancelled:
            return "Apple Sign-In was cancelled"
        case .appleSignInFailed(let message):
            return "Apple Sign-In failed: \(message)"
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

/// Service to handle authentication and backend integration
@MainActor
class AuthService {
    static let shared = AuthService()

    private let baseURL: URL
    private let keychainAccount = "sessionToken"
    private let appleUserIDKeychainAccount = "appleUserID"

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
            guard let iOSClientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                  let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String else {
                throw AuthError.signInFailed(NSError(
                    domain: "AuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing GIDClientID or GIDServerClientID in Info.plist"]
                ))
            }

            let config = GIDConfiguration(clientID: iOSClientID, serverClientID: serverClientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.noIDToken
            }

            let (user, sessionToken) = try await authenticateWithBackend(idToken: idToken)
            try saveTokenToKeychain(sessionToken)

            return (user, sessionToken)

        } catch {
            if let authError = error as? AuthError {
                throw authError
            }
            throw AuthError.signInFailed(error)
        }
    }

    // MARK: - Sign In with Apple

    /// Process Apple Sign-In credential from SignInWithAppleButton
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws -> (User, String) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.appleSignInFailed("Unexpected credential type")
            }

            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                throw AuthError.noIDToken
            }

            let email = credential.email
            let fullName = credential.fullName.flatMap {
                PersonNameComponentsFormatter.localizedString(from: $0, style: .default, options: [])
            }

            saveAppleUserID(credential.user)

            let (user, sessionToken) = try await authenticateAppleWithBackend(
                identityToken: identityToken,
                email: email,
                fullName: fullName
            )
            try saveTokenToKeychain(sessionToken)

            return (user, sessionToken)

        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                throw AuthError.appleSignInCancelled
            }
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }

    private func authenticateAppleWithBackend(
        identityToken: String,
        email: String?,
        fullName: String?
    ) async throws -> (User, String) {
        let url = baseURL.appendingPathComponent("/api/auth/mobile/apple")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = ["identityToken": identityToken]
        if let email { body["email"] = email }
        if let fullName { body["fullName"] = fullName }
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

    // MARK: - Apple Credential State

    func checkAppleCredentialState() async -> Bool {
        guard let appleUserID = loadAppleUserID() else { return false }

        return await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleUserID) { state, _ in
                continuation.resume(returning: state == .authorized)
            }
        }
    }

    private func saveAppleUserID(_ userID: String) {
        guard let data = userID.data(using: .utf8) else { return }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: appleUserIDKeychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: appleUserIDKeychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadAppleUserID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: appleUserIDKeychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userID = String(data: data, encoding: .utf8) else {
            return nil
        }
        return userID
    }

    private func deleteAppleUserID() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: appleUserIDKeychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Authenticate with Backend (Google)

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

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        deleteTokenFromKeychain()
        deleteAppleUserID()
    }

    // MARK: - Restore Session

    func restorePreviousSignIn() async throws -> String? {
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

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

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
