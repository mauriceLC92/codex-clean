import Foundation
import os.log

final class Scheduler {
    private var timer: Timer?
    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "Scheduler")

    func schedule(at date: Date, handler: @escaping () -> Void) {
        timer?.invalidate()
        let interval = max(date.timeIntervalSinceNow, 1)
        logger.debug("Scheduling cleanup in \(interval, privacy: .public) seconds")

        let newTimer = Timer(timeInterval: interval, repeats: false) { _ in
            handler()
        }
        newTimer.tolerance = min(max(interval * 0.01, 60), 300)
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}
