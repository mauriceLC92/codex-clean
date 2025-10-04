import XCTest
@testable import ScreenshotSweeper

final class PrefixFilteringTests: XCTestCase {
    func testCaseSensitive() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot1.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("screenshot2.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
    }

    func testCaseInsensitive() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot1.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("screenshot2.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: false)
        XCTAssertEqual(matches.count, 2)
    }

    func testEmptyPrefixMatchesAll() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot1.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Foo.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 2)
    }

    // MARK: - Negative Tests (Critical Safety Tests)

    func testFilesWithoutPrefixAreNotMatched() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Document.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Photo.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("MyImage.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1, "Only files with exact prefix should match")
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot.png")
    }

    func testPartialPrefixDoesNotMatch() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Scr.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screen.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1, "Partial prefix should not match")
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot.png")
    }

    func testPrefixInMiddleOfFilenameDoesNotMatch() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("MyScreenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Test-Screenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1, "Prefix must be at start of filename")
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot.png")
    }

    func testHiddenFilesAreExcluded() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent(".Screenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1, "Hidden files should be excluded")
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot.png")
    }

    // MARK: - Extension Validation Tests

    func testOnlySupportedExtensionsAreMatched() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        // Supported extensions
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.jpg").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.jpeg").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.heic").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.tiff").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 5, "All supported extensions should match")
    }

    func testUnsupportedExtensionsAreExcluded() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        // Unsupported extensions
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.gif").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.pdf").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.txt").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.mov").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.mp4").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot").path, contents: Data()) // No extension
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1, "Only supported image extensions should match")
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot.png")
    }

    func testExtensionIsCaseInsensitive() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.PNG").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.Jpg").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.JPEG").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 3, "Extensions should be case-insensitive")
    }

    // MARK: - Edge Case Tests

    func testPrefixWithSpecialCharacters() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot-2024.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot_test.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.old.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot-", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.lastPathComponent, "Screenshot-2024.png")
    }

    func testPrefixWithSpaces() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("My Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("MyScreenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "My Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.lastPathComponent, "My Screenshot.png")
    }

    func testPrefixWithUnicode() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("スクリーンショット.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "スクリーンショット", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.lastPathComponent, "スクリーンショット.png")
    }

    func testPrefixWithEmoji() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        fm.createFile(atPath: dir.appendingPathComponent("📸Screenshot.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "📸", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.lastPathComponent, "📸Screenshot.png")
    }

    func testVeryLongPrefix() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        let longPrefix = "Screenshot-2024-01-15-at-14-30-45-MacBook-Pro"
        fm.createFile(atPath: dir.appendingPathComponent("\(longPrefix).png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.png").path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: longPrefix, isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.lastPathComponent, "\(longPrefix).png")
    }

    // MARK: - Comprehensive Integration Test

    func testMixedFilesReturnsOnlyCorrectMatches() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default

        // Should match (3 files)
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot 2024-01-15.png").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot 2024-01-16.jpg").path, contents: Data())
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.heic").path, contents: Data())

        // Should NOT match
        fm.createFile(atPath: dir.appendingPathComponent("screenshot.png").path, contents: Data()) // Wrong case
        fm.createFile(atPath: dir.appendingPathComponent("MyScreenshot.png").path, contents: Data()) // Prefix not at start
        fm.createFile(atPath: dir.appendingPathComponent("Screen.png").path, contents: Data()) // Partial prefix
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.pdf").path, contents: Data()) // Wrong extension
        fm.createFile(atPath: dir.appendingPathComponent("Screenshot.txt").path, contents: Data()) // Wrong extension
        fm.createFile(atPath: dir.appendingPathComponent(".Screenshot.png").path, contents: Data()) // Hidden file
        fm.createFile(atPath: dir.appendingPathComponent("Document.png").path, contents: Data()) // Different prefix

        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)

        XCTAssertEqual(matches.count, 3, "Should only match files with correct prefix and extension")

        let matchedNames = Set(matches.map { $0.lastPathComponent })
        XCTAssertTrue(matchedNames.contains("Screenshot 2024-01-15.png"))
        XCTAssertTrue(matchedNames.contains("Screenshot 2024-01-16.jpg"))
        XCTAssertTrue(matchedNames.contains("Screenshot.heic"))

        // Verify non-matches are excluded
        XCTAssertFalse(matchedNames.contains("screenshot.png"))
        XCTAssertFalse(matchedNames.contains("MyScreenshot.png"))
        XCTAssertFalse(matchedNames.contains("Screenshot.pdf"))
    }
}
