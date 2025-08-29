import SwiftUI
import os.log

@main
struct ScreenshotSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()
    @State private var showingPreferences = false

    var body: some Scene {
        MenuBarExtra("Screenshot Sweeper", systemImage: "camera.fill.badge.ellipsis") {
            MenuBarView(viewModel: viewModel, showingPreferences: $showingPreferences)
        }
        .menuBarExtraStyle(.window)
        .sheet(isPresented: $showingPreferences) {
            PreferencesView(viewModel: viewModel)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Preferences…", comment: "command")) {
                    showingPreferences = true
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}
