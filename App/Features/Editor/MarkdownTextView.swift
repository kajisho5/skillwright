import SwiftUI
import UIKit
import EditorKit

/// The text editor: UITextView on TextKit 2 with syntax colouring, list continuation,
/// pair input and the accessory keys (design spec §4, §0-4).
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    var onFocusChange: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView(usingTextLayoutManager: true)
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.font = Highlighter.baseFont
        tv.adjustsFontForContentSizeCategory = true
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.spellCheckingType = .no
        tv.keyboardDismissMode = .interactive
        tv.alwaysBounceVertical = true
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
        tv.text = text
        tv.inputAccessoryView = context.coordinator.makeAccessory()
        Highlighter.apply(to: tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        if tv.text != text && tv.markedTextRange == nil {
            let sel = tv.selectedRange
            tv.text = text
            Highlighter.apply(to: tv)
            tv.selectedRange = NSRange(location: min(sel.location, (text as NSString).length), length: 0)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView
        weak var textView: UITextView?

        init(_ parent: MarkdownTextView) { self.parent = parent }

        // MARK: typing

        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            textView = tv
            // Never interfere while Japanese (or any) input is being converted.
            guard tv.markedTextRange == nil else { return true }
            if text == "\n", range.length == 0,
               let edit = ListContinuation.editForReturn(in: tv.text, at: range.location) {
                apply(edit, in: tv)
                return false
            }
            if (text as NSString).length == 1,
               let edit = PairInput.edit(typing: text, selection: range, in: tv.text) {
                apply(edit, in: tv)
                return false
            }
            return true
        }

        func textViewDidChange(_ tv: UITextView) {
            textView = tv
            if tv.markedTextRange == nil { Highlighter.apply(to: tv) }
            parent.text = tv.text
        }

        func textViewDidBeginEditing(_ tv: UITextView) { textView = tv; parent.onFocusChange(true) }
        func textViewDidEndEditing(_ tv: UITextView) { parent.onFocusChange(false) }

        /// Applies an edit through UITextInput so that Undo works (one step per edit).
        func apply(_ edit: TextEdit, in tv: UITextView) {
            guard let start = tv.position(from: tv.beginningOfDocument, offset: edit.range.location),
                  let end = tv.position(from: start, offset: edit.range.length),
                  let range = tv.textRange(from: start, to: end) else { return }
            tv.replace(range, withText: edit.replacement)
            tv.selectedRange = NSRange(location: edit.cursor, length: 0)
            textViewDidChange(tv)
        }

        // MARK: accessory keys (# ** - [ ] ` → undo)

        func makeAccessory() -> UIView {
            let bar = UIInputView(frame: CGRect(x: 0, y: 0, width: 320, height: 44), inputViewStyle: .keyboard)
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.translatesAutoresizingMaskIntoConstraints = false
            let keys: [(String, String, Selector)] = [
                ("#", String(localized: "Heading"), #selector(heading)),
                ("**", String(localized: "Bold"), #selector(bold)),
                ("-", String(localized: "List"), #selector(list)),
                ("[ ]", String(localized: "Checkbox"), #selector(checkbox)),
                ("`", String(localized: "Code"), #selector(code)),
                ("→", String(localized: "Indent"), #selector(indent)),
            ]
            for (title, label, action) in keys {
                let b = UIButton(type: .system)
                b.setTitle(title, for: .normal)
                b.titleLabel?.font = .monospacedSystemFont(ofSize: 17, weight: .medium)
                b.tintColor = .label
                b.accessibilityLabel = label
                b.addTarget(self, action: action, for: .touchUpInside)
                stack.addArrangedSubview(b)
            }
            let undo = UIButton(type: .system)
            undo.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
            undo.tintColor = .label
            undo.accessibilityLabel = String(localized: "Undo")
            undo.addTarget(self, action: #selector(undoAction), for: .touchUpInside)
            stack.addArrangedSubview(undo)
            bar.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
                stack.topAnchor.constraint(equalTo: bar.topAnchor),
                stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
            ])
            return bar
        }

        private func lineStartInsert(_ prefix: String) {
            guard let tv = textView else { return }
            let ns = tv.text as NSString
            let line = ns.lineRange(for: NSRange(location: tv.selectedRange.location, length: 0))
            apply(TextEdit(range: NSRange(location: line.location, length: 0), replacement: prefix,
                           cursor: tv.selectedRange.location + (prefix as NSString).length), in: tv)
        }

        @objc private func heading() { lineStartInsert("# ") }
        @objc private func list() { lineStartInsert("- ") }
        @objc private func checkbox() { lineStartInsert("- [ ] ") }

        @objc private func bold() { wrap("**") }
        @objc private func code() { wrap("`") }

        private func wrap(_ mark: String) {
            guard let tv = textView else { return }
            let sel = tv.selectedRange
            let inner = (tv.text as NSString).substring(with: sel)
            let rep = mark + inner + mark
            let cursor = sel.length > 0 ? sel.location + (rep as NSString).length : sel.location + (mark as NSString).length
            apply(TextEdit(range: sel, replacement: rep, cursor: cursor), in: tv)
        }

        @objc private func indent() {
            guard let tv = textView else { return }
            apply(Indent.indent(in: tv.text, at: tv.selectedRange.location), in: tv)
        }

        @objc private func undoAction() { textView?.undoManager?.undo() }
    }
}

/// Syntax colouring: markers and frontmatter keys in the secondary colour, headings bold,
/// code in monospace. Text is never changed, only attributes.
enum Highlighter {
    static var baseFont: UIFont { UIFont.preferredFont(forTextStyle: .body) }
    static var monoFont: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .monospacedSystemFont(ofSize: 16, weight: .regular))
    }

    private static let heading = try! NSRegularExpression(pattern: #"^(#{1,6})[ \t]+(.*)$"#, options: [.anchorsMatchLines])
    private static let listMarker = try! NSRegularExpression(pattern: #"^[ \t]*([-*+]|\d{1,9}[.)])[ \t]+(\[[ xX]\][ \t]+)?"#, options: [.anchorsMatchLines])
    private static let emphasis = try! NSRegularExpression(pattern: #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#)
    private static let inlineCode = try! NSRegularExpression(pattern: #"`[^`\n]+`"#)
    private static let link = try! NSRegularExpression(pattern: #"!?\[[^\]\n]*\]\([^)\n]*\)"#)

    static func apply(to tv: UITextView) {
        let storage = tv.textStorage
        let ns = storage.string as NSString
        let full = NSRange(location: 0, length: ns.length)
        let label = UIColor.label
        let secondary = Theme.uiDynamic(light: 0x6B6B6B, dark: 0x9A9A9A)
        storage.beginEditing()
        storage.setAttributes([.font: baseFont, .foregroundColor: label], range: full)

        // Frontmatter block
        var bodyStart = 0
        if ns.hasPrefix("---\n") || ns.isEqual(to: "---") {
            let close = ns.range(of: "\n---", options: [], range: NSRange(location: 3, length: max(0, ns.length - 3)))
            let end = close.location == NSNotFound ? ns.length : NSMaxRange(close)
            let fm = NSRange(location: 0, length: end)
            storage.addAttribute(.font, value: monoFont, range: fm)
            ns.enumerateSubstrings(in: fm, options: .byLines) { line, range, _, _ in
                guard let line else { return }
                if line == "---" { storage.addAttribute(.foregroundColor, value: secondary, range: range); return }
                if let colon = line.firstIndex(of: ":"), !line.hasPrefix(" ") {
                    let keyLen = (String(line[...colon]) as NSString).length
                    storage.addAttribute(.foregroundColor, value: secondary, range: NSRange(location: range.location, length: keyLen))
                }
            }
            bodyStart = end
        }
        let body = NSRange(location: bodyStart, length: ns.length - bodyStart)

        // Fenced code
        var codeRanges: [NSRange] = []
        var openAt: Int?
        ns.enumerateSubstrings(in: body, options: .byLines) { line, range, enclosing, _ in
            guard let line else { return }
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("```") || t.hasPrefix("~~~") {
                if let o = openAt { codeRanges.append(NSRange(location: o, length: NSMaxRange(range) - o)); openAt = nil }
                else { openAt = range.location }
            }
        }
        if let o = openAt { codeRanges.append(NSRange(location: o, length: ns.length - o)) }
        for r in codeRanges {
            storage.addAttribute(.font, value: monoFont, range: r)
            storage.addAttribute(.foregroundColor, value: secondary, range: r)
        }
        func inCode(_ r: NSRange) -> Bool { codeRanges.contains { NSIntersectionRange($0, r).length > 0 } }

        for m in heading.matches(in: storage.string, range: body) where !inCode(m.range) {
            storage.addAttribute(.foregroundColor, value: secondary, range: m.range(at: 1))
            storage.addAttribute(.font, value: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .bold)), range: m.range(at: 2))
        }
        for m in listMarker.matches(in: storage.string, range: body) where !inCode(m.range) {
            storage.addAttribute(.foregroundColor, value: secondary, range: m.range)
        }
        for m in emphasis.matches(in: storage.string, range: body) where !inCode(m.range) {
            storage.addAttribute(.font, value: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .bold)), range: m.range(at: 2))
            storage.addAttribute(.foregroundColor, value: secondary, range: m.range(at: 1))
            let closeLoc = NSMaxRange(m.range) - m.range(at: 1).length
            storage.addAttribute(.foregroundColor, value: secondary, range: NSRange(location: closeLoc, length: m.range(at: 1).length))
        }
        for m in inlineCode.matches(in: storage.string, range: body) where !inCode(m.range) {
            storage.addAttribute(.font, value: monoFont, range: m.range)
        }
        for m in link.matches(in: storage.string, range: body) where !inCode(m.range) {
            storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: m.range)
        }
        storage.endEditing()
        tv.typingAttributes = [.font: baseFont, .foregroundColor: label]
    }
}
