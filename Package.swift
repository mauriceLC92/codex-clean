// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenshotSweeper",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ScreenshotSweeper", targets: ["ScreenshotSweeper"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotSweeper",
            path: "Sources/ScreenshotSweeper",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "ScreenshotSweeperTests",
            dependencies: ["ScreenshotSweeper"],
            path: "Tests/ScreenshotSweeperTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
