//
//  User.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation

/// User model matching backend API response
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case image
    }

    /// Computed property for display name
    var displayName: String {
        name ?? email
    }

    /// Computed property for backward compatibility
    var profileImageURL: String? {
        image
    }
}
