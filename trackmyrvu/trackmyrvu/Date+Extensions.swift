//
//  Date+Extensions.swift
//  trackmyrvu
//
//  Created by Claude on 2026-02-12.
//

import Foundation

extension Date {
    /// Format date as ISO 8601 date string (YYYY-MM-DD)
    /// For API requests that expect date-only format
    nonisolated var dateString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }

    /// Format date for display in UI
    /// - Parameter style: DateFormatter style
    /// - Returns: Formatted date string
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format date and time for display in UI
    /// - Parameters:
    ///   - dateStyle: Date style
    ///   - timeStyle: Time style
    /// - Returns: Formatted date/time string
    func formatted(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    /// Get start of day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Get end of day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }
}
