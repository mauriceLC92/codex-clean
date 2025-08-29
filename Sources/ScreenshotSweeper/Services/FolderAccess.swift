import AppKit

enum FolderAccess {
    static func selectFolder() -> Data? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            return bookmark
        } catch {
            return nil
        }
    }

    /// Resolves a bookmark. If the bookmark is stale, nil is returned so the caller can prompt the user again.
    static func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        return isStale ? nil : url
    }
}
