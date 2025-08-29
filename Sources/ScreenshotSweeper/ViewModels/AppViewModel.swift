import Foundation
import SwiftUI
import os.log

final class AppViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var matchCount: Int = 0
    private let scheduler = Scheduler()
    private let cleanupService = CleanupService()
    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "ViewModel")

    init() {
        settings = Settings.load()
        refreshMatchCount()
        scheduleCleanup()
    }

    @discardableResult
    func cleanNow() -> Int {
        let destination: CleanupService.Destination
        switch settings.destinationMode {
        case .trash:
            destination = .trash
        case .folder(let bookmark):
            if let url = FolderAccess.resolveBookmark(bookmark) {
                destination = .folder(url)
            } else {
                logger.error("Folder bookmark invalid; defaulting to trash")
                destination = .trash
            }
        }

        let count = cleanupService.performCleanup(prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive, destination: destination)
        settings.lastRun = Date()
        if count > 0 {
            settings.totalCleaned += count
        }
        settings.save()
        refreshMatchCount()
        return count
    }

    func refreshMatchCount() {
        matchCount = cleanupService.matchingScreenshotCount(prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive)
    }

    func updateSchedule() {
        scheduler.invalidate()
        scheduleCleanup()
    }

    private func scheduleCleanup() {
        guard settings.cleanupEnabled else { return }
        let next = nextCleanupDate()
        scheduler.schedule(at: next) { [weak self] in
            guard let self = self else { return }
            let count = self.cleanNow()
            self.logger.info("Scheduled cleanup removed \(count, privacy: .public) items")
            self.scheduleCleanup()
        }
    }

    private func nextCleanupDate() -> Date {
        var comps = settings.cleanupTime
        let cal = Calendar.current
        var date = cal.date(bySettingHour: comps.hour ?? 23, minute: comps.minute ?? 59, second: 0, of: Date()) ?? Date()
        if date < Date() {
            date = cal.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }
}
