//
//  User.swift
//  RVU Tracker
//
//  User model for authentication and profile data
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String?
    let provider: AuthProvider
    let createdAt: Date?
    let updatedAt: Date?

    enum AuthProvider: String, Codable {
        case apple
        case google
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case provider
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initializers

    init(id: String, email: String, name: String?, provider: AuthProvider, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.provider = provider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Display Helpers

    var displayName: String {
        return name ?? email.components(separatedBy: "@").first ?? "User"
    }

    var initials: String {
        if let name = name {
            let components = name.components(separatedBy: " ")
            if components.count >= 2 {
                let first = components[0].prefix(1)
                let last = components[1].prefix(1)
                return "\(first)\(last)".uppercased()
            } else {
                return String(name.prefix(2)).uppercased()
            }
        }
        return String(email.prefix(2)).uppercased()
    }
}

// MARK: - Mock Data (for previews and testing)

#if DEBUG
extension User {
    static let mock = User(
        id: "mock-user-123",
        email: "doctor@example.com",
        name: "Dr. Jane Smith",
        provider: .apple,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockGoogle = User(
        id: "mock-user-456",
        email: "physician@gmail.com",
        name: "Dr. John Doe",
        provider: .google,
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
