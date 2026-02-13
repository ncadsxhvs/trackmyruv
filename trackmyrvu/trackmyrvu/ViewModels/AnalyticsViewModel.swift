//
//  AnalyticsViewModel.swift
//  trackmyrvu
//

import Foundation

@Observable
@MainActor
class AnalyticsViewModel {
    var period: AnalyticsPeriod = .daily
    var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var endDate: Date = Date()
    var activeTab: AnalyticsTab = .summary
    var selectedPeriodIndex: Int?

    var allVisits: [Visit] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared
    private let rvuCache = RVUCacheService.shared

    /// Parse the date string from a Visit.
    /// The backend may return "yyyy-MM-dd" or a full ISO 8601 datetime like "2026-02-12T00:00:00.000Z".
    private static func parseVisitDate(_ dateString: String) -> Date? {
        // Extract just the date portion (first 10 chars) regardless of format
        let dateOnly = String(dateString.prefix(10))
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "GMT")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: dateOnly)
    }

    // MARK: - Load Data

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        // Ensure RVU cache is loaded for enrichment
        await rvuCache.loadCodes()

        do {
            let freshVisits = try await apiService.fetchVisits()
            allVisits = rvuCache.enrichVisitsWithRVU(freshVisits)
        } catch let error as APIError where error == .tokenExpired {
            errorMessage = "Session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Period Changed

    func onPeriodChanged() {
        selectedPeriodIndex = nil
        if period == .yearly {
            let cal = Calendar.current
            let year = cal.component(.year, from: Date())
            startDate = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? startDate
            endDate = cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? endDate
        }
    }

    // MARK: - Bar Selection

    func selectBar(at index: Int) {
        if selectedPeriodIndex == index {
            selectedPeriodIndex = nil
        } else {
            selectedPeriodIndex = index
        }
    }

    func clearBarFilter() {
        selectedPeriodIndex = nil
    }

    // MARK: - Filtered Visits

    var filteredVisits: [Visit] {
        // Use GMT calendar to match how visit dates are parsed
        var gmtCal = Calendar(identifier: .gregorian)
        gmtCal.timeZone = TimeZone(identifier: "GMT")!
        let startOfStart = gmtCal.startOfDay(for: startDate)
        let endOfEnd = gmtCal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        return allVisits.filter { visit in
            guard let date = Self.parseVisitDate(visit.date) else { return false }
            return date >= startOfStart && date <= endOfEnd
        }
    }

    // MARK: - Aggregate Stats

    var totalRVU: Double {
        filteredVisits.reduce(0) { $0 + $1.totalWorkRVU }
    }

    var totalEncounters: Int {
        filteredVisits.filter { !$0.isNoShow }.count
    }

    var totalNoShows: Int {
        filteredVisits.filter { $0.isNoShow }.count
    }

    var avgRVUPerEncounter: Double {
        guard totalEncounters > 0 else { return 0 }
        return totalRVU / Double(totalEncounters)
    }

    // MARK: - Period Summaries

    var periodSummaries: [PeriodSummary] {
        let cal = Calendar.current
        var buckets: [Date: (rvu: Double, encounters: Int, noShows: Int)] = [:]

        for visit in filteredVisits {
            guard let date = Self.parseVisitDate(visit.date) else { continue }
            let key = periodStartDate(for: date, calendar: cal)

            var bucket = buckets[key, default: (rvu: 0, encounters: 0, noShows: 0)]
            bucket.rvu += visit.totalWorkRVU
            if visit.isNoShow {
                bucket.noShows += 1
            } else {
                bucket.encounters += 1
            }
            buckets[key] = bucket
        }

        return buckets.map { key, value in
            PeriodSummary(
                periodStart: key,
                periodLabel: periodLabel(for: key, calendar: cal),
                totalRVU: value.rvu,
                encounterCount: value.encounters,
                noShowCount: value.noShows
            )
        }
        .sorted { $0.periodStart < $1.periodStart }
    }

    // MARK: - Period Breakdowns

    var periodBreakdowns: [PeriodBreakdown] {
        let cal = Calendar.current
        let summaries = periodSummaries

        let visitsToUse: [Visit]
        if let idx = selectedPeriodIndex, idx < summaries.count {
            let selectedStart = summaries[idx].periodStart
            visitsToUse = filteredVisits.filter { visit in
                guard let date = Self.parseVisitDate(visit.date) else { return false }
                return periodStartDate(for: date, calendar: cal) == selectedStart
            }
        } else {
            visitsToUse = filteredVisits
        }

        var periodGroups: [Date: [Visit]] = [:]
        for visit in visitsToUse {
            guard let date = Self.parseVisitDate(visit.date) else { continue }
            let key = periodStartDate(for: date, calendar: cal)
            periodGroups[key, default: []].append(visit)
        }

        return periodGroups.map { key, visits in
            var hcpcsMap: [String: (description: String, quantity: Int, rvu: Double)] = [:]
            for visit in visits {
                for proc in visit.procedures {
                    var entry = hcpcsMap[proc.hcpcs, default: (description: proc.description, quantity: 0, rvu: 0)]
                    entry.quantity += proc.quantity
                    entry.rvu += proc.workRVU * Double(proc.quantity)
                    hcpcsMap[proc.hcpcs] = entry
                }
            }

            let rows = hcpcsMap.map { hcpcs, data in
                HCPCSBreakdownRow(
                    hcpcs: hcpcs,
                    description: data.description,
                    totalQuantity: data.quantity,
                    totalWorkRVU: data.rvu
                )
            }
            .sorted { $0.totalWorkRVU > $1.totalWorkRVU }

            return PeriodBreakdown(
                periodStart: key,
                periodLabel: periodLabel(for: key, calendar: cal),
                rows: rows
            )
        }
        .sorted { $0.periodStart > $1.periodStart }
    }

    // MARK: - Period Helpers

    private func periodStartDate(for date: Date, calendar: Calendar) -> Date {
        switch period {
        case .daily:
            return calendar.startOfDay(for: date)
        case .weekly:
            let interval = calendar.dateInterval(of: .weekOfYear, for: date)
            return interval?.start ?? calendar.startOfDay(for: date)
        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .yearly:
            let comps = calendar.dateComponents([.year], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        }
    }

    private func periodLabel(for date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")

        switch period {
        case .daily:
            f.dateFormat = "MMM d"
            return f.string(from: date)
        case .weekly:
            f.dateFormat = "MMM d"
            let start = f.string(from: date)
            if let end = calendar.date(byAdding: .day, value: 6, to: date) {
                let endStr = f.string(from: end)
                return "\(start)-\(endStr)"
            }
            return start
        case .monthly:
            f.dateFormat = "MMM yyyy"
            return f.string(from: date)
        case .yearly:
            f.dateFormat = "yyyy"
            return f.string(from: date)
        }
    }
}

