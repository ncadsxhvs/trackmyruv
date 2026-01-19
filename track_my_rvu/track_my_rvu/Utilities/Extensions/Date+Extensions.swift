//
//  Date+Extensions.swift
//  RVU Tracker
//
//  Date extension methods for common operations
//

import Foundation

extension Date {
    /// Convert date to ISO 8601 date string (date only)
    /// Example: "2026-01-18"
    var dateString: String {
        return DateUtils.toDateString(self)
    }

    /// Convert date to ISO 8601 date-time string
    /// Example: "2026-01-18T14:30:00Z"
    var dateTimeString: String {
        return DateUtils.toDateTimeString(self)
    }

    /// Format date for display
    /// Example: "Jan 18, 2026"
    var displayString: String {
        return DateUtils.formatForDisplay(self)
    }

    /// Format time for display
    /// Example: "2:30 PM"
    var timeString: String {
        return DateUtils.formatTimeForDisplay(self)
    }

    /// Format date and time for display
    /// Example: "Jan 18, 2026 at 2:30 PM"
    var displayDateTimeString: String {
        return DateUtils.formatDateTimeForDisplay(self)
    }

    /// Get start of day (midnight)
    var startOfDay: Date {
        return DateUtils.startOfDay(for: self)
    }

    /// Check if date is today
    var isToday: Bool {
        return DateUtils.isSameDay(self, Date())
    }

    /// Check if date is in the past
    var isPast: Bool {
        return self < Date()
    }

    /// Check if date is in the future
    var isFuture: Bool {
        return self > Date()
    }

    /// Add days to this date
    /// - Parameter days: Number of days to add (can be negative)
    /// - Returns: New date with days added
    func addingDays(_ days: Int) -> Date? {
        return DateUtils.addDays(days, to: self)
    }

    /// Calculate days between this date and another date
    /// - Parameter other: The other date
    /// - Returns: Number of days between dates
    func daysBetween(_ other: Date) -> Int {
        return DateUtils.daysBetween(from: self, to: other)
    }

    /// Create date from ISO 8601 date string (date only)
    /// - Parameter dateString: ISO 8601 date string (YYYY-MM-DD)
    /// - Returns: Date object, or nil if parsing fails
    static func from(dateString: String) -> Date? {
        return DateUtils.fromDateString(dateString)
    }

    /// Create date from ISO 8601 date-time string
    /// - Parameter dateTimeString: ISO 8601 date-time string
    /// - Returns: Date object, or nil if parsing fails
    static func from(dateTimeString: String) -> Date? {
        return DateUtils.fromDateTimeString(dateTimeString)
    }
}
