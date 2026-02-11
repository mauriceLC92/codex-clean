# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Screenshot Sweeper is a macOS menu bar app built with Swift and SwiftUI that automatically moves Desktop screenshots to the Trash or a specified folder on a scheduled basis. The app uses Swift Package Manager and targets macOS 13+.

## Development Commands

### Building and Running
```bash
make build                    # Build app bundle via build-app.sh
make run                      # Open the built app
make clean                    # Remove .build and build directories
make rebuild                  # Clean and build from scratch
swift build                   # Build via SPM directly
swift run                     # Build and run the executable
```

### Testing
```bash
swift test                    # Run all tests
swift test --parallel         # Run tests in parallel
swift test --filter NextRunCalculatorTests  # Run specific test class
```

## Architecture

### MVVM with Service Layer

- **ScreenshotSweeperApp** (`@main`): Creates a single `AppViewModel` as `@StateObject`, passes it to both `MenuBarView` and the preferences window via `AppDelegate`
- **AppViewModel**: Central `ObservableObject` coordinating between UI and services. Owns `CleanupService`, `Scheduler`, and `Settings`. All state flows through `@Published` properties
- **CleanupService**: Stateless struct that finds matching screenshot files and moves them (to trash or folder with conflict-safe renaming)
- **Scheduler**: Wraps a single `Timer` for the next scheduled cleanup. Uses `NextRunCalculator` to compute next run date, then re-schedules recursively after each run
- **Settings**: `Codable` struct persisted as JSON in `UserDefaults`. Security-scoped bookmarks stored as `Data` for folder destinations. Requires manual `save()` calls after mutation

### Scene Management (MenuBarExtra + NSWindow)

The app uses `MenuBarExtra` with `.window` style for the menu bar popover and a separate `PreferencesWindowController` (singleton `NSWindowController`) for the preferences window. When preferences open, the activation policy switches from `.accessory` to `.regular` (shows dock icon); it switches back when the window closes. The preferences window uses `NSHostingView` to embed `PreferencesView` SwiftUI content.

### Key Patterns

**TextField Binding**: When binding TextFields to nested struct properties in `@Published` objects, use custom `Binding` for reliable updates:
```swift
TextField("Prefix", text: Binding(
    get: { viewModel.settings.prefix },
    set: { newValue in
        viewModel.settings.prefix = newValue
        viewModel.settings.save()
    }
))
```

**Debouncing**: `AppViewModel` uses `Debouncer` (DispatchWorkItem-based) for prefix changes — `debouncedRefreshMatchCount()` (0.3s) and `debouncedSaveSettings()` (0.5s) to avoid excessive I/O.

**Security-Scoped Resources**: Folder destinations require `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` bracketing around file operations. If a bookmark becomes invalid, the app prompts the user to reselect.

**Error Handling in CleanupService**: Permission errors (`NSFileWriteNoPermissionError`, `NSFileReadNoPermissionError`) are thrown to the caller. Busy files (`EBUSY`) are silently skipped. Other errors are logged and skipped.

### Screenshot Detection

Files are matched by prefix (configurable case sensitivity) against extensions: `png`, `jpg`, `jpeg`, `heic`, `tiff`. Only the Desktop directory is scanned.

## Known Issues

### TextField Input Issues
The prefix TextField in preferences has known issues with input not working properly. This may be related to SwiftUI Form + NSWindow interaction patterns on macOS.

## Permissions Requirements

The app requires Desktop folder access permission via System Settings → Privacy & Security → Files and Folders.