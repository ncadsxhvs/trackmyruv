//
//  DateUtils.swift
//  RVU Tracker
//
//  Timezone-independent date utilities
//  CRITICAL: All date handling must be timezone-safe
//

import Foundation

enum DateUtils {
    // MARK: - Shared Formatters

    /// ISO 8601 date formatter (date only, no time)
    /// Format: YYYY-MM-DD
    static let iso8601DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    /// ISO 8601 date-time formatter (date + time)
    /// Format: YYYY-MM-DDTHH:mm:ssZ
    static let iso8601DateTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Display date formatter (localized)
    /// Example: "Jan 18, 2026"
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Display time formatter (localized, 12-hour)
    /// Example: "2:30 PM"
    static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Display date-time formatter (localized)
    /// Example: "Jan 18, 2026 at 2:30 PM"
    static let displayDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Date Conversion

    /// Convert Date to ISO 8601 date string (date only)
    /// - Parameter date: The date to convert
    /// - Returns: ISO 8601 date string (YYYY-MM-DD)
    static func toDateString(_ date: Date) -> String {
        return iso8601DateFormatter.string(from: date)
    }

    /// Convert ISO 8601 date string to Date (date only)
    /// - Parameter dateString: ISO 8601 date string (YYYY-MM-DD)
    /// - Returns: Date object, or nil if parsing fails
    static func fromDateString(_ dateString: String) -> Date? {
        return iso8601DateFormatter.date(from: dateString)
    }

    /// Convert Date to ISO 8601 date-time string
    /// - Parameter date: The date to convert
    /// - Returns: ISO 8601 date-time string (YYYY-MM-DDTHH:mm:ssZ)
    static func toDateTimeString(_ date: Date) -> String {
        return iso8601DateTimeFormatter.string(from: date)
    }

    /// Convert ISO 8601 date-time string to Date
    /// - Parameter dateTimeString: ISO 8601 date-time string
    /// - Returns: Date object, or nil if parsing fails
    static func fromDateTimeString(_ dateTimeString: String) -> Date? {
        return iso8601DateTimeFormatter.date(from: dateTimeString)
    }

    // MARK: - Date Manipulation

    /// Get the start of day for a given date (midnight, local time)
    /// - Parameter date: The date to process
    /// - Returns: Date at start of day
    static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    /// Check if two dates are on the same day (ignoring time)
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if dates are on the same day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    /// Add days to a date
    /// - Parameters:
    ///   - days: Number of days to add (can be negative)
    ///   - date: Starting date
    /// - Returns: New date with days added, or nil if calculation fails
    static func addDays(_ days: Int, to date: Date) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: date)
    }

    /// Calculate days between two dates
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days between dates
    static func daysBetween(from: Date, to: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: from, to: to)
        return components.day ?? 0
    }

    // MARK: - Display Formatting

    /// Format date for display (localized)
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string (e.g., "Jan 18, 2026")
    static func formatForDisplay(_ date: Date) -> String {
        return displayDateFormatter.string(from: date)
    }

    /// Format time for display (localized, 12-hour)
    /// - Parameter date: The date containing the time
    /// - Returns: Formatted time string (e.g., "2:30 PM")
    static func formatTimeForDisplay(_ date: Date) -> String {
        return displayTimeFormatter.string(from: date)
    }

    /// Format date and time for display (localized)
    /// - Parameter date: The date to format
    /// - Returns: Formatted date-time string (e.g., "Jan 18, 2026 at 2:30 PM")
    static func formatDateTimeForDisplay(_ date: Date) -> String {
        return displayDateTimeFormatter.string(from: date)
    }

    // MARK: - Date Ranges

    /// Get date range for last N days
    /// - Parameter days: Number of days (e.g., 7 for last week)
    /// - Returns: Tuple of (startDate, endDate)
    static func lastNDays(_ days: Int) -> (startDate: Date, endDate: Date) {
        let endDate = Date()
        let startDate = addDays(-days, to: endDate) ?? endDate
        return (startDate, endDate)
    }

    /// Get date range for current month
    /// - Returns: Tuple of (startDate, endDate) for current month
    static func currentMonth() -> (startDate: Date, endDate: Date) {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)

        let startDate = calendar.date(from: components) ?? now
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? now

        return (startDate, endDate)
    }

    /// Get date range for current year
    /// - Returns: Tuple of (startDate, endDate) for current year
    static func currentYear() -> (startDate: Date, endDate: Date) {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)

        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
        let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now

        return (startDate, endDate)
    }
}
