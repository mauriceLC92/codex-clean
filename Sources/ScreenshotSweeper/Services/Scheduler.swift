import Foundation
import os.log

final class Scheduler {
    private var timer: Timer?
    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "Scheduler")

    func schedule(at date: Date, handler: @escaping () -> Void) {
        timer?.invalidate()
        let interval = max(date.timeIntervalSinceNow, 1)
        logger.debug("Scheduling cleanup in \(interval, privacy: .public) seconds")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            handler()
        }
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}
