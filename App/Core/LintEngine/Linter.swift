import Foundation
import Yams

/// Checks one markdown (or script) file against the rule book.
public struct Linter: Sendable {
    public let book: RuleBook

    public init(book: RuleBook) { self.book = book }

    public init() throws { self.book = try RuleBook.bundled() }

    // MARK: - Public entry point

    public func lint(_ input: LintInput) -> LintReport {
        guard let kind = FileKind.detect(path: input.path) else {
            return LintReport(kind: .markdown, issues: [], countedRules: [], passedRules: [], suppressions: [],
                              rulesVersion: book.version)
        }
        var ctx = Context(input: input, kind: kind, book: book)
        let scan = MarkdownScan(input.text)

        if kind == .script {
            checkSecurity(&ctx, lines: scan.allLines.enumerated().map { ($0.offset + 1, $0.element) })
        } else {
            var frontmatterOK = true
            var fields: Frontmatter?
            if kind == .skill || kind == .claudeRule {
                fields = parseFrontmatter(scan, ctx: &ctx, required: kind == .skill)
                frontmatterOK = fields != nil || kind == .claudeRule
            }
            switch kind {
            case .skill:
                if let f = fields { checkSkillFields(f, ctx: &ctx) }
                checkSkillBody(scan, fields: fields, ctx: &ctx)
            case .claudeMD:
                checkClaudeMD(scan, ctx: &ctx)
            case .agentsMD:
                checkAgentsMD(scan, ctx: &ctx)
            case .claudeRule:
                if let f = fields { checkRulePaths(f, ctx: &ctx) }
                checkLinks(scan, ruleID: "MD-01", ctx: &ctx)
            case .markdown:
                checkLinks(scan, ruleID: "MD-01", ctx: &ctx)
            case .script:
                break
            }
            checkHeadings(scan, ctx: &ctx)
            checkVagueWords(scan, ctx: &ctx)
            checkSecurity(&ctx, lines: scan.allLines.enumerated().map { ($0.offset + 1, $0.element) })
            if !frontmatterOK { ctx.skipCounting.formUnion(Self.frontmatterRules) }
        }

        return finish(ctx, scan: scan)
    }

    /// Rough token count (estimate only; real tokenizers differ). Latin text ≈ 4 characters per
    /// token, CJK ≈ 1 character per token.
    public static func estimateTokens(_ text: String) -> Int {
        var ascii = 0
        var cjk = 0
        var other = 0
        for s in text.unicodeScalars {
            if s.isASCII { ascii += 1 }
            else if (0x3000...0x9FFF).contains(s.value) || (0xAC00...0xD7AF).contains(s.value) || (0xFF00...0xFFEF).contains(s.value) { cjk += 1 }
            else { other += 1 }
        }
        return Int((Double(ascii) / 4.0 + Double(cjk) + Double(other) / 2.0).rounded(.up))
    }

    /// Estimated tokens per section (WR-02, the weight bands in the editor).
    public static func sectionWeights(_ text: String) -> [(line: Int, title: String, tokens: Int)] {
        let scan = MarkdownScan(text)
        let heads = scan.headings
        guard !heads.isEmpty else { return [] }
        var result: [(Int, String, Int)] = []
        for (i, h) in heads.enumerated() {
            let end = i + 1 < heads.count ? heads[i + 1].line : Int.max
            let chunk = scan.body.filter { $0.number >= h.line && $0.number < end }.map(\.text).joined(separator: "\n")
            result.append((h.line, h.title, estimateTokens(chunk)))
        }
        return result
    }

    // MARK: - Context

    static let frontmatterRules: Set<String> = ["SK-02", "SK-03", "SK-04", "SK-05", "SK-06", "SK-07",
                                                "CC-01", "CC-02", "CC-03", "CC-04"]

    struct Context {
        let input: LintInput
        let kind: FileKind
        let book: RuleBook
        var issues: [LintIssue] = []
        var skipCounting: Set<String> = []

        mutating func add(_ ruleID: String, line: Int?, _ values: [String: String] = [:], severity: Severity? = nil) {
            guard let rule = book.rule(ruleID) else { return }
            let msg = book.message(ruleID, language: input.language, values)
            issues.append(LintIssue(ruleID: ruleID, severity: severity ?? rule.severity, message: msg, line: line,
                                    reference: URL(string: rule.doc)))
        }
    }

    // MARK: - Frontmatter

