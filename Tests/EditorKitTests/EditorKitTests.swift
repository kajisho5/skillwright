import Foundation
import Testing
@testable import EditorKit

private func returnAtEnd(_ text: String) -> String? {
    ListContinuation.editForReturn(in: text, at: (text as NSString).length)?.apply(to: text)
}

@Suite("List continuation")
struct ListContinuationTests {
    @Test func bullets() {
        #expect(returnAtEnd("- Ask which tea") == "- Ask which tea\n- ")
        #expect(returnAtEnd("  * nested") == "  * nested\n  * ")
    }

    @Test func numbersCount() {
        #expect(returnAtEnd("1. Boil water") == "1. Boil water\n2. ")
        #expect(returnAtEnd("9) Pour") == "9) Pour\n10) ")
    }

    @Test func checkboxesStartEmpty() {
        #expect(returnAtEnd("- [x] Warm the pot") == "- [x] Warm the pot\n- [ ] ")
    }

    @Test func emptyItemLeavesList() {
        #expect(returnAtEnd("- Ask\n- ") == "- Ask\n")
        #expect(returnAtEnd("- [ ] ") == "")
    }

    @Test func quotes() {
        #expect(returnAtEnd("> Steep gently") == "> Steep gently\n> ")
    }

    @Test func plainTextAndMidLine() {
        #expect(returnAtEnd("Just text") == nil)
        #expect(ListContinuation.editForReturn(in: "- Ask which tea", at: 3) == nil)
    }

    @Test func japanese() {
        #expect(returnAtEnd("- お湯を沸かす") == "- お湯を沸かす\n- ")
    }
}

@Suite("Pairs and wrapping")
struct PairTests {
    @Test func wrapSelection() {
        let text = "make it bold"
        let e = PairInput.edit(typing: "*", selection: NSRange(location: 8, length: 4), in: text)
        #expect(e?.apply(to: text) == "make it *bold*")
    }

    @Test func autoCloseAndStepOver() {
        let e = PairInput.edit(typing: "(", selection: NSRange(location: 0, length: 0), in: "")
        #expect(e?.apply(to: "") == "()")
        #expect(e?.cursor == 1)
        let step = PairInput.edit(typing: ")", selection: NSRange(location: 1, length: 0), in: "()")
        #expect(step?.apply(to: "()") == "()")
        #expect(step?.cursor == 2)
    }

    @Test func noAutoCloseBeforeWord() {
        #expect(PairInput.edit(typing: "(", selection: NSRange(location: 0, length: 0), in: "tea") == nil)
    }
}

@Suite("Indent and checkbox")
struct IndentTests {
    @Test func indentOutdent() {
        let t = "- tea"
        #expect(Indent.indent(in: t, at: 5).apply(to: t) == "  - tea")
        #expect(Indent.outdent(in: "  - tea", at: 7)?.apply(to: "  - tea") == "- tea")
        #expect(Indent.outdent(in: "- tea", at: 5) == nil)
    }

    @Test func toggleCheckbox() {
        let t = "# List\n- [ ] Warm the pot\n- [x] Boil"
        #expect(Checkbox.toggle(in: t, line: 2)?.apply(to: t) == "# List\n- [x] Warm the pot\n- [x] Boil")
        #expect(Checkbox.toggle(in: t, line: 3)?.apply(to: t) == "# List\n- [ ] Warm the pot\n- [ ] Boil")
        #expect(Checkbox.toggle(in: t, line: 1) == nil)
    }
}
