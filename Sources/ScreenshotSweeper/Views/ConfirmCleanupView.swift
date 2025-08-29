import SwiftUI

struct ConfirmCleanupView: View {
    let count: Int
    let destinationDescription: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var acknowledged = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(format: NSLocalizedString("You're about to clean %d screenshot%@ from Desktop.", comment: "summary"), count, count == 1 ? "" : "s"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(isOn: $acknowledged) {
                Text(String(format: NSLocalizedString("I understand these files will be moved to %@", comment: "confirmation"), destinationDescription))
            }
            .toggleStyle(.checkbox)
            HStack {
                Button(NSLocalizedString("Cancel", comment: "cancel")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(NSLocalizedString("Confirm", comment: "confirm")) {
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!acknowledged)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