    struct Frontmatter {
        /// key → (node, file line)
        var entries: [(key: String, node: Node, line: Int)]
        func node(_ key: String) -> Node? { entries.first { $0.key == key }?.node }
        func line(_ key: String) -> Int? { entries.first { $0.key == key }?.line }
        func string(_ key: String) -> String? { node(key)?.scalar?.string }
    }

    private func parseFrontmatter(_ scan: MarkdownScan, ctx: inout Context, required: Bool) -> Frontmatter? {
        guard let yaml = scan.frontmatter else {
            if required { ctx.add("SK-01", line: 1) }
            return nil
        }
        let node: Node?
        do { node = try Yams.compose(yaml: yaml) } catch {
            if required { ctx.add("SK-01", line: 1) }
            return nil
        }
        guard let mapping = node?.mapping else {
            if required { ctx.add("SK-01", line: 1) }
            return nil
        }
        var entries: [(String, Node, Int)] = []
        for (k, v) in mapping {
            guard let key = k.string else { continue }
            let line = (k.mark?.line ?? 1) + scan.frontmatterFirstLine - 1
            entries.append((key, v, line))
        }
        return Frontmatter(entries: entries.map { (key: $0.0, node: $0.1, line: $0.2) })
    }

    // MARK: - SKILL.md

    private func checkSkillFields(_ f: Frontmatter, ctx: inout Context) {
        let p = book.params
        // SK-02 / SK-03
        let name = f.string("name") ?? ""
        let nameLen = name.count
        if name.isEmpty || nameLen > p.nameMaxLength {
            ctx.add("SK-02", line: f.line("name") ?? 1, ["max": "\(p.nameMaxLength)", "count": "\(nameLen)"])
        } else if !Self.isValidName(name) {
            ctx.add("SK-03", line: f.line("name"))
        }
        // SK-04
        let folder = ctx.input.skillFolderName ?? (RelPath.directory(of: ctx.input.path) as NSString).lastPathComponent
        if !name.isEmpty, !folder.isEmpty, name != folder {
            ctx.add("SK-04", line: f.line("name"), ["name": name, "folder": folder])
        }
        // SK-05
        let desc = f.string("description") ?? ""
        if desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || desc.count > p.descriptionMaxLength {
            ctx.add("SK-05", line: f.line("description") ?? 1, ["max": "\(p.descriptionMaxLength)", "count": "\(desc.count)"])
        }
        // SK-06
        if let n = f.node("compatibility") {
            let c = n.scalar?.string ?? ""
            if c.isEmpty || c.count > p.compatibilityMaxLength {
                ctx.add("SK-06", line: f.line("compatibility"), ["max": "\(p.compatibilityMaxLength)", "count": "\(c.count)"])
            }
        }
        // SK-07 — metadata must be a map of text to text. A plain scalar written without quotes
        // that YAML would read as a number or yes/no (e.g. 1.0, true) is not text.
        if let n = f.node("metadata") {
            if let m = n.mapping {
                for (k, v) in m {
                    let key = k.string ?? "?"
                    guard let s = v.scalar else {
                        ctx.add("SK-07", line: f.line("metadata"), ["key": key]); continue
                    }
                    if s.style == .plain, Self.looksNonString(s.string) {
                        ctx.add("SK-07", line: (v.mark?.line ?? 1) + 1, ["key": key])
                    }
                }
            } else {
                ctx.add("SK-07", line: f.line("metadata"), ["key": "metadata"])
            }
        }
        // SK-12
        if f.node("allowed-tools") != nil { ctx.add("SK-12", line: f.line("allowed-tools")) }
        // CC-01
        for e in f.entries where !p.specFields.contains(e.key) {
            ctx.add("CC-01", line: e.line, ["key": e.key], severity: ctx.input.uploadToClaudeAI ? .error : .warning)
        }
        // CC-02
        let listing = desc.count + (f.string("when_to_use")?.count ?? 0)
        if listing > p.listingMaxChars {
            ctx.add("CC-02", line: f.line("description"), ["count": "\(listing)", "max": "\(p.listingMaxChars)"])
        }
        // CC-03
        for candidate in Set([name, folder]) where !candidate.isEmpty {
            let lower = candidate.lowercased()
            if p.reservedNames.contains(lower) || p.reservedPrefixes.contains(where: { lower.hasPrefix($0) }) {
                ctx.add("CC-03", line: f.line("name") ?? 1, ["name": candidate])
                break
            }
        }
        // CC-04
        for key in p.claudeCodeBooleanFields {
            guard let n = f.node(key) else { continue }
            let value = n.scalar?.string ?? ""
            if !p.booleanValues.contains(value.lowercased()) {
                ctx.add("CC-04", line: f.line(key), ["key": key, "value": value])
            }
        }
    }

