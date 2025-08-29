import SwiftUI
import os.log

@main
struct ScreenshotSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()
    @State private var showingPreferences = false

    var body: some Scene {
        MenuBarExtra("Screenshot Sweeper", systemImage: "scissors") {
            MenuBarView(viewModel: viewModel, showingPreferences: $showingPreferences)
        }
        .menuBarExtraStyle(.window)
        .sheet(isPresented: $showingPreferences) {
            PreferencesView(viewModel: viewModel)
        }
    }
}
