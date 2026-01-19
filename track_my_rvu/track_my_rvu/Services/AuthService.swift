//
//  AuthService.swift
//  RVU Tracker
//
//  Service for managing authentication tokens and Keychain storage
//

import Foundation
import Security

actor AuthService {
    static let shared = AuthService()

    private init() {}

    // MARK: - Keychain Storage

    /// Store auth token in Keychain
    func storeToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Auth.keychainService,
            kSecAttrAccount as String: Constants.Auth.tokenKey,
            kSecValueData as String: data
        ]

        // Delete any existing token first
        SecItemDelete(query as CFDictionary)

        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError(status)
        }
    }

    /// Retrieve auth token from Keychain
    func retrieveToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Auth.keychainService,
            kSecAttrAccount as String: Constants.Auth.tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw AuthError.keychainError(status)
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidTokenData
        }

        return token
    }

    /// Delete auth token from Keychain
    func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Auth.keychainService,
            kSecAttrAccount as String: Constants.Auth.tokenKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainError(status)
        }
    }

    /// Store refresh token in Keychain
    func storeRefreshToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Auth.keychainService,
            kSecAttrAccount as String: Constants.Auth.refreshTokenKey,
            kSecValueData as String: data
        ]

        // Delete any existing token first
        SecItemDelete(query as CFDictionary)

        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError(status)
        }
    }

    /// Retrieve refresh token from Keychain
    func retrieveRefreshToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Auth.keychainService,
            kSecAttrAccount as String: Constants.Auth.refreshTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw AuthError.keychainError(status)
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidTokenData
        }

        return token
    }

    // MARK: - Token Validation

    /// Check if JWT token is valid (not expired)
    func isTokenValid(_ token: String) -> Bool {
        // Simple JWT expiration check
        // JWT format: header.payload.signature
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return false }

        let payloadBase64 = components[1]
        guard let payloadData = Data(base64Encoded: base64URLDecode(payloadBase64)),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return false
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        return expirationDate > Date()
    }

    // MARK: - Helper Methods

    private func base64URLDecode(_ base64URL: String) -> String {
        var base64 = base64URL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 {
            base64.append(String(repeating: "=", count: paddingLength))
        }

        return base64
    }

    // MARK: - User Storage

    /// Store user data in UserDefaults
    func storeUser(_ user: User) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: "currentUser")
    }

    /// Retrieve user data from UserDefaults
    func retrieveUser() throws -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(User.self, from: data)
    }

    /// Delete user data from UserDefaults
    func deleteUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    // MARK: - Clear All Auth Data

    /// Clear all authentication data (tokens and user)
    func clearAllAuthData() throws {
        try deleteToken()
        deleteUser()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case keychainError(OSStatus)
    case invalidTokenData
    case tokenExpired
    case networkError(Error)
    case invalidResponse
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidTokenData:
            return "Invalid token data"
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidCredentials:
            return "Invalid credentials"
        }
    }
}
