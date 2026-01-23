# Optimization Notes

## Changes Made (Jan 2026)

### Safe Changes

1. **Static RelativeDateTimeFormatter** - Safe. It's thread-safe for reading and only called from main thread anyway.

2. **maxDisplayFiles limit (100)** - Safe. `matchCount` still shows the real count, only `matchedFiles` array is capped. Cleanup processes all files.

3. **weak viewModel in PreferencesWindowController** - Safe. The ViewModel is held by the App's `@StateObject`, so it won't be deallocated while the app runs.

### Potentially Risky Changes

4. **Debounced save (500ms delay)** - **Risk**: If the user quits the app within 500ms of typing, their last change might not be saved. The settings are saved immediately on toggle changes for schedule/destination, but prefix changes use debouncing.

5. **Timer tolerance (10%, min 60s)** - **Risk**: Cleanup could fire up to 10% late (or ~6 seconds minimum for short intervals, 60 seconds for long intervals). For a daily cleanup, this means it could fire up to ~2.4 hours late in the worst case. That's probably fine for this use case, but worth knowing.

## Files Changed

- `Sources/ScreenshotSweeper/Utilities/Debouncer.swift` (new)
- `Sources/ScreenshotSweeper/ViewModels/AppViewModel.swift`
- `Sources/ScreenshotSweeper/Views/PreferencesView.swift`
- `Sources/ScreenshotSweeper/Services/Scheduler.swift`
- `Sources/ScreenshotSweeper/PreferencesWindowController.swift`
- `Tests/ScreenshotSweeperTests/DebouncerTests.swift` (new)
