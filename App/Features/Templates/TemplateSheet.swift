import SwiftUI
import LintEngine

/// S-07: create a file from a template.
struct TemplateSheet: View {
    @Environment(Workspace.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    let folder: String?
    @State private var template: Workspace.Template = .skill
    @State private var name = ""
    @State private var error: String?

    private var needsName: Bool { template == .skill || template == .empty }
    private var nameOK: Bool {
        switch template {
        case .skill: Linter.isValidName(name)
        case .empty: !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Picker("Template", selection: $template) {
                        ForEach(Workspace.Template.allCases) { t in
                            VStack(alignment: .leading) {
                                Text(title(t)).font(.system(.body, design: .monospaced))
                                Text(subtitle(t)).font(.caption).foregroundStyle(Theme.secondaryLabel)
                            }
                            .tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                if needsName {
                    Section {
                        TextField(template == .skill ? "kettle-guide" : "notes", text: $name)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } header: {
                        Text(template == .skill ? "Skill name (also the folder name)" : "File name")
                    } footer: {
                        if template == .skill {
                            Text(name.isEmpty || nameOK ? "Lowercase letters, numbers and hyphens only." : "This name does not follow the rules.")
                                .foregroundStyle(name.isEmpty || nameOK ? Theme.secondaryLabel : Theme.lintError)
                        }
                    }
                }
                if let error {
                    Text(error).foregroundStyle(Theme.lintError)
                }
            }
            .navigationTitle("New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        do {
                            _ = try workspace.create(template, name: name, in: folder)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    } label: { Image(systemName: "checkmark") }
                    .disabled(needsName && !nameOK)
                    .accessibilityLabel(Text("Create"))
                }
            }
        }
    }

    private func title(_ t: Workspace.Template) -> String {
        switch t {
        case .skill: "SKILL.md"
        case .claude: "CLAUDE.md"
        case .agents: "AGENTS.md"
        case .readme: "README.md"
        case .empty: String(localized: "Empty file")
        }
    }

    private func subtitle(_ t: Workspace.Template) -> String {
        switch t {
        case .skill: String(localized: "Agent Skill (follows the spec)")
        case .claude: String(localized: "Instructions for Claude Code")
        case .agents: String(localized: "Instructions for many agents")
        case .readme: String(localized: "Explanation for people")
        case .empty: String(localized: "Markdown only")
        }
    }
}
