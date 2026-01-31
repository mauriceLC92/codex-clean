import XCTest
@testable import ScreenshotSweeper

final class DebouncerTests: XCTestCase {
    func testDebouncerExecutesAfterDelay() {
        let expectation = XCTestExpectation(description: "Debounced action should execute")
        let debouncer = Debouncer(delay: 0.1)

        var executionCount = 0
        debouncer.debounce {
            executionCount += 1
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1)
    }

    func testDebouncerCancelsRapidCalls() {
        let expectation = XCTestExpectation(description: "Only final debounced action should execute")
        let debouncer = Debouncer(delay: 0.1)

        var executionCount = 0
        var lastValue = 0

        // Simulate rapid typing - each call should cancel the previous
        for i in 1...5 {
            debouncer.debounce {
                executionCount += 1
                lastValue = i
                if i == 5 {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "Only one execution should occur")
        XCTAssertEqual(lastValue, 5, "Should execute with last value")
    }

    func testDebouncerAllowsSubsequentCallsAfterDelay() {
        let firstExpectation = XCTestExpectation(description: "First debounced action")
        let secondExpectation = XCTestExpectation(description: "Second debounced action")
        let debouncer = Debouncer(delay: 0.05)

        var results: [Int] = []

        debouncer.debounce {
            results.append(1)
            firstExpectation.fulfill()
        }

        wait(for: [firstExpectation], timeout: 1.0)

        debouncer.debounce {
            results.append(2)
            secondExpectation.fulfill()
        }

        wait(for: [secondExpectation], timeout: 1.0)
        XCTAssertEqual(results, [1, 2])
    }

    func testDebouncerCancel() {
        let debouncer = Debouncer(delay: 0.1)

        var executed = false
        debouncer.debounce {
            executed = true
        }

        debouncer.cancel()

        // Wait longer than the debounce delay
        let expectation = XCTestExpectation(description: "Wait for potential execution")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.2)

        XCTAssertFalse(executed, "Cancelled action should not execute")
    }

    func testDebouncerWithCustomQueue() {
        let expectation = XCTestExpectation(description: "Action should execute on custom queue")
        let customQueue = DispatchQueue(label: "test.debouncer.queue")
        let debouncer = Debouncer(delay: 0.05, queue: customQueue)

        var executedOnCustomQueue = false
        debouncer.debounce {
            dispatchPrecondition(condition: .onQueue(customQueue))
            executedOnCustomQueue = true
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(executedOnCustomQueue)
    }
}
