//
//  RVUCacheService.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-08.
//

import Foundation

/// Model for HCPCS code
struct RVUCode: Identifiable, Codable {
    let hcpcs: String
    let description: String
    let statusCode: String
    let workRVU: Double

    var id: String { hcpcs }

    enum CodingKeys: String, CodingKey {
        case hcpcs = "HCPCS"
        case description = "DESCRIPTION"
        case statusCode = "STATUS CODE"
        case workRVU = "WORK RVU"
    }
}

/// Service to load and search HCPCS codes from bundled CSV
@Observable
@MainActor
class RVUCacheService {
    static let shared = RVUCacheService()

    private(set) var codes: [RVUCode] = []
    private(set) var isLoaded = false
    private(set) var error: String?

    /// Fast HCPCS → workRVU lookup dictionary
    private var rvuByHCPCS: [String: Double] = [:]

    private init() {}

    /// Load codes from bundled CSV file
    func loadCodes() async {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "rvu", withExtension: "csv") else {
            error = "RVU codes file not found in bundle"
            return
        }

        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)

            // Skip header and parse lines
            var parsedCodes: [RVUCode] = []

            for (index, line) in lines.enumerated() {
                // Skip header
                if index == 0 { continue }

                // Skip empty lines
                if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }

                // Parse CSV line
                let components = parseCSVLine(line)

                guard components.count >= 4 else { continue }

                let hcpcs = components[0].trimmingCharacters(in: .whitespaces)
                let description = components[1].trimmingCharacters(in: .whitespaces)
                let statusCode = components[2].trimmingCharacters(in: .whitespaces)
                let workRVUString = components[3].trimmingCharacters(in: .whitespaces)

                guard let workRVU = Double(workRVUString) else { continue }

                let code = RVUCode(
                    hcpcs: hcpcs,
                    description: description,
                    statusCode: statusCode,
                    workRVU: workRVU
                )

                parsedCodes.append(code)
            }

            self.codes = parsedCodes
            self.rvuByHCPCS = Dictionary(
                parsedCodes.map { ($0.hcpcs.uppercased(), $0.workRVU) },
                uniquingKeysWith: { first, _ in first }
            )
            self.isLoaded = true

        } catch {
            self.error = "Failed to load RVU codes: \(error.localizedDescription)"
        }
    }

    /// Look up workRVU for a given HCPCS code
    func lookupRVU(hcpcs: String) -> Double? {
        rvuByHCPCS[hcpcs.uppercased()]
    }

    /// Enrich visits with RVU values from the local CSV cache.
    /// Replaces procedure workRVU with CSV value when available.
    func enrichVisitsWithRVU(_ visits: [Visit]) -> [Visit] {
        guard isLoaded else { return visits }

        return visits.map { visit in
            var enrichedVisit = visit
            enrichedVisit.procedures = visit.procedures.map { proc in
                var enrichedProc = proc
                if let rvu = lookupRVU(hcpcs: proc.hcpcs) {
                    enrichedProc.workRVU = rvu
                }
                return enrichedProc
            }
            return enrichedVisit
        }
    }

    /// Search codes by HCPCS code or description
    func search(query: String, limit: Int = 100) -> [RVUCode] {
        guard !query.isEmpty else { return [] }

        let lowercaseQuery = query.lowercased()

        // Filter codes matching query
        let results = codes.filter { code in
            code.hcpcs.lowercased().contains(lowercaseQuery) ||
            code.description.lowercased().contains(lowercaseQuery)
        }

        // Sort: exact HCPCS matches first, then prefix matches, then others
        let sorted = results.sorted { lhs, rhs in
            let lhsHCPCS = lhs.hcpcs.lowercased()
            let rhsHCPCS = rhs.hcpcs.lowercased()

            // Exact match
            if lhsHCPCS == lowercaseQuery { return true }
            if rhsHCPCS == lowercaseQuery { return false }

            // Prefix match
            if lhsHCPCS.hasPrefix(lowercaseQuery) && !rhsHCPCS.hasPrefix(lowercaseQuery) {
                return true
            }
            if !lhsHCPCS.hasPrefix(lowercaseQuery) && rhsHCPCS.hasPrefix(lowercaseQuery) {
                return false
            }

            // Alphabetical
            return lhsHCPCS < rhsHCPCS
        }

        return Array(sorted.prefix(limit))
    }

    /// Parse CSV line handling quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var components: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                components.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        // Add last field
        components.append(currentField)

        return components
    }
}
