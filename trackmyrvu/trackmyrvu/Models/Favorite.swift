//
//  Favorite.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import Foundation

/// Favorite HCPCS code model matching backend API
/// Backend schema: id (int), user_id (text), hcpcs (varchar), sort_order (int), created_at (timestamp), updated_at (timestamp)
/// Full HCPCS details (description, workRVU, statusCode) looked up from RVUCacheService
struct Favorite: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let hcpcs: String
    let sortOrder: Int
    let createdAt: Date?
    let updatedAt: Date?

    var displayName: String {
        hcpcs
    }

    init(
        id: String,
        userId: String,
        hcpcs: String,
        sortOrder: Int,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.hcpcs = hcpcs
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle Int→String conversion for id
    // The decoder's .convertFromSnakeCase handles user_id → userId, etc.
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id, userId, hcpcs, sortOrder, createdAt, updatedAt
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID: Int from database SERIAL, fallback to String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }

        self.userId = try container.decode(String.self, forKey: .userId)
        self.hcpcs = try container.decode(String.self, forKey: .hcpcs)
        self.sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        enum CodingKeys: String, CodingKey {
            case id, userId, hcpcs, sortOrder, createdAt, updatedAt
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(hcpcs, forKey: .hcpcs)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
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


