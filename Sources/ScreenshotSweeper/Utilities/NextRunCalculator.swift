import Foundation

/// Utility to compute next and previous cleanup dates given a target time.
struct NextRunCalculator {
    /// Returns the next date matching the provided hour/minute components.
    static func nextDate(for components: DateComponents, from now: Date = Date(), calendar: Calendar = .current) -> Date {
        var comps = components
        comps.second = 0
        if let next = calendar.nextDate(after: now, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents) {
            return next
        }
        return now
    }

    /// Returns the most recent past date matching the provided components.
    static func previousDate(for components: DateComponents, from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        var comps = components
        comps.second = 0
        let today = calendar.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: now) ?? now
        if today <= now {
            return today
        }
        return calendar.date(byAdding: .day, value: -1, to: today)
    }
}
