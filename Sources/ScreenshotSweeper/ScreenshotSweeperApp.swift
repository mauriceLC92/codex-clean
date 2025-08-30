import SwiftUI
import os.log
import AppKit

@main
struct ScreenshotSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // We need to initialize after StateObject is ready
    }
    
    var body: some Scene {
        MenuBarExtra("Screenshot Sweeper", systemImage: "trash.circle") {
            MenuBarView(viewModel: viewModel, appDelegate: appDelegate)
                .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                    viewModel.recomputeSchedule()
                }
                .onAppear {
                    // Pass viewModel to AppDelegate when view appears
                    appDelegate.viewModel = viewModel
                }
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: AppViewModel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we're running as a true menu bar app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func showPreferences() {
        if let viewModel = viewModel {
            PreferencesWindowController.shared.show(with: viewModel)
        }
    }
}