    public static func isValidName(_ name: String) -> Bool {
        guard let first = name.first, let last = name.last, first != "-", last != "-" else { return false }
        if name.contains("--") { return false }
        return name.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "-" }
    }

    /// Plain YAML scalars that would not be read as text.
    static func looksNonString(_ s: String) -> Bool {
        let lower = s.lowercased()
        if ["true", "false", "yes", "no", "on", "off", "null", "~", ""].contains(lower) { return true }
        if Double(s) != nil { return true }
        return false
    }

    private func checkSkillBody(_ scan: MarkdownScan, fields: Frontmatter?, ctx: inout Context) {
        let p = book.params
        let bodyLines = scan.body.count
        if bodyLines > p.bodyMaxLines {
            ctx.add("SK-08", line: scan.body.first?.number, ["count": "\(bodyLines)", "max": "\(p.bodyMaxLines)"])
        }
        let tokens = Self.estimateTokens(scan.bodyText)
        if tokens > p.bodyMaxTokens {
            ctx.add("SK-09", line: scan.body.first?.number, ["count": "\(tokens)", "max": "\(p.bodyMaxTokens)"])
        }

        // SK-10: links plus bare "references/…" style paths
        let dir = RelPath.directory(of: ctx.input.path)
        var targets: [(String, Int)] = scan.links.filter { RelPath.isLocal($0.target) }.map { (RelPath.clean($0.target), $0.line) }
        let folders = p.skillFolders.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        let bare = try! NSRegularExpression(pattern: "(?<![\\w/.\\-])((?:\(folders))/[A-Za-z0-9_./\\-]*[A-Za-z0-9_])")
        for line in scan.body {
            let ns = line.text as NSString
            for m in bare.matches(in: line.text, range: NSRange(location: 0, length: ns.length)) {
                targets.append((ns.substring(with: m.range(at: 1)), line.number))
            }
        }
        var seen = Set<String>()
        for (t, line) in targets {
            guard let resolved = RelPath.resolve(t, from: dir), !resolved.isEmpty else { continue }
            let key = "\(resolved)#\(line)"
            if seen.contains(key) { continue }
            seen.insert(key)
            if !ctx.input.fileExists(resolved) {
                ctx.add("SK-10", line: line, ["path": t])
            } else if resolved.lowercased().hasSuffix(".md"), let other = ctx.input.readFile(resolved) {
                // SK-11: the referenced file points at more files
                let nested = MarkdownScan(other).links.filter { RelPath.isLocal($0.target) && !RelPath.clean($0.target).isEmpty }
                if !nested.isEmpty { ctx.add("SK-11", line: line, ["path": t]) }
            }
        }

        // SEC-03
        if let f = fields, let tools = f.node("allowed-tools") {
            let list: String
            if let s = tools.scalar?.string { list = s }
            else if let seq = tools.sequence { list = seq.compactMap { $0.string }.joined(separator: " ") }
            else { list = "" }
            let tokensInList = list.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
            let bashAll = tokensInList.contains("Bash")
            var codeText: [(Int, String)] = scan.body.filter(\.inCode).map { ($0.number, $0.text) }
            for line in scan.proseLines {
                for span in MarkdownScan.inlineCodeSpans(line.text) { codeText.append((line.number, span)) }
            }
            for tool in p.toolHints {
                let re = try! NSRegularExpression(pattern: "(^|[\\s;&|(`$])\(NSRegularExpression.escapedPattern(for: tool))(\\s|$)")
                guard let hit = codeText.first(where: { re.firstMatch(in: $0.1, range: NSRange(location: 0, length: ($0.1 as NSString).length)) != nil }) else { continue }
                if bashAll || list.contains("Bash(\(tool)") { continue }
                ctx.add("SEC-03", line: hit.0, ["tool": tool])
            }
        }
    }

    // MARK: - CLAUDE.md

    private static let importRegex = try! NSRegularExpression(pattern: #"(?:^|\s)@("[^"]+"|'[^']+'|(?:\\ |[^\s])+)"#)

    private func imports(in text: String) -> [(raw: String, line: Int)] {
        let scan = MarkdownScan(text)
        var out: [(String, Int)] = []
        for line in scan.proseLines {
            let ns = line.prose as NSString
            for m in Self.importRegex.matches(in: line.prose, range: NSRange(location: 0, length: ns.length)) {
                out.append((ns.substring(with: m.range(at: 1)), line.number))
            }
        }
        return out
    }

    private func checkClaudeMD(_ scan: MarkdownScan, ctx: inout Context) {
        let p = book.params
        if scan.allLines.count > p.claudeMdMaxLines {
            ctx.add("CC-05", line: nil, ["count": "\(scan.allLines.count)", "max": "\(p.claudeMdMaxLines)"])
        }
        let dir = RelPath.directory(of: ctx.input.path)
        var importsAgents = false
        for imp in imports(in: ctx.input.text) {
            var raw = imp.raw
            if raw.hasPrefix("\"") || raw.hasPrefix("'") {
                ctx.add("CC-07", line: imp.line, ["path": raw]); continue
            }
            raw = raw.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:)"))
            guard raw.contains("/") || raw.contains(".") else { continue }   // "@MainActor" and similar
            guard RelPath.isLocal(raw) else { continue }                    // ~/ and absolute paths cannot be checked here
            let path = raw.replacingOccurrences(of: "\\ ", with: " ")
            if (path as NSString).lastPathComponent == "AGENTS.md" { importsAgents = true }
            guard let resolved = RelPath.resolve(path, from: dir) else { continue }
            if !ctx.input.fileExists(resolved) {
                ctx.add("CC-06", line: imp.line, ["path": raw, "max": "\(p.importMaxDepth)"])
            } else if importDepth(from: resolved, depth: 1, visited: [ctx.input.path], read: ctx.input.readFile) > p.importMaxDepth {
                ctx.add("CC-06", line: imp.line, ["path": raw, "max": "\(p.importMaxDepth)"])
            }
        }
        // CC-08
        let agents = dir.isEmpty ? "AGENTS.md" : dir + "/AGENTS.md"
        if ctx.input.fileExists(agents) && !importsAgents {
            ctx.add("CC-08", line: nil)
        }
        checkLinks(scan, ruleID: "MD-01", ctx: &ctx)
    }

    /// Deepest import chain starting at `path` (which itself is at `depth`).
    private func importDepth(from path: String, depth: Int, visited: Set<String>,
                             read: @Sendable (String) -> String?) -> Int {
        guard depth <= book.params.importMaxDepth + 1, let text = read(path) else { return depth }
        var deepest = depth
        let dir = RelPath.directory(of: path)
        for imp in imports(in: text) {
            let raw = imp.raw.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:)"))
            guard raw.contains("/") || raw.contains("."), RelPath.isLocal(raw), !raw.hasPrefix("\""), !raw.hasPrefix("'") else { continue }
            guard let next = RelPath.resolve(raw.replacingOccurrences(of: "\\ ", with: " "), from: dir),
                  !visited.contains(next) else { continue }
            deepest = max(deepest, importDepth(from: next, depth: depth + 1, visited: visited.union([path]), read: read))
        }
        return deepest
    }


    // MARK: - AGENTS.md

    private func checkAgentsMD(_ scan: MarkdownScan, ctx: inout Context) {
        let name = (ctx.input.path as NSString).lastPathComponent
        ctx.add("AG-01", line: nil)
        if name != "AGENTS.md" { ctx.add("AG-03", line: nil, ["name": name]) }
        checkLinks(scan, ruleID: "AG-02", ctx: &ctx)
    }

    // MARK: - .claude/rules

    private func checkRulePaths(_ f: Frontmatter, ctx: inout Context) {
        guard let n = f.node("paths") else { return }
        if n.scalar != nil { return }
        if let seq = n.sequence, seq.allSatisfy({ $0.scalar != nil }) { return }
        ctx.add("CC-09", line: f.line("paths"))
    }

    // MARK: - Shared checks

    private func checkLinks(_ scan: MarkdownScan, ruleID: String, ctx: inout Context) {
        let dir = RelPath.directory(of: ctx.input.path)
        for link in scan.links where RelPath.isLocal(link.target) {
            let cleaned = RelPath.clean(link.target)
            guard !cleaned.isEmpty, let resolved = RelPath.resolve(cleaned, from: dir) else { continue }
            if !ctx.input.fileExists(resolved) { ctx.add(ruleID, line: link.line, ["path": link.target]) }
        }
    }

    private func checkHeadings(_ scan: MarkdownScan, ctx: inout Context) {
        var previous: Int?
        for h in scan.headings {
            if let prev = previous, h.level > prev + 1 {
                ctx.add("MD-02", line: h.line, ["from": "\(prev)", "to": "\(h.level)"])
            }
            previous = h.level
        }
    }

    private func checkVagueWords(_ scan: MarkdownScan, ctx: inout Context) {
        let all = (book.vagueWords["en"] ?? []) + (book.vagueWords["ja"] ?? [])
        guard !all.isEmpty else { return }
        for line in scan.proseLines {
            let lower = line.prose.lowercased()
            for word in all {
                let w = word.lowercased()
                guard lower.contains(w) else { continue }
                if w.unicodeScalars.allSatisfy(\.isASCII) {
                    let re = try! NSRegularExpression(pattern: "(?<![A-Za-z])\(NSRegularExpression.escapedPattern(for: w))(?![A-Za-z])")
                    guard re.firstMatch(in: lower, range: NSRange(location: 0, length: (lower as NSString).length)) != nil else { continue }
                }
                ctx.add("WR-01", line: line.number, ["word": word])
            }
        }
    }

    private func checkSecurity(_ ctx: inout Context, lines: [(Int, String)]) {
        let p = book.params
        let dangerous = p.dangerousPatterns.compactMap { try? NSRegularExpression(pattern: $0) }
        let secrets = p.secretPatterns.compactMap { try? NSRegularExpression(pattern: $0) }
        for (n, text) in lines {
            let range = NSRange(location: 0, length: (text as NSString).length)
            if let m = dangerous.lazy.compactMap({ $0.firstMatch(in: text, range: range) }).first {
                var s = (text as NSString).substring(with: m.range).trimmingCharacters(in: .whitespaces)
                if s.count > 40 { s = String(s.prefix(40)) + "…" }
                ctx.add("SEC-01", line: n, ["match": s])
            }
            if secrets.contains(where: { $0.firstMatch(in: text, range: range) != nil }) {
                ctx.add("SEC-02", line: n)
            }
        }
    }

    // MARK: - Suppressions and score

    private static let markerRegex = try! NSRegularExpression(
        pattern: #"<!--\s*skillwright-disable(-next-line)?\s+([A-Za-z0-9\-\s,]+?)\s*-->"#)

    private func finish(_ ctxIn: Context, scan: MarkdownScan) -> LintReport {
        var ctx = ctxIn
        var suppressions: [Suppression] = []
        var markerIssues: [LintIssue] = []
        let lang = ctx.input.language
        for (i, text) in scan.allLines.enumerated() {
            let ns = text as NSString
            for m in Self.markerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let nextLine = m.range(at: 1).location != NSNotFound
                let ids = ns.substring(with: m.range(at: 2)).split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
                for id in ids {
                    guard let rule = book.rule(id) else {
                        let reason = lang == "ja" ? "\(id) という決まりはありません" : "there is no rule \(id)"
                        markerIssues.append(issue("SW-01", line: i + 1, ["reason": reason], lang)); continue
                    }
                    if rule.severity == .error {
                        let reason = lang == "ja" ? "\(id) は違反の決まりなので除外できません" : "\(id) is an error rule and cannot be skipped"
                        markerIssues.append(issue("SW-01", line: i + 1, ["reason": reason], lang)); continue
                    }
                    suppressions.append(Suppression(ruleID: id, markerLine: i + 1, appliesToLine: nextLine ? i + 2 : nil))
                }
            }
        }
        let fileWide = Set(suppressions.filter { $0.appliesToLine == nil }.map(\.ruleID))
        ctx.issues.removeAll { issue in
            guard issue.severity != .error else { return false }
            if fileWide.contains(issue.ruleID) { return true }
            return suppressions.contains { $0.ruleID == issue.ruleID && $0.appliesToLine != nil && $0.appliesToLine == issue.line }
        }
        ctx.issues += markerIssues
        ctx.issues.sort { ($0.severity, $0.line ?? 0) < ($1.severity, $1.line ?? 0) }

        let counted = book.rules
            .filter { $0.kinds.contains(ctx.kind) && $0.severity != .info }
            .map(\.id)
            .filter { !fileWide.contains($0) && !ctx.skipCounting.contains($0) }
        let failing = Set(ctx.issues.filter { $0.severity != .info }.map(\.ruleID))
        let passed = counted.filter { !failing.contains($0) }
        return LintReport(kind: ctx.kind, issues: ctx.issues, countedRules: counted, passedRules: passed,
                          suppressions: suppressions, rulesVersion: book.version)
    }

    private func issue(_ id: String, line: Int, _ values: [String: String], _ lang: String) -> LintIssue {
        let r = book.rule(id)
        return LintIssue(ruleID: id, severity: r?.severity ?? .info, message: book.message(id, language: lang, values),
                         line: line, reference: r.flatMap { URL(string: $0.doc) })
    }
}
