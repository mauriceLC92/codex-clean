import XCTest
@testable import ScreenshotSweeper

final class ConflictSafeRenamingTests: XCTestCase {
    func testRenaming() throws {
        let src = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let dest = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: src, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: src)
            try? FileManager.default.removeItem(at: dest)
        }
        let fm = FileManager.default
        fm.createFile(atPath: src.appendingPathComponent("Screenshot.png").path, contents: Data())
        // Existing file in destination
        fm.createFile(atPath: dest.appendingPathComponent("Screenshot.png").path, contents: Data())

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .folder(dest), directory: src)
        XCTAssertEqual(result.cleaned, 1)
        XCTAssertTrue(fm.fileExists(atPath: dest.appendingPathComponent("Screenshot-1.png").path))
    }
}
