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
        XCTAssertEqual(cal.component(.minute, from: next), 59)

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
}
