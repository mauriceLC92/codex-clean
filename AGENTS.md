# Repository Guidelines

## Project Structure & Module Organization

Screenshot Sweeper is a Swift Package Manager macOS menu bar app targeting macOS 15. Source code lives in `Sources/ScreenshotSweeper`, grouped by role:

- `Models/` for persisted configuration such as `Settings`.
- `Services/` for cleanup, folder access, and scheduling logic.
- `ViewModels/` for app state coordination.
- `Views/` for SwiftUI menu bar and preferences UI.
- `Utilities/` for shared helpers like date calculation and debouncing.
- `Resources/` for app metadata such as `Info.plist`.

Tests are in `Tests/ScreenshotSweeperTests` and mirror the behavior under test, for example `NextRunCalculatorTests.swift` and `TrashCleanupTests.swift`.

## Build, Test, and Development Commands

- `swift build`: build the SwiftPM executable.
- `swift run`: build and run the app directly from SwiftPM.
- `swift test`: run the full XCTest suite.
- `swift test --parallel`: run tests concurrently when debugging does not require ordering.
- `swift test --filter NextRunCalculatorTests`: run one test class.
- `make build`: create the app bundle via `build-app.sh`.
- `make run`: open `build/Screenshot Sweeper.app`.
- `make clean` / `make rebuild`: remove generated build output, then optionally rebuild.

## Coding Style & Naming Conventions

Use Swift 5 language mode with four-space indentation. Keep types in PascalCase, methods and properties in lowerCamelCase, and test files named after the unit or behavior they verify. Follow the existing MVVM plus service-layer structure: UI state belongs in `AppViewModel`, business logic belongs in `Services`, and reusable calculations belong in `Utilities`. Prefer small, explicit SwiftUI bindings when mutating nested settings so changes are saved reliably.

## Testing Guidelines

Use XCTest. Add focused tests for scheduler math, cleanup filtering, conflict-safe renaming, and file movement behavior when touching those areas. Name test methods descriptively with the behavior and expected result. Run `swift test` before opening a pull request; use filtered tests only during local iteration.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries, sometimes with a conventional prefix such as `chore:`. Keep commits scoped to one change, for example `chore: add cleanup scheduling tests` or `Fix prefix matching for HEIC files`.

Pull requests should include a concise description, the user-visible impact, test results, and screenshots for UI changes. Link related issues when available and call out permission, sandboxing, or macOS-version implications.

## Security & Configuration Tips

Folder destinations rely on security-scoped bookmarks. When changing file access code, always pair `startAccessingSecurityScopedResource()` with `stopAccessingSecurityScopedResource()` and preserve graceful handling for invalid bookmarks and Desktop permission failures.
