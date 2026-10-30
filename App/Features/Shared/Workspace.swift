import Foundation
import Observation
import LintEngine

/// Files on this device, inside the app's Documents folder (design spec §10-1, "このiPhone").
/// GitHub workspaces come later and will live under Workspaces/github/….
@Observable
final class Workspace {
    struct Entry: Identifiable, Hashable {
        var id: String { path }
        let path: String       // relative to `root`
        let name: String
        let isFolder: Bool
        let childCount: Int
    }

    enum Template: String, CaseIterable, Identifiable {
        case skill, claude, agents, readme, empty
        var id: String { rawValue }
    }

    enum CreateError: LocalizedError {
        case invalidName, alreadyExists
        var errorDescription: String? {
            switch self {
            case .invalidName: String(localized: "Use lowercase letters, numbers and hyphens only.")
            case .alreadyExists: String(localized: "A file with this name already exists.")
            }
        }
    }

    let root: URL
    let linter: Linter?
    /// Bumped whenever files change so lists refresh.
    private(set) var revision = 0

    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.linter = try? Linter()
    }

    static var language: String {
        Locale.current.language.languageCode?.identifier == "ja" ? "ja" : "en"
    }

    func url(_ path: String) -> URL { path.isEmpty ? root : root.appending(path: path) }

    func entries(in folder: String?) -> [Entry] {
        _ = revision
        let base = url(folder ?? "")
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: base.path(percentEncoded: false)) else { return [] }
        let list: [Entry] = names.filter { !$0.hasPrefix(".") }.map { name in
            let rel = folder.map { "\($0)/\(name)" } ?? name
            var isDir: ObjCBool = false
            fm.fileExists(atPath: url(rel).path(percentEncoded: false), isDirectory: &isDir)
            let count = isDir.boolValue ? ((try? fm.contentsOfDirectory(atPath: url(rel).path(percentEncoded: false)))?.filter { !$0.hasPrefix(".") }.count ?? 0) : 0
            return Entry(path: rel, name: name, isFolder: isDir.boolValue, childCount: count)
        }
        return list.sorted { ($0.isFolder ? 0 : 1, $0.name.lowercased()) < ($1.isFolder ? 0 : 1, $1.name.lowercased()) }
    }

    func read(_ path: String) -> String {
        (try? String(contentsOf: url(path), encoding: .utf8)) ?? ""
    }

    func write(_ path: String, text: String) {
        try? text.write(to: url(path), atomically: true, encoding: .utf8)
    }

    func delete(_ path: String) {
        try? FileManager.default.removeItem(at: url(path))
        revision += 1
    }

    /// Creates a file from a template and returns its path.
    func create(_ template: Template, name rawName: String, in folder: String?) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespaces)
        let ja = Self.language == "ja"
        let fm = FileManager.default
        func target(_ rel: String) -> String { folder.map { "\($0)/\(rel)" } ?? rel }
        let path: String
        let text: String
        switch template {
        case .skill:
            guard Linter.isValidName(name) else { throw CreateError.invalidName }
            path = target("\(name)/SKILL.md")
            text = "---\nname: \(name)\ndescription: \n---\n\n# \(name)\n\n" + (ja ? "## 使い方\n" : "## Steps\n")
        case .claude:
            path = target("CLAUDE.md")
            text = ja ? "# このリポの決まり\n\n## よく使うコマンド\n\n## 書き方の決まり\n" : "# Project rules\n\n## Common commands\n\n## Style\n"
        case .agents:
            path = target("AGENTS.md")
            text = ja ? "# AGENTS.md\n\n## 準備\n\n## テスト\n" : "# AGENTS.md\n\n## Setup\n\n## Testing\n"
        case .readme:
            path = target("README.md")
            text = "# \(folder.map { ($0 as NSString).lastPathComponent } ?? (name.isEmpty ? "README" : name))\n\n"
        case .empty:
            guard !name.isEmpty, !name.contains("/") else { throw CreateError.invalidName }
            path = target(name.lowercased().hasSuffix(".md") ? name : name + ".md")
            text = ""
        }
        let fileURL = url(path)
        guard !fm.fileExists(atPath: fileURL.path(percentEncoded: false)) else { throw CreateError.alreadyExists }
        try fm.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        revision += 1
        return path
    }

    /// Lints one file. Paths in the report are relative to `root`.
    func lint(path: String, text: String) -> LintReport? {
        guard let linter, FileKind.detect(path: path) != nil else { return nil }
        let rootURL = root
        let input = LintInput(
            path: path, text: text, language: Self.language,
            fileExists: { FileManager.default.fileExists(atPath: rootURL.appending(path: $0).path(percentEncoded: false)) },
            readFile: { try? String(contentsOf: rootURL.appending(path: $0), encoding: .utf8) })
        return linter.lint(input)
    }
}
