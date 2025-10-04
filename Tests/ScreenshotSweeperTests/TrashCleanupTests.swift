import XCTest
@testable import ScreenshotSweeper

final class TrashCleanupTests: XCTestCase {
    func testTrashCleanupMovesFilesToTrash() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        let file = dir.appendingPathComponent("Screenshot1.png")
        fm.createFile(atPath: file.path, contents: Data())

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 1, "One file should be cleaned")
        XCTAssertEqual(result.skipped, 0, "No files should be skipped")
        XCTAssertFalse(fm.fileExists(atPath: file.path), "File should be removed from source directory")
    }

    func testTrashCleanupHandlesMultipleFiles() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        let files = [
            dir.appendingPathComponent("Screenshot1.png"),
            dir.appendingPathComponent("Screenshot2.jpg"),
            dir.appendingPathComponent("Screenshot3.heic")
        ]

        for file in files {
            fm.createFile(atPath: file.path, contents: Data())
        }

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 3, "Three files should be cleaned")
        XCTAssertEqual(result.skipped, 0, "No files should be skipped")

        for file in files {
            XCTAssertFalse(fm.fileExists(atPath: file.path), "File \(file.lastPathComponent) should be removed")
        }
    }

    func testTrashCleanupOnlyMovesMatchingFiles() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        let matchingFile = dir.appendingPathComponent("Screenshot1.png")
        let nonMatchingFile1 = dir.appendingPathComponent("Document.png")
        let nonMatchingFile2 = dir.appendingPathComponent("Photo.jpg")

        fm.createFile(atPath: matchingFile.path, contents: Data())
        fm.createFile(atPath: nonMatchingFile1.path, contents: Data())
        fm.createFile(atPath: nonMatchingFile2.path, contents: Data())

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 1, "Only one matching file should be cleaned")
        XCTAssertFalse(fm.fileExists(atPath: matchingFile.path), "Matching file should be removed")
        XCTAssertTrue(fm.fileExists(atPath: nonMatchingFile1.path), "Non-matching file should remain")
        XCTAssertTrue(fm.fileExists(atPath: nonMatchingFile2.path), "Non-matching file should remain")
    }

    func testTrashCleanupReturnsZeroWhenNoMatches() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Document.png").path, contents: Data())

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 0, "No files should be cleaned")
        XCTAssertEqual(result.skipped, 0, "No files should be skipped")
    }

    func testTrashCleanupWithCaseInsensitivePrefix() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        let files = [
            dir.appendingPathComponent("Screenshot1.png"),
            dir.appendingPathComponent("screenshot2.png"),
            dir.appendingPathComponent("SCREENSHOT3.png")
        ]

        for file in files {
            fm.createFile(atPath: file.path, contents: Data())
        }

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: false, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 3, "All files with case-insensitive match should be cleaned")

        for file in files {
            XCTAssertFalse(fm.fileExists(atPath: file.path), "File should be removed")
        }
    }

    func testTrashCleanupWithCaseSensitivePrefix() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        let matchingFile = dir.appendingPathComponent("Screenshot1.png")
        let nonMatchingFile = dir.appendingPathComponent("screenshot2.png")

        fm.createFile(atPath: matchingFile.path, contents: Data())
        fm.createFile(atPath: nonMatchingFile.path, contents: Data())

        let service = CleanupService()
        let result = try service.performCleanup(prefix: "Screenshot", isCaseSensitive: true, destination: .trash, directory: dir)

        XCTAssertEqual(result.cleaned, 1, "Only case-sensitive match should be cleaned")
        XCTAssertFalse(fm.fileExists(atPath: matchingFile.path), "Matching file should be removed")
        XCTAssertTrue(fm.fileExists(atPath: nonMatchingFile.path), "Case-mismatched file should remain")
    }
}
