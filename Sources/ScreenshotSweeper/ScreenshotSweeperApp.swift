import SwiftUI
import os.log
import AppKit

@main
struct ScreenshotSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra("Screenshot Sweeper", systemImage: "trash.circle") {
            MenuBarView(viewModel: viewModel)
                .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                    viewModel.recomputeSchedule()
                }
        }
        .menuBarExtraStyle(.window)
        
        Window("Preferences", id: "preferences") {
            PreferencesView(viewModel: viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
    }
}
