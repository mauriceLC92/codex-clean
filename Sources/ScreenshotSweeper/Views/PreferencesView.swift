import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingConfirm = false
    @State private var destChoice: DestinationChoice

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        switch viewModel.settings.destinationMode {
        case .trash: _destChoice = State(initialValue: .trash)
        case .folder: _destChoice = State(initialValue: .folder)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                scheduleSection
                destinationSection
                filterSection
                actionsSection
                aboutSection
            }
        }
        .padding(20)
        .frame(width: 420)
        .sheet(isPresented: $showingConfirm) {
            ConfirmCleanupView(count: viewModel.matchCount, destinationDescription: destinationDescription()) {
                viewModel.cleanNow()
                showingConfirm = false
            } onCancel: {
                showingConfirm = false
            }
        }
    }

    private var scheduleSection: some View {
        Section(header: Text(NSLocalizedString("Schedule", comment: "section"))) {
            Toggle(NSLocalizedString("Enable daily cleanup", comment: "toggle"), isOn: $viewModel.settings.cleanupEnabled)
                .onChange(of: viewModel.settings.cleanupEnabled) { _ in
                    viewModel.settings.save()
                    viewModel.updateSchedule()
                }
            DatePicker(NSLocalizedString("Time", comment: "time"), selection: cleanupTimeBinding, displayedComponents: .hourAndMinute)
            Text(NSLocalizedString("Sweeps your Desktop screenshots once per day.", comment: "help"))
                .font(.caption)
        }
    }

    private var destinationSection: some View {
        Section(header: Text(NSLocalizedString("Destination", comment: "section"))) {
            Picker("", selection: $destChoice) {
                Text(NSLocalizedString("Move to Trash", comment: "dest")).tag(DestinationChoice.trash)
                Text(NSLocalizedString("Move to Folder…", comment: "dest")).tag(DestinationChoice.folder)
            }
            .pickerStyle(.radioGroup)
            .onChange(of: destChoice) { newValue in
                switch newValue {
                case .trash:
                    viewModel.settings.destinationMode = .trash
                    viewModel.settings.save()
                case .folder:
                    if case .folder = viewModel.settings.destinationMode {
                        break
                    } else {
                        chooseFolder()
                    }
                }
            }

            if case .folder(let bookmark) = viewModel.settings.destinationMode {
                if let url = FolderAccess.resolveBookmark(bookmark) {
                    HStack {
                        Text(url.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(NSLocalizedString("Change", comment: "button")) {
                            chooseFolder()
                        }
                        Button(NSLocalizedString("Reveal", comment: "button")) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                } else {
                    Text(NSLocalizedString("Selected folder unavailable", comment: "warning"))
                        .foregroundColor(.red)
                    Button(NSLocalizedString("Re-select", comment: "button")) {
                        chooseFolder()
                    }
                }
            }
        }
    }

    private var filterSection: some View {
        Section(header: Text(NSLocalizedString("Filter", comment: "section"))) {
            TextField(NSLocalizedString("Prefix", comment: "field"), text: $viewModel.settings.prefix)
                .onChange(of: viewModel.settings.prefix) { _ in
                    viewModel.settings.save()
                    viewModel.refreshMatchCount()
                }
            Toggle(NSLocalizedString("Case-sensitive match", comment: "toggle"), isOn: $viewModel.settings.isCaseSensitive)
                .onChange(of: viewModel.settings.isCaseSensitive) { _ in
                    viewModel.settings.save()
                    viewModel.refreshMatchCount()
                }
            Text(NSLocalizedString("Only files on Desktop whose names start with this prefix will be cleaned.", comment: "help"))
                .font(.caption)
            Text(String(format: NSLocalizedString("Currently matching %d file(s) on Desktop.", comment: "preview"), viewModel.matchCount))
                .font(.footnote)
                .padding(.top, 4)
        }
    }

    private var actionsSection: some View {
        Section(header: Text(NSLocalizedString("Actions", comment: "section"))) {
            Button(NSLocalizedString("Clean Now…", comment: "button")) {
                viewModel.refreshMatchCount()
                showingConfirm = true
            }
            .disabled(viewModel.matchCount == 0)
            if viewModel.matchCount == 0 {
                Text(NSLocalizedString("No matching files found.", comment: "hint"))
                    .font(.caption)
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text(NSLocalizedString("About", comment: "section"))) {
            Text(appNameVersion())
            Text(NSLocalizedString("No files are uploaded; this app only moves files on your Mac.", comment: "about"))
                .font(.caption)
        }
    }

    private var cleanupTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: viewModel.settings.cleanupTime) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                viewModel.settings.cleanupTime = comps
                viewModel.settings.save()
                viewModel.updateSchedule()
            }
        )
    }

    private func chooseFolder() {
        if let bookmark = FolderAccess.selectFolder() {
            viewModel.settings.destinationMode = .folder(bookmark: bookmark)
            viewModel.settings.save()
        } else {
            destChoice = .trash
            viewModel.settings.destinationMode = .trash
            viewModel.settings.save()
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

    private func appNameVersion() -> String {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Screenshot Sweeper"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "\(name) \(version)"
    }
}

enum DestinationChoice: Hashable {
    case trash
    case folder
}
