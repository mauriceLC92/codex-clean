import SwiftUI

struct CleanConfirmationView: View {
    let count: Int
    let destination: String
    @Binding var isPresented: Bool
    var onConfirm: () -> Void

    @State private var step: Int = 1
    @State private var acknowledged = false

    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                Text("You're about to clean \(count) screenshot(s) from Desktop.")
                    .multilineTextAlignment(.center)
                HStack {
                    Button("Cancel") { isPresented = false }
                    Spacer()
                    Button("Continue") { step = 2 }
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("These files will be moved to \(destination).")
                    .multilineTextAlignment(.center)
                Toggle("I understand", isOn: $acknowledged)
                HStack {
                    Button("Cancel") { isPresented = false }
                    Spacer()
                    Button("Confirm") {
                        onConfirm()
                        isPresented = false
                        step = 1
                        acknowledged = false
                    }
                    .disabled(!acknowledged)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}
