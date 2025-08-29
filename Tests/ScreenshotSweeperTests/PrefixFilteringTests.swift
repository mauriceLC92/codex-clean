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
}
