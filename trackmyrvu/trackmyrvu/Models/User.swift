//
//  User.swift
//  trackmyrvu
//
//  Created by Claude on 2026-01-25.
//

import Foundation

/// User model representing authenticated Google user
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let givenName: String?
    let familyName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageURL
        case givenName
        case familyName
    }
}
