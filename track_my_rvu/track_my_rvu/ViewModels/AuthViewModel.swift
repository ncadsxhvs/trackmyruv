//
//  AuthViewModel.swift
//  RVU Tracker
//
//  ViewModel for managing authentication state and sign-in flows
//

import Foundation
import AuthenticationServices
import SwiftUI
import UIKit
import GoogleSignIn

@MainActor
class AuthViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let authService = AuthService.shared
    private var currentNonce: String?

    // MARK: - Initialization

    override init() {
        super.init()
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Auth Status Check

    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Try to retrieve stored token
            guard let token = try await authService.retrieveToken() else {
                isAuthenticated = false
                currentUser = nil
                return
            }

            // Validate token
            guard await authService.isTokenValid(token) else {
                // Token expired, try to refresh
                await attemptTokenRefresh()
                return
            }

            // Retrieve user data
            if let user = try await authService.retrieveUser() {
                currentUser = user
                isAuthenticated = true
            } else {
                // Token exists but no user data, clear auth
                try await authService.clearAllAuthData()
                isAuthenticated = false
                currentUser = nil
            }
        } catch {
            print("Error checking auth status: \(error)")
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple() {
        isLoading = true
        errorMessage = nil

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: Constants.Auth.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                guard let signInResult = signInResult else {
                    self.errorMessage = "Google Sign-In returned no result"
                    self.isLoading = false
                    return
                }

                let user = signInResult.user
                guard let idToken = user.idToken?.tokenString else {
                    self.errorMessage = "Failed to get ID token"
                    self.isLoading = false
                    return
                }

                // TODO: Send idToken to backend for verification
                // For now, create a mock user
                let mockUser = User(
                    id: user.userID ?? UUID().uuidString,
                    email: user.profile?.email ?? "user@gmail.com",
                    name: user.profile?.name,
                    provider: .google
                )

                await self.handleSuccessfulSignIn(token: idToken, user: mockUser)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            do {
                try await authService.clearAllAuthData()
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error signing out: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Private Methods

    private func attemptTokenRefresh() async {
        // TODO: Implement token refresh logic with backend
        // For now, just sign out
        try? await authService.clearAllAuthData()
        isAuthenticated = false
        currentUser = nil
    }

    private func handleSuccessfulSignIn(token: String, user: User) async {
        do {
            try await authService.storeToken(token)
            try await authService.storeUser(user)

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error storing credentials: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                isLoading = false
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                isLoading = false
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                isLoading = false
                return
            }

            // TODO: Send idTokenString to backend for verification
            // For now, create a mock user and store the token
            Task {
                let mockUser = User(
                    id: appleIDCredential.user,
                    email: appleIDCredential.email ?? "user@icloud.com",
                    name: [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " "),
                    provider: .apple
                )

                await handleSuccessfulSignIn(token: idTokenString, user: mockUser)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as NSError
        if authError.code == ASAuthorizationError.canceled.rawValue {
            errorMessage = "Sign in was cancelled"
        } else {
            errorMessage = "Error signing in with Apple: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window scene found")
        }
        return window
    }
}

// MARK: - SHA256 (using CryptoKit)

import CryptoKit

extension SHA256 {
    static func hash(data: Data) -> SHA256Digest {
        return SHA256.hash(data: data)
    }
}
