//
//  Visit.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-06.
//

import Foundation

/// Visit model matching the backend API shape
struct Visit: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let date: String
    let time: String?
    let notes: String?
    let isNoShow: Bool
    var procedures: [VisitProcedure]
    let createdAt: Date?
    let updatedAt: Date?

    /// Sum of work RVU for all procedures
    var totalWorkRVU: Double {
        procedures.reduce(0) { $0 + ($1.workRVU * Double($1.quantity)) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case time
        case notes
        case isNoShow
        case procedures
        case createdAt
        case updatedAt
    }

    init(
        id: String,
        userId: String,
        date: String,
        time: String?,
        notes: String?,
        isNoShow: Bool,
        procedures: [VisitProcedure],
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.time = time
        self.notes = notes
        self.isNoShow = isNoShow
        self.procedures = procedures
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeStringOrInt(forKey: .id)
        self.userId = try container.decodeStringOrInt(forKey: .userId)
        self.date = try container.decode(String.self, forKey: .date)
        self.time = try container.decodeIfPresent(String.self, forKey: .time)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.isNoShow = try container.decodeIfPresent(Bool.self, forKey: .isNoShow) ?? false
        self.procedures = try container.decodeIfPresent([VisitProcedure].self, forKey: .procedures) ?? []

        // Parse ISO 8601 timestamps if present
        let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt)
        let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.createdAt = createdAtString?.iso8601Date
        self.updatedAt = updatedAtString?.iso8601Date
    }
}

struct VisitProcedure: Codable, Identifiable, Equatable {
    let id: String
    let visitId: String
    let hcpcs: String
    let description: String
    let statusCode: String
    var workRVU: Double
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case visitId
        case hcpcs
        case description
        case statusCode
        case workRVU
        case quantity
    }

    init(
        id: String,
        visitId: String,
        hcpcs: String,
        description: String,
        statusCode: String,
        workRVU: Double,
        quantity: Int
    ) {
        self.id = id
        self.visitId = visitId
        self.hcpcs = hcpcs
        self.description = description
        self.statusCode = statusCode
        self.workRVU = workRVU
        self.quantity = quantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeStringOrInt(forKey: .id)
        self.visitId = (try? container.decodeStringOrInt(forKey: .visitId)) ?? ""
        self.hcpcs = try container.decode(String.self, forKey: .hcpcs)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.statusCode = try container.decodeIfPresent(String.self, forKey: .statusCode) ?? ""
        self.workRVU = try container.decodeIfPresent(Double.self, forKey: .workRVU) ?? 0
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }
}

// MARK: - Decoding helpers

private extension KeyedDecodingContainer {
    func decodeStringOrInt(forKey key: Key) throws -> String {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected String or Int for key \(key.stringValue)"
        )
    }
}

private extension String {
    var iso8601Date: Date? {
        ISO8601DateFormatter().date(from: self)
    }
}

// MARK: - Create Visit Request

struct CreateVisitRequest: Codable {
    let date: String
    let time: String?
    let notes: String?
    let procedures: [CreateProcedureRequest]
    let isNoShow: Bool

    enum CodingKeys: String, CodingKey {
        case date
        case time
        case notes
        case procedures
        case isNoShow = "is_no_show"
    }
}

struct CreateProcedureRequest: Codable {
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case hcpcs
        case description
        case statusCode = "status_code"
        case workRVU = "work_rvu"
        case quantity
    }
}
