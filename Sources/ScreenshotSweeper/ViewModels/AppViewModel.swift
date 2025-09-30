import Foundation
import SwiftUI
import os.log

final class AppViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var matchCount: Int = 0
    private let scheduler = Scheduler()
    private let cleanupService = CleanupService()
    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "scheduler")

    init() {
        settings = Settings.load()
        refreshMatchCount()
        recomputeSchedule()
    }

    @discardableResult
    func cleanNow() -> CleanupResult {
        let destination: CleanupService.Destination
        var accessURL: URL? = nil
        switch settings.destinationMode {
        case .trash:
            destination = .trash
        case .folder(let bookmark):
            if let url = FolderAccess.resolveBookmark(bookmark) {
                accessURL = url
                guard url.startAccessingSecurityScopedResource() else {
                    logger.error("Failed to access security-scoped resource for folder")
                    destination = .trash
                    return CleanupResult(cleaned: 0, skipped: 0)
                }
                destination = .folder(url)
            } else if let newBm = FolderAccess.selectFolder(), let url = FolderAccess.resolveBookmark(newBm) {
                settings.destinationMode = .folder(bookmark: newBm)
                settings.save()
                accessURL = url
                guard url.startAccessingSecurityScopedResource() else {
                    logger.error("Failed to access security-scoped resource for new folder")
                    destination = .trash
                    return CleanupResult(cleaned: 0, skipped: 0)
                }
                destination = .folder(url)
            } else {
                logger.error("Folder bookmark invalid; defaulting to trash")
                destination = .trash
            }
        }

        let result: CleanupResult
        do {
            result = try cleanupService.performCleanup(prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive, destination: destination)
            if result.cleaned > 0 {
                settings.totalCleaned += result.cleaned
            }
            settings.lastRun = Date()
            settings.save()
            refreshMatchCount()
        } catch {
            logger.error("Cleanup failed due to permission error")
            accessURL?.stopAccessingSecurityScopedResource()
            return CleanupResult(cleaned: 0, skipped: 0)
        }
        accessURL?.stopAccessingSecurityScopedResource()
        return result
    }

    func refreshMatchCount() {
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else { matchCount = 0; return }
        matchCount = cleanupService.findMatches(in: desktop, prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive).count
    }

    func updateSchedule() {
        recomputeSchedule()
    }

    /// Schedules the next cleanup run.
    func recomputeSchedule() {
        scheduler.invalidate()
        guard settings.cleanupEnabled else { return }
        let next = NextRunCalculator.nextDate(for: settings.cleanupTime, from: Date())
        scheduler.schedule(at: next) { [weak self] in
            guard let self = self else { return }
            _ = self.cleanNow()
            self.recomputeSchedule()
        }
    }

    var destinationDescription: String {
        switch settings.destinationMode {
        case .trash:
            return NSLocalizedString("Trash", comment: "Destination trash")
        case .folder(let bookmark):
            if let url = FolderAccess.resolveBookmark(bookmark) {
                return url.lastPathComponent
            } else {
                return NSLocalizedString("Folder", comment: "Destination folder")
            }
        }
    }

    var destinationURL: URL? {
        switch settings.destinationMode {
        case .trash:
            return nil
        case .folder(let bookmark):
            return FolderAccess.resolveBookmark(bookmark)
        }
    }

    var lastRunDescription: String {
        if let last = settings.lastRun {
            let fmt = RelativeDateTimeFormatter()
            fmt.unitsStyle = .abbreviated
            return fmt.localizedString(for: last, relativeTo: Date())
        } else {
            return NSLocalizedString("Never", comment: "Never run")
        }
    }
}
