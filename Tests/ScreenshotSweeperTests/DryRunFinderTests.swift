import XCTest
@testable import ScreenshotSweeper

final class DryRunFinderTests: XCTestCase {
    func testDryRunDoesNotMove() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fm = FileManager.default
        let file = dir.appendingPathComponent("Screenshot1.png")
        fm.createFile(atPath: file.path, contents: Data())
        let service = CleanupService()
        let matches = service.findMatches(in: dir, prefix: "Screenshot", isCaseSensitive: true)
        XCTAssertEqual(matches.count, 1)
        XCTAssertTrue(fm.fileExists(atPath: file.path))
    }
}
