import Foundation

/// One change to the text, in UTF-16 offsets (what UITextView uses).
public struct TextEdit: Equatable, Sendable {
    public var range: NSRange
    public var replacement: String
    /// Where the cursor goes afterwards (UTF-16 offset, selection length 0).
    public var cursor: Int

    public init(range: NSRange, replacement: String, cursor: Int) {
        self.range = range
        self.replacement = replacement
        self.cursor = cursor
    }

    /// Applies the edit to a string (used by tests and by the share extension).
    public func apply(to text: String) -> String {
        (text as NSString).replacingCharacters(in: range, with: replacement)
    }
}

/// Helpers for the line around an offset.
enum Lines {
    /// Range of the line that contains `location` (without the trailing newline).
    static func lineRange(in ns: NSString, at location: Int) -> NSRange {
        var start = 0, end = 0, contentsEnd = 0
        ns.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: NSRange(location: min(location, ns.length), length: 0))
        return NSRange(location: start, length: contentsEnd - start)
    }
}

/// "Return" inside a list keeps the list going (design spec §0-4).
public enum ListContinuation {
    private static let listRegex = try! NSRegularExpression(
        pattern: #"^([ \t]*)([-*+]|(\d{1,9})([.)]))([ \t]+)(\[[ xX]\][ \t]+)?(.*)$"#)
    private static let quoteRegex = try! NSRegularExpression(pattern: #"^([ \t]*>[ \t]?)(.*)$"#)

    /// The edit to make when the user presses Return with the cursor at `location`
    /// (no selection). nil means "insert a plain newline".
    public static func editForReturn(in text: String, at location: Int) -> TextEdit? {
        let ns = text as NSString
        let lineRange = Lines.lineRange(in: ns, at: location)
        // Only when the cursor is at the end of the line content.
        guard location == NSMaxRange(lineRange) else { return nil }
        let line = ns.substring(with: lineRange)
        let lns = line as NSString
        let full = NSRange(location: 0, length: lns.length)

        if let m = listRegex.firstMatch(in: line, range: full) {
            let indent = lns.substring(with: m.range(at: 1))
            let gap = lns.substring(with: m.range(at: 5))
            let hasBox = m.range(at: 6).location != NSNotFound
            let content = lns.substring(with: m.range(at: 7))
            if content.trimmingCharacters(in: .whitespaces).isEmpty {
                // Empty item: leave the list. Keep the indent only.
                return TextEdit(range: lineRange, replacement: "", cursor: lineRange.location)
            }
            var marker: String
            if m.range(at: 3).location != NSNotFound, let n = Int(lns.substring(with: m.range(at: 3))) {
                marker = "\(n + 1)" + lns.substring(with: m.range(at: 4))
            } else {
                marker = lns.substring(with: m.range(at: 2))
            }
            marker = indent + marker + gap + (hasBox ? "[ ] " : "")
            let insert = "\n" + marker
            return TextEdit(range: NSRange(location: location, length: 0), replacement: insert,
                            cursor: location + (insert as NSString).length)
        }
        if let m = quoteRegex.firstMatch(in: line, range: full) {
            let prefix = lns.substring(with: m.range(at: 1))
            let content = lns.substring(with: m.range(at: 2))
            if content.trimmingCharacters(in: .whitespaces).isEmpty {
                return TextEdit(range: lineRange, replacement: "", cursor: lineRange.location)
            }
            let p = prefix.hasSuffix(" ") ? prefix : prefix + " "
            let insert = "\n" + p
            return TextEdit(range: NSRange(location: location, length: 0), replacement: insert,
                            cursor: location + (insert as NSString).length)
        }
        return nil
    }
}

/// Typing a pair character wraps the selection or closes the pair (design spec §0-4).
public enum PairInput {
    public static let wrapPairs: [String: String] = ["*": "*", "_": "_", "`": "`", "~": "~", "\"": "\"", "(": ")", "[": "]", "{": "}"]
    public static let autoClose: [String: String] = ["(": ")", "[": "]", "{": "}", "`": "`"]

    /// nil means "let the text view insert the character normally".
    public static func edit(typing char: String, selection: NSRange, in text: String) -> TextEdit? {
        let ns = text as NSString
        if selection.length > 0, let close = wrapPairs[char] {
            let inner = ns.substring(with: selection)
            let replacement = char + inner + close
            return TextEdit(range: selection, replacement: replacement,
                            cursor: selection.location + (replacement as NSString).length)
        }
        guard selection.length == 0 else { return nil }
        // Typing a closing character right before the same one: just step over it.
        if autoClose.values.contains(char), selection.location < ns.length,
           ns.substring(with: NSRange(location: selection.location, length: 1)) == char {
            return TextEdit(range: NSRange(location: selection.location, length: 0), replacement: "",
                            cursor: selection.location + 1)
        }
        if let close = autoClose[char] {
            // Do not auto-close in the middle of a word.
            if selection.location < ns.length {
                let next = ns.substring(with: NSRange(location: selection.location, length: 1))
                if next.rangeOfCharacter(from: .alphanumerics) != nil { return nil }
            }
            return TextEdit(range: selection, replacement: char + close, cursor: selection.location + (char as NSString).length)
        }
        return nil
    }
}

/// Indent / outdent the list line at the cursor (swipe, ⌘] ⌘[, the → key).
public enum Indent {
    public static let unit = "  "

    public static func indent(in text: String, at location: Int) -> TextEdit {
        let ns = text as NSString
        let line = Lines.lineRange(in: ns, at: location)
        return TextEdit(range: NSRange(location: line.location, length: 0), replacement: unit,
                        cursor: location + (unit as NSString).length)
    }

    public static func outdent(in text: String, at location: Int) -> TextEdit? {
        let ns = text as NSString
        let line = Lines.lineRange(in: ns, at: location)
        let s = ns.substring(with: line)
        let lead = s.prefix(while: { $0 == " " }).count
        let remove = min(lead, (unit as NSString).length)
        if s.hasPrefix("\t") {
            return TextEdit(range: NSRange(location: line.location, length: 1), replacement: "", cursor: max(line.location, location - 1))
        }
        guard remove > 0 else { return nil }
        return TextEdit(range: NSRange(location: line.location, length: remove), replacement: "",
                        cursor: max(line.location, location - remove))
    }
}

/// Toggles "- [ ]" and "- [x]" on a line (preview checkbox, design spec §0-4).
public enum Checkbox {
    private static let regex = try! NSRegularExpression(pattern: #"^([ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+)\[([ xX])\]"#)

    public static func toggle(in text: String, line number: Int) -> TextEdit? {
        let ns = text as NSString
        var offset = 0
        var current = 1
        while current < number {
            let r = ns.range(of: "\n", options: [], range: NSRange(location: offset, length: ns.length - offset))
            if r.location == NSNotFound { return nil }
            offset = NSMaxRange(r)
            current += 1
        }
        let lineRange = Lines.lineRange(in: ns, at: offset)
        let line = ns.substring(with: lineRange)
        guard let m = regex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) else { return nil }
        let mark = (line as NSString).substring(with: m.range(at: 2))
        let boxAt = lineRange.location + m.range(at: 2).location
        return TextEdit(range: NSRange(location: boxAt, length: 1), replacement: mark == " " ? "x" : " ", cursor: boxAt + 1)
    }
}
