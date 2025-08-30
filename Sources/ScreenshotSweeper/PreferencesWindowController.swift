import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    
    private var viewModel: AppViewModel?
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screenshot Sweeper Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PreferencesWindow")
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(with viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Set up the content view with SwiftUI
        if let viewModel = self.viewModel {
            let preferencesView = PreferencesView(viewModel: viewModel)
            let hostingView = NSHostingView(rootView: preferencesView)
            window?.contentView = hostingView
        }
        
        // Switch to regular activation policy to show in dock temporarily
        NSApp.setActivationPolicy(.regular)
        
        // Activate the app and show window
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        
        // Ensure window becomes key
        window?.makeMain()
        window?.makeKey()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Switch back to accessory mode when preferences close
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of close to maintain state
        sender.orderOut(nil)
        // Switch back to accessory mode
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        return false
    }
}