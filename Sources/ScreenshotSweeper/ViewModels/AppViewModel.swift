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
        if count > 0 {
            settings.totalCleaned += count
        }
        settings.lastRun = Date()
        settings.save()
        refreshMatchCount()
        return count
    }

    func refreshMatchCount() {
        matchCount = countMatches(prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive)
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
            _ = self.cleanNow()
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

    private func countMatches(prefix: String, isCaseSensitive: Bool) -> Int {
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else { return 0 }
        let exts = ["png", "jpg", "jpeg", "heic", "tiff"]
        do {
            let items = try fm.contentsOfDirectory(at: desktop, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            return items.filter { url in
                guard exts.contains(url.pathExtension.lowercased()) else { return false }
                let name = url.lastPathComponent
                if isCaseSensitive {
                    return name.hasPrefix(prefix)
                } else {
                    return name.lowercased().hasPrefix(prefix.lowercased())
                }
            }.count
        } catch {
            logger.error("Error counting matches: \(error.localizedDescription, privacy: .public)")
            return 0
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
