import SwiftUI

struct CleanConfirmationView: View {
    let fileURLs: [URL]
    let destination: String
    @Binding var isPresented: Bool
    var onConfirm: () -> Void

    @State private var step: Int = 1
    @State private var acknowledged = false

    private var count: Int { fileURLs.count }

    var body: some View {
        VStack(spacing: 16) {
            if step == 1 {
                Text("You're about to clean \(count) screenshot(s) from Desktop.")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if !fileURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Files to be moved:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        List(fileURLs, id: \.self) { url in
                            Text(url.lastPathComponent)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .listStyle(.bordered(alternatesRowBackgrounds: false))
                        .frame(height: calculatedListHeight)
                    }
                }

                HStack {
                    Button("Cancel") { isPresented = false }
                    Spacer()
                    Button("Continue") { step = 2 }
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("These files will be moved to \(destination).")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
        .frame(width: 360)
    }

    private var calculatedListHeight: CGFloat {
        let rowHeight: CGFloat = 20
        let maxRows: CGFloat = 8
        let minRows: CGFloat = 3
        let desiredRows = min(CGFloat(fileURLs.count), maxRows)
        let actualRows = max(desiredRows, minRows)
        return actualRows * rowHeight + 16
    }
}
