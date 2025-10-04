import XCTest
@testable import ScreenshotSweeper

final class NextRunCalculatorTests: XCTestCase {
    func testNextDateAroundMidnight() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = cal.date(from: DateComponents(year: 2023, month: 5, day: 1, hour: 23, minute: 58))!
        let target = DateComponents(hour: 23, minute: 59)
        let next = NextRunCalculator.nextDate(for: target, from: now, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: next), 1)
        XCTAssertEqual(cal.component(.hour, from: next), 23)
        XCTAssertEqual(cal.component(.minute, from:  next), 59)

        let after = cal.date(from: DateComponents(year: 2023, month: 5, day: 1, hour: 23, minute: 59, second: 30))!
        let next2 = NextRunCalculator.nextDate(for: target, from: after, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: next2), 2)
    }

    func testDSTForwardJump() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let now = cal.date(from: DateComponents(year: 2023, month: 3, day: 12, hour: 1, minute: 0))!
        let target = DateComponents(hour: 2, minute: 30)
        let next = NextRunCalculator.nextDate(for: target, from: now, calendar: cal)
        // 2:30 AM does not exist on this day; expect 3:30 AM
        XCTAssertEqual(cal.component(.day, from: next), 12)
        XCTAssertEqual(cal.component(.hour, from: next), 3)
    }

    func testExactTimeBoundaries() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let target = DateComponents(hour: 14, minute: 30)

        // 1 second before target → schedules TODAY at target time
        let oneSecondBefore = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 14, minute: 29, second: 59))!
        let nextFromBefore = NextRunCalculator.nextDate(for: target, from: oneSecondBefore, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromBefore), 15)
        XCTAssertEqual(cal.component(.hour, from: nextFromBefore), 14)
        XCTAssertEqual(cal.component(.minute, from: nextFromBefore), 30)
        XCTAssertEqual(cal.component(.second, from: nextFromBefore), 0)

        // Exactly at target time → schedules TOMORROW at target time
        let exactTime = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 14, minute: 30, second: 0))!
        let nextFromExact = NextRunCalculator.nextDate(for: target, from: exactTime, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromExact), 16)
        XCTAssertEqual(cal.component(.hour, from: nextFromExact), 14)
        XCTAssertEqual(cal.component(.minute, from: nextFromExact), 30)
        XCTAssertEqual(cal.component(.second, from: nextFromExact), 0)

        // 1 second after target → schedules TOMORROW at target time
        let oneSecondAfter = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 14, minute: 30, second: 1))!
        let nextFromAfter = NextRunCalculator.nextDate(for: target, from: oneSecondAfter, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromAfter), 16)
        XCTAssertEqual(cal.component(.hour, from: nextFromAfter), 14)
        XCTAssertEqual(cal.component(.minute, from: nextFromAfter), 30)
        XCTAssertEqual(cal.component(.second, from: nextFromAfter), 0)
    }

    func testMidnightBoundaries() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let target = DateComponents(hour: 23, minute: 59)

        // Before target on same day → schedules TODAY
        let before = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 23, minute: 58))!
        let nextFromBefore = NextRunCalculator.nextDate(for: target, from: before, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromBefore), 15)
        XCTAssertEqual(cal.component(.hour, from: nextFromBefore), 23)
        XCTAssertEqual(cal.component(.minute, from: nextFromBefore), 59)

        // Exactly at target → schedules TOMORROW
        let exact = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 23, minute: 59, second: 0))!
        let nextFromExact = NextRunCalculator.nextDate(for: target, from: exact, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromExact), 16)
        XCTAssertEqual(cal.component(.hour, from: nextFromExact), 23)
        XCTAssertEqual(cal.component(.minute, from: nextFromExact), 59)

        // After midnight, before target → schedules TODAY
        let afterMidnight = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 0, minute: 0))!
        let nextFromMidnight = NextRunCalculator.nextDate(for: target, from: afterMidnight, calendar: cal)
        XCTAssertEqual(cal.component(.day, from: nextFromMidnight), 15)
        XCTAssertEqual(cal.component(.hour, from: nextFromMidnight), 23)
        XCTAssertEqual(cal.component(.minute, from: nextFromMidnight), 59)
    }

    func testDateBoundaries() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let target = DateComponents(hour: 10, minute: 0)

        // Month boundary: Jan 31 → Feb 1
        let endOfJan = cal.date(from: DateComponents(year: 2023, month: 1, day: 31, hour: 23, minute: 0))!
        let nextFromJan = NextRunCalculator.nextDate(for: target, from: endOfJan, calendar: cal)
        XCTAssertEqual(cal.component(.month, from: nextFromJan), 2)
        XCTAssertEqual(cal.component(.day, from: nextFromJan), 1)
        XCTAssertEqual(cal.component(.hour, from: nextFromJan), 10)
        XCTAssertEqual(cal.component(.minute, from: nextFromJan), 0)

        // Year boundary: Dec 31 → Jan 1
        let endOfYear = cal.date(from: DateComponents(year: 2023, month: 12, day: 31, hour: 23, minute: 0))!
        let nextFromYear = NextRunCalculator.nextDate(for: target, from: endOfYear, calendar: cal)
        XCTAssertEqual(cal.component(.year, from: nextFromYear), 2024)
        XCTAssertEqual(cal.component(.month, from: nextFromYear), 1)
        XCTAssertEqual(cal.component(.day, from: nextFromYear), 1)
        XCTAssertEqual(cal.component(.hour, from: nextFromYear), 10)
        XCTAssertEqual(cal.component(.minute, from: nextFromYear), 0)

        // Leap year: Feb 28 → Feb 29 (2024 is a leap year)
        let endOfFebLeap = cal.date(from: DateComponents(year: 2024, month: 2, day: 28, hour: 23, minute: 0))!
        let nextFromFebLeap = NextRunCalculator.nextDate(for: target, from: endOfFebLeap, calendar: cal)
        XCTAssertEqual(cal.component(.month, from: nextFromFebLeap), 2)
        XCTAssertEqual(cal.component(.day, from: nextFromFebLeap), 29)

        // Non-leap year: Feb 28 → Mar 1 (2023 is not a leap year)
        let endOfFebNonLeap = cal.date(from: DateComponents(year: 2023, month: 2, day: 28, hour: 23, minute: 0))!
        let nextFromFebNonLeap = NextRunCalculator.nextDate(for: target, from: endOfFebNonLeap, calendar: cal)
        XCTAssertEqual(cal.component(.month, from: nextFromFebNonLeap), 3)
        XCTAssertEqual(cal.component(.day, from: nextFromFebNonLeap), 1)
    }

    func testDSTFallBack() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        // Nov 5, 2023: DST ends, clocks fall back at 2:00 AM to 1:00 AM
        // 1:00-2:00 AM occurs twice (first in DST, then in standard time)
        let beforeFallBack = cal.date(from: DateComponents(year: 2023, month: 11, day: 5, hour: 0, minute: 30))!
        let target = DateComponents(hour: 1, minute: 30)
        let next = NextRunCalculator.nextDate(for: target, from: beforeFallBack, calendar: cal)

        // Should schedule for the first occurrence of 1:30 AM (during DST, before fall back)
        XCTAssertEqual(cal.component(.day, from: next), 5)
        XCTAssertEqual(cal.component(.hour, from: next), 1)
        XCTAssertEqual(cal.component(.minute, from: next), 30)

        // Verify it's the first occurrence by checking it's before 2:00 AM local time
        // (when the clock would fall back)
        let twoAM = cal.date(from: DateComponents(year: 2023, month: 11, day: 5, hour: 2, minute: 0))!
        XCTAssertLessThan(next, twoAM)
    }

    func testSecondsPrecision() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let target = DateComponents(hour: 14, minute: 30)

        // Test with various second values in the current time
        let times = [0, 15, 30, 45, 59]
        for second in times {
            let now = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 10, minute: 0, second: second))!
            let next = NextRunCalculator.nextDate(for: target, from: now, calendar: cal)

            // Returned date should always have seconds set to 0
            XCTAssertEqual(cal.component(.second, from: next), 0,
                           "Failed for input with seconds=\(second)")
        }

        // Test that target with explicit seconds is ignored (seconds should still be 0)
        var targetWithSeconds = DateComponents(hour: 14, minute: 30)
        targetWithSeconds.second = 45
        let now = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 10, minute: 0))!
        let next = NextRunCalculator.nextDate(for: targetWithSeconds, from: now, calendar: cal)
        XCTAssertEqual(cal.component(.second, from: next), 0,
                       "Seconds should be forced to 0 even when specified in target")
    }

    func testInvalidInputHandling() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = cal.date(from: DateComponents(year: 2023, month: 6, day: 15, hour: 10, minute: 0))!

        // Empty DateComponents - calendar finds next minute boundary
        let emptyTarget = DateComponents()
        let nextFromEmpty = NextRunCalculator.nextDate(for: emptyTarget, from: now, calendar: cal)
        XCTAssertEqual(cal.component(.hour, from: nextFromEmpty), 10)
        XCTAssertEqual(cal.component(.minute, from: nextFromEmpty), 1)

        // Missing hour - matches next occurrence of the minute
        let missingHour = DateComponents(minute: 30)
        let nextFromMissingHour = NextRunCalculator.nextDate(for: missingHour, from: now, calendar: cal)
        XCTAssertEqual(cal.component(.hour, from: nextFromMissingHour), 10)
        XCTAssertEqual(cal.component(.minute, from: nextFromMissingHour), 30)

        // Missing minute - matches next occurrence of the hour (at :00)
        let missingMinute = DateComponents(hour: 14)
        let nextFromMissingMinute = NextRunCalculator.nextDate(for: missingMinute, from: now, calendar: cal)
        XCTAssertEqual(cal.component(.hour, from: nextFromMissingMinute), 14)
        XCTAssertEqual(cal.component(.minute, from: nextFromMissingMinute), 0)
    }
}
