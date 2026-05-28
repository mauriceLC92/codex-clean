import Foundation
import SwiftUI
import os.log

final class AppViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var matchCount: Int = 0
    @Published var matchedFiles: [URL] = []
    @Published var isCleaning: Bool = false
    private let scheduler = Scheduler()
    private let cleanupService = CleanupService()
    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "scheduler")

    private let refreshDebouncer = Debouncer(delay: 0.3)
    private let saveDebouncer = Debouncer(delay: 0.5)
    private static let maxDisplayFiles = 100

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        return fmt
    }()

    init() {
        settings = Settings.load()
        refreshMatchCount()
        recomputeSchedule()
    }

    func cleanNow(allowsFolderSelection: Bool = true, completion: @escaping (CleanupResult) -> Void) {
        guard !isCleaning else {
            completion(CleanupResult(cleaned: 0, skipped: 0))
            return
        }

        guard !settings.prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            refreshMatchCount()
            completion(CleanupResult(cleaned: 0, skipped: 0))
            return
        }

        guard let preparedDestination = prepareDestination(allowsFolderSelection: allowsFolderSelection) else {
            completion(CleanupResult(cleaned: 0, skipped: 0))
            return
        }

        let prefix = settings.prefix
        let isCaseSensitive = settings.isCaseSensitive
        let cleanupService = cleanupService
        isCleaning = true

        DispatchQueue.global(qos: .userInitiated).async {
            let cleanupResult: CleanupResult
            let cleanupFailed: Bool
            do {
                cleanupResult = try cleanupService.performCleanup(prefix: prefix, isCaseSensitive: isCaseSensitive, destination: preparedDestination.destination)
                cleanupFailed = false
            } catch {
                cleanupResult = CleanupResult(cleaned: 0, skipped: 0)
                cleanupFailed = true
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    preparedDestination.accessURL?.stopAccessingSecurityScopedResource()
                    return
                }

                preparedDestination.accessURL?.stopAccessingSecurityScopedResource()
                self.isCleaning = false

                if cleanupFailed {
                    self.logger.error("Cleanup failed due to permission error")
                    completion(cleanupResult)
                    return
                }

                if cleanupResult.cleaned > 0 {
                    self.settings.totalCleaned += cleanupResult.cleaned
                }
                self.settings.lastRun = Date()
                self.settings.save()
                self.refreshMatchCount()
                completion(cleanupResult)
            }
        }
    }

    private func prepareDestination(allowsFolderSelection: Bool) -> (destination: CleanupService.Destination, accessURL: URL?)? {
        switch settings.destinationMode {
        case .trash:
            settings.destinationNeedsAttention = false
            return (.trash, nil)
        case .folder(let bookmark):
            if let url = FolderAccess.resolveBookmark(bookmark) {
                guard url.startAccessingSecurityScopedResource() else {
                    logger.error("Failed to access security-scoped resource for folder")
                    markDestinationNeedsAttention()
                    return nil
                }
                settings.destinationNeedsAttention = false
                return (.folder(url), url)
            } else if allowsFolderSelection, let newBm = FolderAccess.selectFolder(), let url = FolderAccess.resolveBookmark(newBm) {
                settings.destinationMode = .folder(bookmark: newBm)
                settings.destinationNeedsAttention = false
                settings.save()
                guard url.startAccessingSecurityScopedResource() else {
                    logger.error("Failed to access security-scoped resource for new folder")
                    markDestinationNeedsAttention()
                    return nil
                }
                return (.folder(url), url)
            } else {
                logger.error("Folder bookmark invalid; cleanup skipped")
                markDestinationNeedsAttention()
                return nil
            }
        }
    }

    private func markDestinationNeedsAttention() {
        settings.destinationNeedsAttention = true
        settings.save()
    }

    func refreshMatchCount() {
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            matchCount = 0
            matchedFiles = []
            return
        }

        let matches = cleanupService.findMatches(in: desktop, prefix: settings.prefix, isCaseSensitive: settings.isCaseSensitive)
        matchCount = matches.count
        matchedFiles = Array(matches.prefix(Self.maxDisplayFiles))
    }

    func debouncedRefreshMatchCount() {
        refreshDebouncer.debounce { [weak self] in
            self?.refreshMatchCount()
        }
    }

    func debouncedSaveSettings() {
        saveDebouncer.debounce { [weak self] in
            self?.settings.save()
        }
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
            self.cleanNow(allowsFolderSelection: false) { [weak self] _ in
                self?.recomputeSchedule()
            }
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
            return Self.relativeDateFormatter.localizedString(for: last, relativeTo: Date())
        } else {
            return NSLocalizedString("Never", comment: "Never run")
        }
    }
}
