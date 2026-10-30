import SwiftUI
import LintEngine

/// S-03: the editor card with the one-line lint status at the bottom.
struct EditorView: View {
    @Environment(Workspace.self) private var workspace
    @Environment(\.scenePhase) private var scenePhase
    let path: String

    @State private var text = ""
    @State private var loaded = false
    @State private var report: LintReport?
    @State private var showingLint = false
    @State private var editing = false
    @State private var lintTask: Task<Void, Never>?
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                MarkdownTextView(text: $text, onFocusChange: { editing = $0 })
                if let report {
                    Button { showingLint = true } label: { StatusLine(report: report) }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
            }
            .card()
            if editing {
                Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                    .buttonStyle(PillButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Theme.background)
        .navigationTitle((path as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingLint = true } label: { Image(systemName: "checklist") }
                    .accessibilityLabel(Text("Check results"))
                    .disabled(report == nil)
            }
        }
        .sheet(isPresented: $showingLint) {
            if let report { LintSheet(report: report).presentationDetents([.medium, .large]) }
        }
        .onAppear {
            guard !loaded else { return }
            text = workspace.read(path)
            loaded = true
            report = workspace.lint(path: path, text: text)
        }
        .onChange(of: text) { _, newValue in
            scheduleLint(newValue)
            scheduleSave(newValue)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { workspace.write(path, text: text) }
        }
        .onDisappear { workspace.write(path, text: text) }
    }

    /// Check 0.3 s after typing stops (design spec §9).
    private func scheduleLint(_ value: String) {
        lintTask?.cancel()
        let ws = workspace, p = path
        lintTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            report = ws.lint(path: p, text: value)
        }
    }

    /// Save 1 s after typing stops.
    private func scheduleSave(_ value: String) {
        saveTask?.cancel()
        let ws = workspace, p = path
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            ws.write(p, text: value)
        }
    }
}

private struct StatusLine: View {
    let report: LintReport

    var body: some View {
        HStack(spacing: 6) {
            if let first = report.issues.first(where: { $0.severity != .info }) {
                Image(systemName: first.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(first.severity == .error ? Theme.lintError : Theme.lintWarn)
                Text(lineText(first)).lineLimit(2)
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.label)
                Text("\(report.passedCount)/\(report.totalCount) rules passed")
            }
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(Theme.secondaryLabel)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func lineText(_ issue: LintIssue) -> String {
        if let line = issue.line { return String(localized: "Line \(line): \(issue.message)") }
        return issue.message
    }
}
