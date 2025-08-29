import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var showingPreferences: Bool
    @State private var showingConfirm = false
    @State private var showSuccess = false
    @State private var lastCleanCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Clean Now…") {
                viewModel.refreshMatchCount()
                showingConfirm = true
            }
                .keyboardShortcut(.return, modifiers: [])
            Text("Total cleaned (all-time): \(viewModel.settings.totalCleaned)")
                .padding(.top, 4)
            Text("Last run: \(viewModel.lastRunDescription)")
            Divider()
            Toggle("Daily cleanup", isOn: $viewModel.settings.cleanupEnabled)
                .onChange(of: viewModel.settings.cleanupEnabled) { _ in
                    viewModel.settings.save()
                    viewModel.updateSchedule()
                }
            Button("Open Preferences…") { showingPreferences = true }
                .keyboardShortcut(",")
            Button("Quit Screenshot Sweeper") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(minWidth: 220)
        .sheet(isPresented: $showingConfirm) {
            CleanConfirmationView(count: viewModel.matchCount, destination: viewModel.destinationDescription, isPresented: $showingConfirm) {
                let count = viewModel.cleanNow()
                lastCleanCount = count
                if count > 0 {
                    withAnimation(.spring()) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSuccess = false }
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showSuccess {
                Text("Moved \(lastCleanCount) file(s)")
                    .padding(6)
                    .background(.thinMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
