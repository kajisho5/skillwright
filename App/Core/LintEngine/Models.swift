import Foundation

/// How serious a finding is. Only `.error` and `.warning` count toward the score.
public enum Severity: String, Sendable, Codable, Comparable {
    case error, warning, info

    private var rank: Int {
        switch self {
        case .error: 0
        case .warning: 1
        case .info: 2
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rank < rhs.rank }
}

/// What kind of file is being checked. Decided from the path.
public enum FileKind: String, Sendable, Codable, CaseIterable {
    case skill, claudeMD, agentsMD, claudeRule, markdown, script

    /// Returns nil for files the linter does not look at (images, JSON, …).
    public static func detect(path: String) -> FileKind? {
        let name = (path as NSString).lastPathComponent
        let lower = name.lowercased()
        if name == "SKILL.md" { return .skill }
        if name == "CLAUDE.md" || name == "CLAUDE.local.md" { return .claudeMD }
        if name.hasPrefix("AGENTS") && lower.hasSuffix(".md") { return .agentsMD }
        if lower.hasSuffix(".md") {
            if path.hasPrefix(".claude/rules/") || path.contains("/.claude/rules/") { return .claudeRule }
            return .markdown
        }
        let components = path.split(separator: "/")
        if components.dropLast().contains("scripts") { return .script }
        return nil
    }
}

/// One finding from the linter.
public struct LintIssue: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let ruleID: String
    public let severity: Severity
    /// Already localized message (English or Japanese).
    public let message: String
    /// 1-based line number in the file, when the finding points at a line.
    public let line: Int?
    /// Document that explains the rule.
    public let reference: URL?

    public init(ruleID: String, severity: Severity, message: String, line: Int?, reference: URL?) {
        self.id = UUID()
        self.ruleID = ruleID
        self.severity = severity
        self.message = message
        self.line = line
        self.reference = reference
    }

    public static func == (lhs: LintIssue, rhs: LintIssue) -> Bool {
        lhs.ruleID == rhs.ruleID && lhs.severity == rhs.severity && lhs.message == rhs.message && lhs.line == rhs.line
    }
}

/// A `<!-- skillwright-disable … -->` marker that took effect.
public struct Suppression: Sendable, Equatable {
    public let ruleID: String
    /// Line of the marker (1-based).
    public let markerLine: Int
    /// nil = the whole file, otherwise the single line it applies to.
    public let appliesToLine: Int?
}

/// Everything the linter found in one file.
public struct LintReport: Sendable {
    public let kind: FileKind
    public let issues: [LintIssue]
    /// Rules (error or warning) that were checked and counted toward the score.
    public let countedRules: [String]
    /// Counted rules with no error or warning.
    public let passedRules: [String]
    public let suppressions: [Suppression]
    public let rulesVersion: String

    public var passedCount: Int { passedRules.count }
    public var totalCount: Int { countedRules.count }
    public var errorCount: Int { issues.filter { $0.severity == .error }.count }
    public var warningCount: Int { issues.filter { $0.severity == .warning }.count }
    public var infoCount: Int { issues.filter { $0.severity == .info }.count }
    /// True when publishing must be blocked (any error, including keys and tokens).
    public var blocksPublish: Bool { errorCount > 0 }
}

/// Everything the linter needs to know about one file and its surroundings.
public struct LintInput: Sendable {
    /// Path from the repository (or folder) root, for example "tea-timer/SKILL.md".
    public var path: String
    public var text: String
    /// Name of the folder that holds SKILL.md. Defaults to the parent folder of `path`.
    /// Set it for a SKILL.md at the repository root (use the repository name).
    public var skillFolderName: String?
    /// True when the user wants to upload the skill to claude.ai (stricter CC-01).
    public var uploadToClaudeAI: Bool
    /// Language for messages: "ja" or "en".
    public var language: String
    /// Does a file exist at this root-relative path?
    public var fileExists: @Sendable (String) -> Bool
    /// Reads another file at a root-relative path (used to follow imports and references).
    public var readFile: @Sendable (String) -> String?

    public init(path: String, text: String, skillFolderName: String? = nil, uploadToClaudeAI: Bool = false,
                language: String = "en",
                fileExists: @escaping @Sendable (String) -> Bool = { _ in false },
                readFile: @escaping @Sendable (String) -> String? = { _ in nil }) {
        self.path = path
        self.text = text
        self.skillFolderName = skillFolderName
        self.uploadToClaudeAI = uploadToClaudeAI
        self.language = language
        self.fileExists = fileExists
        self.readFile = readFile
    }
}
