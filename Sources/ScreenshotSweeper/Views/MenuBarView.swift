import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var showingPreferences: Bool
    @State private var showingConfirm = false
    @State private var toastMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(NSLocalizedString("Clean Now…", comment: "menu")) {
                viewModel.refreshMatchCount()
                showingConfirm = true
            }
            if let toastMessage {
                Text(toastMessage)
                    .font(.footnote)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .transition(.move(edge: .top))
            }

            Text(String(format: NSLocalizedString("Total cleaned (all-time): %d", comment: "status"), viewModel.settings.totalCleaned))
            Text(String(format: NSLocalizedString("Last run: %@", comment: "status"), lastRunText()))

            Divider()

            Toggle(NSLocalizedString("Daily cleanup", comment: "toggle"), isOn: $viewModel.settings.cleanupEnabled)
                .onChange(of: viewModel.settings.cleanupEnabled) { _ in
                    viewModel.settings.save()
                    viewModel.updateSchedule()
                }

            Button(NSLocalizedString("Open Preferences…", comment: "menu")) {
                showingPreferences = true
            }
            Button(NSLocalizedString("Quit Screenshot Sweeper", comment: "menu")) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
        .frame(width: 240)
        .sheet(isPresented: $showingConfirm) {
            ConfirmCleanupView(count: viewModel.matchCount, destinationDescription: destinationDescription()) {
                let cleaned = viewModel.cleanNow()
                toast(cleaned: cleaned)
                showingConfirm = false
            } onCancel: {
                showingConfirm = false
            }
        }
    }

    private func destinationDescription() -> String {
        switch viewModel.settings.destinationMode {
        case .trash:
            return NSLocalizedString("Trash", comment: "dest")
        case .folder(let bookmark):
            if let url = FolderAccess.resolveBookmark(bookmark) {
                return url.path
            }
            return NSLocalizedString("Folder", comment: "dest")
        }
    }

    private func lastRunText() -> String {
        if let date = viewModel.settings.lastRun {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
        } else {
            return NSLocalizedString("Never", comment: "status")
        }
    }

    private func toast(cleaned: Int) {
        guard cleaned > 0 else { return }
        toastMessage = String(format: NSLocalizedString("Moved %d file%@", comment: "toast"), cleaned, cleaned == 1 ? "" : "s")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}
