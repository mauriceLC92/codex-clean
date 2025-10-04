# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Screenshot Sweeper is a macOS menu bar app built with Swift and SwiftUI that automatically moves Desktop screenshots to the Trash or a specified folder on a scheduled basis. The app uses Swift Package Manager and targets macOS 13+.

## Development Commands

### Building and Running (Makefile)
```bash
make build                    # Build app bundle via build-app.sh
make run                      # Open the built app
make clean                    # Remove .build and build directories
make rebuild                  # Clean and build from scratch
```

### Building and Running (Swift Package Manager)
```bash
swift build                    # Build the project
swift run                     # Build and run the executable
swift build --configuration release  # Release build
./build-app.sh                # Create macOS app bundle with code signing
./build-app.sh release        # Create release app bundle
```

### Testing
```bash
swift test                    # Run all tests
swift test --parallel         # Run tests in parallel
swift test --filter NextRunCalculatorTests  # Run specific test class
```

### Package Management
```bash
swift package resolve         # Resolve dependencies
swift package clean          # Clean build artifacts
swift package reset          # Reset package state
```

## Architecture

### Core Components

- **ScreenshotSweeperApp.swift**: Main app entry point using `@main` and MenuBarExtra
- **AppViewModel**: Central state management using `@StateObject`, coordinates between services
- **CleanupService**: Core business logic for finding and moving screenshot files
- **Scheduler**: Handles timer-based automatic cleanup scheduling
- **Settings**: Codable model with UserDefaults persistence using security-scoped bookmarks

### Key Patterns

- **MVVM Architecture**: Views bind to AppViewModel via `@Published` properties
- **Service Layer**: CleanupService, FolderAccess, and Scheduler provide isolated functionality
- **Security-Scoped Resources**: Folder destinations use bookmarks for sandboxed file access
- **Permission Handling**: Extensive logging and error handling for macOS file permissions

### Data Flow

1. Settings loaded from UserDefaults on app launch
2. AppViewModel coordinates between UI and services
3. Scheduler uses NextRunCalculator for time-based cleanup
4. CleanupService performs file operations with permission checks
5. Results update Settings and trigger UI refreshes

### File Organization

- `Models/`: Data structures (Settings)
- `Services/`: Business logic (CleanupService, FolderAccess, Scheduler)
- `ViewModels/`: State management (AppViewModel)
- `Views/`: SwiftUI interface components
- `Utilities/`: Helper functions (NextRunCalculator)
- `Tests/`: XCTest unit tests

## SwiftUI Architecture Specifics

### Scene Management
- **MenuBarExtra + NSWindow Pattern**: App uses MenuBarExtra for menu bar presence and PreferencesWindowController for preferences window management
- **Window Opening**: Preferences opened via `PreferencesWindowController.shared.show(with: viewModel)`
- **Activation Policy**: App dynamically switches between `.accessory` (menu bar only) and `.regular` (shows in dock) when preferences window opens/closes
- **State Sharing**: Single `@StateObject private var viewModel` shared between MenuBarExtra and preferences window via AppDelegate

### TextField Binding Pattern
When binding TextFields to nested struct properties in @Published objects, use custom Binding for reliable updates:
```swift
TextField("Prefix", text: Binding(
    get: { viewModel.settings.prefix },
    set: { newValue in
        viewModel.settings.prefix = newValue
        viewModel.settings.save()
        // Additional side effects like refresh
    }
))
```

### Settings Persistence
- Settings stored as JSON in UserDefaults with bundle-namespaced keys
- Security-scoped bookmarks stored as Data for folder access permissions
- Manual save() calls required after settings changes

### Screenshot Detection & Cleanup Logic
- **File Matching**: Matches files by prefix (case-sensitive or insensitive) with extensions: png, jpg, jpeg, heic, tiff
- **Conflict Resolution**: Uses automatic renaming (filename-1.ext, filename-2.ext, etc.) when moving to folders
- **Error Handling**: Distinguishes between permission errors (throws) and file-busy errors (skips with logging)
- **Automatic Cleanup**: Runs only at scheduled time, never on app startup or wake from sleep

## Known Issues

### TextField Input Issues
The app has known issues with TextField input not working properly in certain configurations. This affects the prefix input field in preferences. The issue persists across different binding approaches and may be related to SwiftUI Form + Window interaction patterns on macOS.

## Permissions Requirements

The app requires Desktop folder access permission. Users must grant permission via System Settings → Privacy & Security → Files and Folders. The app handles permission errors gracefully and provides clear logging.