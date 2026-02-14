//
//  Favorite.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import Foundation

/// Favorite HCPCS code model matching backend API
/// Backend schema: id (int), user_id (text), hcpcs (varchar), sort_order (int), created_at (timestamp), group_id (int?)
/// Full HCPCS details (description, workRVU, statusCode) looked up from RVUCacheService
struct Favorite: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let hcpcs: String
    let sortOrder: Int
    let createdAt: Date?
    let groupId: Int?  // Optional group ID (currently unused, but returned by backend)

    var displayName: String {
        hcpcs
    }

    // No need for custom CodingKeys - decoder.keyDecodingStrategy = .convertFromSnakeCase handles it!
    // user_id → userId, sort_order → sortOrder, created_at → createdAt, group_id → groupId

    init(
        id: String,
        userId: String,
        hcpcs: String,
        sortOrder: Int,
        createdAt: Date? = nil,
        groupId: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.hcpcs = hcpcs
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.groupId = groupId
    }

    // Custom decoder to handle Int→String conversion for id
    init(from decoder: Decoder) throws {
        // Use default CodingKeys (auto-generated from property names)
        // The decoder's .convertFromSnakeCase handles user_id → userId, etc.
        enum CodingKeys: String, CodingKey {
            case id, userId, hcpcs, sortOrder, createdAt, groupId
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID: Try Int first (from database SERIAL), fallback to String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }

        // All other fields decode normally with snake_case conversion
        self.userId = try container.decode(String.self, forKey: .userId)
        self.hcpcs = try container.decode(String.self, forKey: .hcpcs)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.groupId = try container.decodeIfPresent(Int.self, forKey: .groupId)
    }

    func encode(to encoder: Encoder) throws {
        enum CodingKeys: String, CodingKey {
            case id, userId, hcpcs, sortOrder, createdAt, groupId
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(hcpcs, forKey: .hcpcs)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(groupId, forKey: .groupId)
    }
}

// MARK: - Create Favorite Request

struct CreateFavoriteRequest: Codable {
    let hcpcs: String
}

// MARK: - Reorder Favorites Request

struct ReorderFavoritesRequest: Codable {
    let favorites: [FavoriteOrder]

    struct FavoriteOrder: Codable {
        let hcpcs: String
        let sortOrder: Int
        // No CodingKeys needed - encoder.keyEncodingStrategy = .convertToSnakeCase handles it
    }
}


