# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Screenshot Sweeper is a macOS menu bar app built with Swift and SwiftUI that automatically moves Desktop screenshots to the Trash or a specified folder on a scheduled basis. The app uses Swift Package Manager and targets macOS 13+.

## Development Commands

### Building and Running
```bash
swift build                    # Build the project
swift run                     # Build and run the executable
swift build --configuration release  # Release build
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

## Permissions Requirements

The app requires Desktop folder access permission. Users must grant permission via System Settings → Privacy & Security → Files and Folders. The app handles permission errors gracefully and provides clear logging.