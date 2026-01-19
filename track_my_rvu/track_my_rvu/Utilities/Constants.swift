//
//  Constants.swift
//  RVU Tracker
//
//  Application-wide constants and configuration
//

import Foundation

enum Constants {
    // MARK: - API Configuration

    enum API {
        #if DEBUG
        static let baseURL = "http://localhost:3000/api"
        #else
        static let baseURL = "https://trackmyrvu.com/api"
        #endif

        static let timeout: TimeInterval = 30
    }

    // MARK: - App Configuration

    enum App {
        static let name = "RVU Tracker"
        static let bundleIdentifier = "com.trackmyrvu.ios"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Authentication

    enum Auth {
        static let keychainService = "com.trackmyrvu.ios"
        static let tokenKey = "authToken"
        static let refreshTokenKey = "refreshToken"

        // Google Sign-In Configuration
        // TODO: Add actual Google OAuth Client ID from Firebase Console
        static let googleClientID = "YOUR_GOOGLE_CLIENT_ID_HERE"
    }

    // MARK: - UI Constants

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 16
        static let animationDuration: TimeInterval = 0.3
    }

    // MARK: - Data

    enum Data {
        static let maxProceduresPerVisit = 50
        static let searchResultLimit = 100
        static let rvuCodesFileName = "rvu_codes"
    }
}
