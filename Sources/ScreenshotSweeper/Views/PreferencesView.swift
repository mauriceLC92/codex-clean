import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingConfirm = false
    @State private var showSuccess = false
    @State private var lastCleanCount = 0
    @State private var lastSkippedCount = 0
    @State private var cleanupTime: Date = Calendar.current.date(from: AppViewModel.defaultDateComponents) ?? Date()
    @State private var destinationChoice: Int = 0

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _cleanupTime = State(initialValue: Calendar.current.date(from: viewModel.settings.cleanupTime) ?? Date())
        switch viewModel.settings.destinationMode {
        case .trash:
            _destinationChoice = State(initialValue: 0)
        case .folder:
            _destinationChoice = State(initialValue: 1)
        }
    }

    var body: some View {
        Form {
            Section("Schedule") {
                Toggle("Enable daily cleanup", isOn: $viewModel.settings.cleanupEnabled)
                    .onChange(of: viewModel.settings.cleanupEnabled) { _ in
                        viewModel.settings.save()
                        viewModel.updateSchedule()
                    }
                DatePicker("Time", selection: $cleanupTime, displayedComponents: .hourAndMinute)
                    .onChange(of: cleanupTime) { newValue in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        viewModel.settings.cleanupTime = comps
                        viewModel.settings.save()
                        viewModel.updateSchedule()
                    }
                    .disabled(!viewModel.settings.cleanupEnabled)
                Text("Sweeps your Desktop screenshots once per day.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Destination") {
                Picker("", selection: $destinationChoice) {
                    Text("Move to Trash").tag(0)
                    Text("Move to Folder").tag(1)
                }
                .pickerStyle(.radioGroup)
                .onChange(of: destinationChoice) { newValue in
                    if newValue == 0 {
                        viewModel.settings.destinationMode = .trash
                        viewModel.settings.save()
                    }
                }

                if destinationChoice == 1 {
                    if let url = viewModel.destinationURL {
                        HStack {
                            Text(url.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("Change") { chooseFolder() }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    } else {
                        HStack {
                            Text("Folder unavailable")
                                .foregroundColor(.red)
                            Button("Re-select") { chooseFolder() }
                        }
                    }
                }
            }

            Section("Filter") {
                TextField("Prefix", text: Binding(
                    get: { viewModel.settings.prefix },
                    set: { newValue in
                        viewModel.settings.prefix = newValue
                        viewModel.settings.save()
                        viewModel.refreshMatchCount()
                    }
                ))
                .textFieldStyle(.roundedBorder)
                Toggle("Case-sensitive match", isOn: $viewModel.settings.isCaseSensitive)
                    .onChange(of: viewModel.settings.isCaseSensitive) { _ in
                        viewModel.settings.save()
                        viewModel.refreshMatchCount()
                    }
                Text("Only files on Desktop whose names start with this prefix will be cleaned.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Text("Currently matching \(viewModel.matchCount) file(s) on Desktop.")
                .font(.footnote)
                .foregroundColor(.secondary)

            Section("Actions") {
                Button("Clean Now") { showingConfirm = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.matchCount == 0)
                if viewModel.matchCount == 0 {
                    Text("No matching files found.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section("About") {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                Text("Screenshot Sweeper \(version)")
                Text("No files are uploaded; this app only moves files on your Mac.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 400)
        .opacity(showingConfirm ? 0 : 1)
        .overlay {
            if showingConfirm {
                CleanConfirmationView(fileURLs: viewModel.matchedFiles, destination: viewModel.destinationDescription, isPresented: $showingConfirm) {
                    let result = viewModel.cleanNow()
                    lastCleanCount = result.cleaned
                    lastSkippedCount = result.skipped
                    if result.cleaned > 0 || result.skipped > 0 {
                        withAnimation(.spring()) { showSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccess = false }
                        }
                    }
                }
                .padding(20)
                .frame(width: 400)
            }
        }
        .overlay(alignment: .top) {
            if showSuccess {
                Text("Moved \(lastCleanCount) file(s), skipped \(lastSkippedCount)")
                    .padding(6)
                    .background(.thinMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.refreshMatchCount()
        }
    }

    private func chooseFolder() {
        if let bm = FolderAccess.selectFolder() {
            viewModel.settings.destinationMode = .folder(bookmark: bm)
            viewModel.settings.save()
            viewModel.refreshMatchCount()
        }
    }
}

extension AppViewModel {
    static var defaultDateComponents: DateComponents { DateComponents(hour: 23, minute: 59) }
}