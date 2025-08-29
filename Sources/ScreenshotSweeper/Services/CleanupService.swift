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
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            logger.error("Could not resolve Desktop directory")
            return 0
        }
        let exts = ["png", "jpg", "jpeg", "heic", "tiff"]
        var cleaned = 0
        do {
            let items = try fm.contentsOfDirectory(at: desktop, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for url in items {
                guard exts.contains(url.pathExtension.lowercased()) else { continue }
                let name = url.lastPathComponent
                let matches: Bool
                if isCaseSensitive {
                    matches = name.hasPrefix(prefix)
                } else {
                    matches = name.lowercased().hasPrefix(prefix.lowercased())
                }
                guard matches else { continue }
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
        } catch {
            logger.error("Error reading Desktop: \(error.localizedDescription, privacy: .public)")
        }
        return cleaned
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
