import SwiftUI
import LintEngine

/// S-05: check results.
struct LintSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let report: LintReport

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(verbatim: "\(report.passedCount)/\(report.totalCount)")
                            .font(.system(size: 52, weight: .medium))
                            .monospacedDigit()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary).font(.headline)
                            Text("Agent Skills spec + Claude Code").font(.footnote).foregroundStyle(Theme.secondaryLabel)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                .listRowBackground(Color.clear)

                if report.issues.isEmpty {
                    Section { Label("No problems found", systemImage: "checkmark.circle") }
                } else {
                    Section {
                        ForEach(report.issues) { issue in
                            IssueRow(issue: issue) { if let url = issue.reference { openURL(url) } }
                        }
                    }
                }
                if !report.suppressions.isEmpty {
                    Section {
                        Text("\(report.suppressions.count) rule(s) skipped by markers")
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                }
                Section {
                    Text("Rules \(report.rulesVersion)").font(.footnote.monospaced()).foregroundStyle(Theme.secondaryLabel)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Check results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close"))
                }
            }
        }
    }

    private var summary: String {
        if report.errorCount > 0 { return String(localized: "\(report.errorCount) error(s)") }
        if report.warningCount > 0 { return String(localized: "\(report.warningCount) warning(s)") }
        return String(localized: "All rules passed")
    }
}

private struct IssueRow: View {
    let issue: LintIssue
    let openDoc: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                icon
                Text(issue.message).font(.body)
            }
            HStack(spacing: 12) {
                Text(verbatim: issue.ruleID + (issue.line.map { " · \(String(localized: "line \($0)"))" } ?? ""))
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.secondaryLabel)
                Spacer()
                if issue.reference != nil {
                    Button("See source", action: openDoc).font(.footnote).underline()
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var icon: some View {
        switch issue.severity {
        case .error: Image(systemName: "xmark.octagon.fill").foregroundStyle(Theme.lintError)
        case .warning: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.lintWarn)
        case .info: Image(systemName: "info.circle").foregroundStyle(Theme.secondaryLabel)
        }
    }
}
