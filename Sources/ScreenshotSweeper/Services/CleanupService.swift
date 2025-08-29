import Foundation
import os.log

struct CleanupResult { let cleaned: Int; let skipped: Int }

struct CleanupService {
    enum Destination {
        case trash
        case folder(URL)
    }

    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "cleanup")
    private let permLogger = Logger(subsystem: "ScreenshotSweeper", category: "permissions")

    /// Returns matching screenshot URLs without moving them.
    func findMatches(in directory: URL, prefix: String, isCaseSensitive: Bool) -> [URL] {
        let fm = FileManager.default
        let exts = ["png", "jpg", "jpeg", "heic", "tiff"]
        let items: [URL]
        do {
            items = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        } catch {
            permLogger.error("Cannot read directory \(directory.path, privacy: .public). Check permissions in System Settings → Privacy & Security → Files and Folders")
            return []
        }
        return items.filter { url in
            guard exts.contains(url.pathExtension.lowercased()) else { return false }
            let name = url.lastPathComponent
            if isCaseSensitive {
                return name.hasPrefix(prefix)
            } else {
                return name.lowercased().hasPrefix(prefix.lowercased())
            }
        }
    }

    /// Performs cleanup and returns counts. Throws if destination permission fails.
    func performCleanup(prefix: String, isCaseSensitive: Bool, destination: Destination, directory: URL? = nil) throws -> CleanupResult {
        let fm = FileManager.default
        let dirURL: URL
        if let directory = directory {
            dirURL = directory
        } else if let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first {
            dirURL = desktop
        } else {
            logger.error("Could not resolve Desktop directory")
            return CleanupResult(cleaned: 0, skipped: 0)
        }

        let matches = findMatches(in: dirURL, prefix: prefix, isCaseSensitive: isCaseSensitive)
        var cleaned = 0
        var skipped = 0
        for url in matches {
            do {
                switch destination {
                case .trash:
                    try fm.trashItem(at: url, resultingItemURL: nil)
                case .folder(let folderURL):
                    let dest = conflictSafeURL(for: url, in: folderURL)
                    try fm.moveItem(at: url, to: dest)
                }
                cleaned += 1
            } catch {
                let ns = error as NSError
                if ns.domain == NSCocoaErrorDomain && (ns.code == NSFileWriteNoPermissionError || ns.code == NSFileReadNoPermissionError) {
                    permLogger.error("Permission denied while moving \(url.path, privacy: .public)")
                    throw error
                }
                if ns.domain == NSPOSIXErrorDomain && ns.code == Int(EBUSY) {
                    skipped += 1
                    logger.info("File busy, skipping \(url.lastPathComponent, privacy: .public)")
                    continue
                }
                skipped += 1
                logger.error("Failed to move \(url.path, privacy: .public): \(ns.localizedDescription, privacy: .public)")
            }
        }
        return CleanupResult(cleaned: cleaned, skipped: skipped)
    }

    private func conflictSafeURL(for url: URL, in folder: URL) -> URL {
        let fm = FileManager.default
        var dest = folder.appendingPathComponent(url.lastPathComponent)
        var counter = 1
        while fm.fileExists(atPath: dest.path) {
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            dest = folder.appendingPathComponent("\(base)-\(counter).\(ext)")
            counter += 1
        }
        return dest
    }
}
