import Foundation
import os.log

struct CleanupService {
    enum Destination {
        case trash
        case folder(URL)
    }

    private let logger = Logger(subsystem: "ScreenshotSweeper", category: "Cleanup")

    func performCleanup(prefix: String, isCaseSensitive: Bool, destination: Destination) -> Int {
        let fm = FileManager.default
        let urls = screenshotURLs(prefix: prefix, isCaseSensitive: isCaseSensitive)
        var cleaned = 0
        for url in urls {
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
                logger.error("Failed to move \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        return cleaned
    }

    func matchingScreenshotCount(prefix: String, isCaseSensitive: Bool) -> Int {
        screenshotURLs(prefix: prefix, isCaseSensitive: isCaseSensitive).count
    }

    private func screenshotURLs(prefix: String, isCaseSensitive: Bool) -> [URL] {
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            logger.error("Could not resolve Desktop directory")
            return []
        }
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
            }
        } catch {
            logger.error("Error reading Desktop: \(error.localizedDescription, privacy: .public)")
            return []
        }
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
