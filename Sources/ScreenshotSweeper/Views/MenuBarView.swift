import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var showingPreferences: Bool
    @State private var confirmCleanup = false

    var body: some View {
        VStack {
            Text("Total cleaned: \(viewModel.settings.totalCleaned)")
                .padding(.horizontal)
            Divider()
            Button("Clean Now…") {
                confirmCleanup = true
            }
            .alert("Clean Desktop Screenshots?", isPresented: $confirmCleanup) {
                Button("Cancel", role: .cancel) {}
                Button("Clean", role: .destructive) {
                    viewModel.cleanNow()
                }
            } message: {
                Text("This will move matching screenshots according to your settings.")
            }
            Divider()
            Button("Preferences…") {
                showingPreferences = true
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
