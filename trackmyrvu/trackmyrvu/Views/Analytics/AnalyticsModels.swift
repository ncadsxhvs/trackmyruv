//
//  AnalyticsModels.swift
//  trackmyrvu
//

import Foundation

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

enum AnalyticsTab: String, CaseIterable, Identifiable {
    case summary = "Summary"
    case breakdown = "HCPCS Breakdown"

    var id: String { rawValue }
}

struct PeriodSummary: Identifiable {
    let id = UUID()
    let periodStart: Date
    let periodLabel: String
    let totalRVU: Double
    let encounterCount: Int
    let noShowCount: Int
}

struct HCPCSBreakdownRow: Identifiable {
    let id = UUID()
    let hcpcs: String
    let description: String
    let totalQuantity: Int
    let totalWorkRVU: Double
}

struct PeriodBreakdown: Identifiable {
    let id = UUID()
    let periodStart: Date
    let periodLabel: String
    let rows: [HCPCSBreakdownRow]
}
