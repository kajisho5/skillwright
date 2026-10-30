import Foundation

/// A light, dependency-free reading of a markdown file: frontmatter, lines inside code,
/// links, headings. Good enough for the checks; the preview uses a full parser.
struct MarkdownScan {
    struct Line {
        let number: Int          // 1-based line number in the file
        let text: String
        let inCode: Bool         // inside a fenced code block (fence lines included)
        /// Text with inline `code` spans blanked out (same length). Empty for code lines.
        let prose: String
    }

    struct Link {
        let target: String
        let line: Int
    }

    let allLines: [String]
    /// nil when the file has no frontmatter block.
    let frontmatter: String?
    /// 1-based line number of the first frontmatter line (the line after `---`).
    let frontmatterFirstLine: Int
    /// True when the file starts with `---` but the block is never closed.
    let frontmatterUnclosed: Bool
    let body: [Line]

    init(_ text: String) {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        var lines = normalized.components(separatedBy: "\n")
        if lines.last == "" && normalized.hasSuffix("\n") { lines.removeLast() }
        allLines = lines

        var bodyStart = 0
        var fm: String?
        var unclosed = false
        if let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---" {
            if let end = lines.indices.dropFirst().first(where: {
                let t = lines[$0].trimmingCharacters(in: .whitespaces)
                return t == "---" || t == "..."
            }) {
                fm = lines[1..<end].joined(separator: "\n")
                bodyStart = end + 1
            } else {
                unclosed = true
            }
        }
        frontmatter = fm
        frontmatterFirstLine = 2
        frontmatterUnclosed = unclosed

        var out: [Line] = []
        var fenceChar: Character?
        var fenceLen = 0
        for i in bodyStart..<max(bodyStart, lines.count) {
            let raw = lines[i]
            let trimmed = raw.drop(while: { $0 == " " })
            let indent = raw.count - trimmed.count
            var isFence = false
            if indent <= 3, let c = trimmed.first, c == "`" || c == "~" {
                let run = trimmed.prefix(while: { $0 == c }).count
                if run >= 3 {
                    if fenceChar == nil {
                        fenceChar = c; fenceLen = run; isFence = true
                    } else if c == fenceChar, run >= fenceLen,
                              trimmed.dropFirst(run).trimmingCharacters(in: .whitespaces).isEmpty {
                        isFence = true
                        out.append(Line(number: i + 1, text: raw, inCode: true, prose: ""))
                        fenceChar = nil
                        continue
                    }
                }
            }
            let inCode = fenceChar != nil || isFence
            out.append(Line(number: i + 1, text: raw, inCode: inCode, prose: inCode ? "" : Self.blankInlineCode(raw)))
        }
        body = out
    }

    /// Body text only (what an agent reads after the frontmatter).
    var bodyText: String { body.map(\.text).joined(separator: "\n") }

    /// Lines that hold prose (not inside code).
    var proseLines: [Line] { body.filter { !$0.inCode } }

    /// Replace `inline code` with spaces so that links and words inside it are ignored.
    static func blankInlineCode(_ s: String) -> String {
        var result = ""
        var inSpan = false
        var ticks = 0
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            if chars[i] == "`" {
                var run = 0
                while i + run < chars.count, chars[i + run] == "`" { run += 1 }
                if !inSpan { inSpan = true; ticks = run } else if run == ticks { inSpan = false }
                result += String(repeating: " ", count: run)
                i += run
                continue
            }
            result.append(inSpan ? " " : chars[i])
            i += 1
        }
        return result
    }

    /// Inline code spans in a line, without the backticks.
    static func inlineCodeSpans(_ s: String) -> [String] {
        var spans: [String] = []
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            guard chars[i] == "`" else { i += 1; continue }
            var run = 0
            while i + run < chars.count, chars[i + run] == "`" { run += 1 }
            let start = i + run
            var j = start
            var found = false
            while j < chars.count {
                if chars[j] == "`" {
                    var r = 0
                    while j + r < chars.count, chars[j + r] == "`" { r += 1 }
                    if r == run { spans.append(String(chars[start..<j])); i = j + r; found = true; break }
                    j += r
                } else { j += 1 }
            }
            if !found { i = start }
        }
        return spans
    }

    private static let linkRegex = try! NSRegularExpression(
        pattern: #"!?\[(?:[^\]\\]|\\.)*\]\(\s*<?([^)\s>]+)>?(?:\s+["'(][^)]*)?\)"#)
    private static let refDefRegex = try! NSRegularExpression(pattern: #"^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(\s|$)"#)

    /// Markdown links and images in prose, plus reference definitions.
    var links: [Link] {
        var result: [Link] = []
        for line in proseLines {
            let ns = line.prose as NSString
            for m in Self.linkRegex.matches(in: line.prose, range: NSRange(location: 0, length: ns.length)) {
                result.append(Link(target: ns.substring(with: m.range(at: 1)), line: line.number))
            }
            if let m = Self.refDefRegex.firstMatch(in: line.prose, range: NSRange(location: 0, length: ns.length)) {
                result.append(Link(target: ns.substring(with: m.range(at: 1)), line: line.number))
            }
        }
        return result
    }

    /// ATX headings outside code: (level, line).
    var headings: [(level: Int, line: Int, title: String)] {
        proseLines.compactMap { line in
            let t = line.text.drop(while: { $0 == " " })
            guard line.text.count - t.count <= 3 else { return nil }
            let hashes = t.prefix(while: { $0 == "#" }).count
            guard (1...6).contains(hashes) else { return nil }
            let rest = t.dropFirst(hashes)
            guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }
            return (hashes, line.number, rest.trimmingCharacters(in: .whitespaces))
        }
    }
}

/// Path helpers for root-relative paths ("a/b/c.md").
enum RelPath {
    static func directory(of path: String) -> String {
        let d = (path as NSString).deletingLastPathComponent
        return d
    }

    /// True for links that point at a file inside the repository.
    static func isLocal(_ target: String) -> Bool {
        let lower = target.lowercased()
        if target.isEmpty || target.hasPrefix("#") || target.hasPrefix("/") || target.hasPrefix("~") { return false }
        if lower.contains("://") || lower.hasPrefix("mailto:") || lower.hasPrefix("tel:") || lower.hasPrefix("data:") { return false }
        return true
    }

    /// Removes `#fragment` and `?query`, decodes %20 and similar.
    static func clean(_ target: String) -> String {
        var t = target
        if let i = t.firstIndex(where: { $0 == "#" || $0 == "?" }) { t = String(t[..<i]) }
        return t.removingPercentEncoding ?? t
    }

    /// Joins and normalizes. Returns nil when the path leaves the root.
    static func resolve(_ target: String, from directory: String) -> String? {
        let joined = directory.isEmpty ? target : directory + "/" + target
        var parts: [Substring] = []
        for p in joined.split(separator: "/", omittingEmptySubsequences: true) {
            if p == "." { continue }
            if p == ".." {
                if parts.isEmpty { return nil }
                parts.removeLast()
            } else { parts.append(p) }
        }
        return parts.joined(separator: "/")
    }
}
