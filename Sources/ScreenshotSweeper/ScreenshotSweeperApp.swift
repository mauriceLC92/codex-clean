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
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "preferences" }) {
                            window.level = .floating
                            window.makeKeyAndOrderFront(nil)
                            window.orderFrontRegardless()
                            window.titlebarAppearsTransparent = false
                            window.styleMask.insert([.titled, .closable, .miniaturizable])
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
    }
}
