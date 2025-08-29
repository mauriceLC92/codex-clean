// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotSweeper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenshotSweeper", targets: ["ScreenshotSweeper"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotSweeper",
            path: "Sources/ScreenshotSweeper",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
