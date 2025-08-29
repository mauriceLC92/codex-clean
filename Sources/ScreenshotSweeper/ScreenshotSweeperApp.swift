import SwiftUI
import os.log
import AppKit

@main
struct ScreenshotSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()
    @State private var showingPreferences = false

    var body: some Scene {
        MenuBarExtra("Screenshot Sweeper", systemImage: "trash.circle") {
            MenuBarView(viewModel: viewModel, showingPreferences: $showingPreferences)
        }
        .menuBarExtraStyle(.window)
        .sheet(isPresented: $showingPreferences) {
            PreferencesView(viewModel: viewModel)
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            viewModel.recomputeSchedule()
        }
    }
}
