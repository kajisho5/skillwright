import SwiftUI
import LintEngine

/// S-01 / S-02: files and folders on this iPhone, with the lint result per file.
struct LibraryView: View {
    @Environment(Workspace.self) private var workspace
    let folder: String?
    @State private var showingNew = false

    var body: some View {
        let entries = workspace.entries(in: folder)
        List {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No files yet", systemImage: "doc")
                } description: {
                    Text("Create one from a template.")
                } actions: {
                    Button("New File") { showingNew = true }
                        .buttonStyle(PillButtonStyle())
                        .frame(maxWidth: 260)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(entries) { entry in
                        NavigationLink(value: entry) { EntryRow(entry: entry) }
                    }
                    .onDelete { indexes in
                        for i in indexes { workspace.delete(entries[i].path) }
                    }
                }
                .listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(folder.map { ($0 as NSString).lastPathComponent } ?? String(localized: "Files"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel(Text("New File"))
            }
        }
        .navigationDestination(for: Workspace.Entry.self) { entry in
            if entry.isFolder { LibraryView(folder: entry.path) } else { EditorView(path: entry.path) }
        }
        .sheet(isPresented: $showingNew) {
            TemplateSheet(folder: folder)
        }
    }
}

private struct EntryRow: View {
    @Environment(Workspace.self) private var workspace
    let entry: Workspace.Entry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isFolder ? "folder" : "doc")
                .foregroundStyle(Theme.label)
                .frame(width: 24)
            Text(entry.isFolder ? entry.name + "/" : entry.name)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if entry.isFolder {
                Text("\(entry.childCount)").font(.system(.subheadline, design: .monospaced)).foregroundStyle(Theme.secondaryLabel)
            } else if let report = workspace.lint(path: entry.path, text: workspace.read(entry.path)) {
                LintBadge(report: report)
            }
        }
        .frame(minHeight: 44)
    }
}

/// Small mark: warning triangle, error mark, or a check.
struct LintBadge: View {
    let report: LintReport

    var body: some View {
        Group {
            if report.errorCount > 0 {
                Image(systemName: "xmark.octagon.fill").foregroundStyle(Theme.lintError)
            } else if report.warningCount > 0 {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.lintWarn)
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.label)
            }
        }
        .accessibilityLabel(Text(verbatim: "\(report.passedCount)/\(report.totalCount)"))
    }
}

struct RecentsView: View {
    var body: some View {
        ContentUnavailableView("No recent files", systemImage: "clock")
            .background(Theme.background)
            .navigationTitle("Recents")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @Environment(Workspace.self) private var workspace

    var body: some View {
        List {
            Section("Checks") {
                LabeledContent("Rules version", value: workspace.linter?.book.version ?? "—")
            }
            Section {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
