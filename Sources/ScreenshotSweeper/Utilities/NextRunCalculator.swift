import Foundation

/// Utility to compute next cleanup date given a target time.
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
}
