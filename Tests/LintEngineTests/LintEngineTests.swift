import Foundation
import Testing
@testable import LintEngine

// All sample content is fictional ("tea-timer", "Teapot Labs").

private let linter: Linter = try! Linter()

private func run(_ path: String, _ text: String, files: [String: String] = [:], upload: Bool = false,
                 folder: String? = nil, lang: String = "en") -> LintReport {
    let all = files
    return linter.lint(LintInput(path: path, text: text, skillFolderName: folder, uploadToClaudeAI: upload, language: lang,
                                 fileExists: { all[$0] != nil }, readFile: { all[$0] }))
}

private func ids(_ r: LintReport) -> [String] { r.issues.map(\.ruleID) }

private let goodSkill = """
---
name: tea-timer
description: Guides brewing time for each kind of tea. Use when someone asks how long to steep tea.
---

# Tea Timer

## Steps
1. Ask which tea.
2. Read [the table](references/brewing.md).
"""

@Suite("SKILL.md")
struct SkillTests {
    @Test func goodSkillPasses() {
        let r = run("tea-timer/SKILL.md", goodSkill, files: ["tea-timer/references/brewing.md": "# Table\n"])
        #expect(r.errorCount == 0)
        #expect(r.warningCount == 0)
        #expect(r.passedCount == r.totalCount)
        #expect(r.totalCount > 5)
        #expect(!r.blocksPublish)
    }

    @Test func missingFrontmatter() {
        let r = run("tea-timer/SKILL.md", "# Tea Timer\n")
        #expect(ids(r).contains("SK-01"))
        #expect(!ids(r).contains("SK-02"))
        #expect(r.blocksPublish)
    }

    @Test func unclosedFrontmatter() {
        let r = run("tea-timer/SKILL.md", "---\nname: tea-timer\n# Tea\n")
        #expect(ids(r).contains("SK-01"))
    }

    @Test func brokenYAML() {
        let r = run("tea-timer/SKILL.md", "---\nname: [tea\n---\n")
        #expect(ids(r).contains("SK-01"))
    }

    @Test(arguments: ["Tea-Timer", "-tea", "tea-", "tea--timer", "tea_timer", "tea timer"])
    func badNames(_ name: String) {
        let r = run("\(name)/SKILL.md", "---\nname: \(name)\ndescription: Steeps tea.\n---\n")
        #expect(ids(r).contains("SK-03"))
    }

    @Test func nameTooLong() {
        let name = String(repeating: "a", count: 65)
        let r = run("\(name)/SKILL.md", "---\nname: \(name)\ndescription: Steeps tea.\n---\n")
        #expect(ids(r).contains("SK-02"))
    }

    @Test func nameMustMatchFolder() {
        let r = run("kettle/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\n---\n")
        #expect(ids(r).contains("SK-04"))
        let ok = run("SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\n---\n", folder: "tea-timer")
        #expect(!ids(ok).contains("SK-04"))
    }

    @Test func descriptionRequiredAndLimited() {
        #expect(ids(run("tea-timer/SKILL.md", "---\nname: tea-timer\n---\n")).contains("SK-05"))
        let long = String(repeating: "x", count: 1025)
        #expect(ids(run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: \(long)\n---\n")).contains("SK-05"))
        let max = String(repeating: "x", count: 1024)
        #expect(!ids(run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: \(max)\n---\n")).contains("SK-05"))
    }

    @Test func compatibilityLimit() {
        let long = String(repeating: "c", count: 501)
        let r = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\ncompatibility: \(long)\n---\n")
        #expect(ids(r).contains("SK-06"))
    }

    @Test func metadataMustBeText() {
        let bad = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\nmetadata:\n  version: 1.0\n---\n")
        #expect(ids(bad).contains("SK-07"))
        let good = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\nmetadata:\n  version: \"1.0\"\n  author: teapot-labs\n---\n")
        #expect(!ids(good).contains("SK-07"))
        let notMap = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\nmetadata: hello\n---\n")
        #expect(ids(notMap).contains("SK-07"))
    }

    @Test func bodyTooLong() {
        let body = (1...501).map { "Line \($0)" }.joined(separator: "\n")
        let r = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\n---\n" + body)
        #expect(ids(r).contains("SK-08"))
    }

    @Test func bodyTooManyTokens() {
        let body = String(repeating: "word ", count: 5000)   // ~25,000 chars → ~6,250 tokens
        let r = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\n---\n" + body)
        #expect(ids(r).contains("SK-09"))
    }

    @Test func missingReferenceAndBarePath() {
        let text = goodSkill + "\nRun scripts/steep.py when done.\n"
        let r = run("tea-timer/SKILL.md", text, files: [:])
        let sk10 = r.issues.filter { $0.ruleID == "SK-10" }
        #expect(sk10.count == 2)
        #expect(sk10.first?.line == 10)
    }

    @Test func linksInsideCodeAreIgnored() {
        let text = "---\nname: tea-timer\ndescription: Steeps tea.\n---\n```\n[x](missing.md)\n```\nUse `[y](gone.md)` like this.\n"
        #expect(!ids(run("tea-timer/SKILL.md", text)).contains("SK-10"))
    }

    @Test func externalLinksAreIgnored() {
        let text = "---\nname: tea-timer\ndescription: Steeps tea.\n---\n[site](https://example.com) [top](#steps) [mail](mailto:a@example.com)\n"
        #expect(!ids(run("tea-timer/SKILL.md", text)).contains("SK-10"))
    }

    @Test func nestedReferences() {
        let r = run("tea-timer/SKILL.md", goodSkill, files: [
            "tea-timer/references/brewing.md": "See [more](deeper.md)\n",
            "tea-timer/references/deeper.md": "x",
        ])
        #expect(ids(r).contains("SK-11"))
    }

    @Test func allowedToolsInfoAndMismatch() {
        let text = "---\nname: tea-timer\ndescription: Steeps tea.\nallowed-tools: Read\n---\nRun `git status` first.\n"
        let r = run("tea-timer/SKILL.md", text)
        #expect(ids(r).contains("SK-12"))
        #expect(ids(r).contains("SEC-03"))
        let ok = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\nallowed-tools: Bash(git:*) Read\n---\nRun `git status` first.\n")
        #expect(!ids(ok).contains("SEC-03"))
    }

    @Test func extraFieldsWarnOrFail() {
        let text = "---\nname: tea-timer\ndescription: Steeps tea.\nwhen_to_use: When brewing.\n---\n"
        let warn = run("tea-timer/SKILL.md", text)
        #expect(warn.issues.first { $0.ruleID == "CC-01" }?.severity == .warning)
        #expect(warn.issues.first { $0.ruleID == "CC-01" }?.line == 4)
        let fail = run("tea-timer/SKILL.md", text, upload: true)
        #expect(fail.issues.first { $0.ruleID == "CC-01" }?.severity == .error)
    }

    @Test func listingLength() {
        let d = String(repeating: "d", count: 1000), w = String(repeating: "w", count: 600)
        let r = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: \(d)\nwhen_to_use: \(w)\n---\n")
        #expect(ids(r).contains("CC-02"))
    }

    @Test func reservedName() {
        let r = run("synced/SKILL.md", "---\nname: synced\ndescription: Steeps tea.\n---\n")
        #expect(ids(r).contains("CC-03"))
    }

    @Test func booleanFields() {
        let bad = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\ndisable-model-invocation: maybe\n---\n")
        #expect(ids(bad).contains("CC-04"))
        let ok = run("tea-timer/SKILL.md", "---\nname: tea-timer\ndescription: Steeps tea.\nuser-invocable: No\n---\n")
        #expect(!ids(ok).contains("CC-04"))
    }

    @Test func japaneseMessages() {
        let r = run("kettle/SKILL.md", "---\nname: tea-timer\ndescription: お茶の時間\n---\n", lang: "ja")
        #expect(r.issues.first { $0.ruleID == "SK-04" }?.message.contains("フォルダ名「kettle」") == true)
    }
}

@Suite("CLAUDE.md")
struct ClaudeMDTests {
    @Test func tooLong() {
        let text = (1...201).map { "- rule \($0)" }.joined(separator: "\n")
        #expect(ids(run("CLAUDE.md", text)).contains("CC-05"))
    }

    @Test func missingImport() {
        let r = run("CLAUDE.md", "See @docs/style.md for style.\nAlso @AGENTS.md\n", files: ["AGENTS.md": "x"])
        let cc06 = r.issues.filter { $0.ruleID == "CC-06" }
        #expect(cc06.count == 1)
        #expect(cc06.first?.line == 1)
        #expect(!ids(r).contains("CC-08"))
    }

    @Test func importsInCodeAndAnnotationsIgnored() {
        let text = "Mark types with `@docs/x.md` or @MainActor.\n```\n@missing.md\n```\nmail me at a@example.com\n"
        #expect(!ids(run("CLAUDE.md", text)).contains("CC-06"))
    }

    @Test func quotedImport() {
        #expect(ids(run("CLAUDE.md", "@\"my notes.md\"\n")).contains("CC-07"))
    }

    @Test func importTooDeep() {
        let files = ["a.md": "@b.md", "b.md": "@c.md", "c.md": "@d.md", "d.md": "@e.md", "e.md": "end"]
        #expect(ids(run("CLAUDE.md", "@a.md\n", files: files)).contains("CC-06"))
        let shallow = ["a.md": "@b.md", "b.md": "@c.md", "c.md": "@d.md", "d.md": "end"]
        #expect(!ids(run("CLAUDE.md", "@a.md\n", files: shallow)).contains("CC-06"))
    }

    @Test func importCycleDoesNotHang() {
        let files = ["a.md": "@b.md", "b.md": "@a.md"]
        _ = run("CLAUDE.md", "@a.md\n", files: files)
    }

    @Test func agentsBridge() {
        #expect(ids(run("CLAUDE.md", "# Rules\n", files: ["AGENTS.md": "x"])).contains("CC-08"))
        #expect(!ids(run("CLAUDE.md", "# Rules\n")).contains("CC-08"))
    }
}

@Suite("Other files")
struct OtherFileTests {
    @Test func agentsInfoAndLinks() {
        let r = run("AGENTS.md", "# Setup\nSee [docs](docs/setup.md)\n")
        #expect(ids(r).contains("AG-01"))
        #expect(ids(r).contains("AG-02"))
        #expect(ids(run("AGENTS.override.md", "# x\n")).contains("AG-03"))
    }

    @Test func rulePaths() {
        #expect(ids(run(".claude/rules/api.md", "---\npaths:\n  a: b\n---\n")).contains("CC-09"))
        #expect(!ids(run(".claude/rules/api.md", "---\npaths:\n  - \"src/**\"\n---\n")).contains("CC-09"))
        #expect(!ids(run(".claude/rules/api.md", "# no frontmatter is fine\n")).contains("SK-01"))
    }

    @Test func plainMarkdownLinksAndHeadings() {
        let r = run("docs/readme.md", "# Title\n### Skipped\n![pic](../assets/pic.png)\n", files: [:])
        #expect(ids(r).contains("MD-02"))
        #expect(ids(r).contains("MD-01"))
        let ok = run("docs/readme.md", "![pic](../assets/pic.png)\n", files: ["assets/pic.png": ""])
        #expect(!ids(ok).contains("MD-01"))
    }

    @Test func notLinted() {
        #expect(FileKind.detect(path: "image.png") == nil)
        #expect(FileKind.detect(path: "tea-timer/scripts/steep.py") == .script)
        #expect(FileKind.detect(path: "CLAUDE.local.md") == .claudeMD)
    }
}

@Suite("Writing and safety")
struct SafetyTests {
    @Test func vagueWords() {
        let r = run("notes.md", "Handle errors appropriately.\n必要に応じて直す。\nUse `as needed` in code is fine.\n")
        let lines = r.issues.filter { $0.ruleID == "WR-01" }.compactMap(\.line)
        #expect(lines == [1, 2])
        #expect(!ids(run("notes.md", "inappropriately named\n")).contains("WR-01"))
    }

    @Test(arguments: ["rm -rf build", "curl https://example.com/install | sh", "sudo apt install x", "chmod 777 file"])
    func dangerousCommands(_ cmd: String) {
        #expect(ids(run("notes.md", "```\n\(cmd)\n```\n")).contains("SEC-01"))
    }

    @Test func secretsBlockPublishing() {
        // Fictional, made-up token shape.
        let fake = "ghp_" + String(repeating: "A1b2", count: 9)
        let r = run("notes.md", "token = \(fake)\n")
        #expect(ids(r).contains("SEC-02"))
        #expect(r.blocksPublish)
    }

    @Test func scriptsAreScanned() {
        let r = run("tea-timer/scripts/clean.sh", "#!/bin/sh\nrm -rf /tmp/tea\n")
        #expect(ids(r) == ["SEC-01"])
    }
}

@Suite("Suppression markers")
struct SuppressionTests {
    @Test func fileWide() {
        let r = run("notes.md", "<!-- skillwright-disable WR-01 -->\nDo it appropriately.\n")
        #expect(!ids(r).contains("WR-01"))
        #expect(r.suppressions.count == 1)
    }

    @Test func nextLineOnly() {
        let text = "```\n<!-- skillwright-disable-next-line SEC-01 -->\nrm -rf build\nrm -rf dist\n```\n"
        let r = run("notes.md", text)
        #expect(r.issues.filter { $0.ruleID == "SEC-01" }.compactMap(\.line) == [4])
    }

    @Test func errorsCannotBeSuppressed() {
        let fake = "AKIA" + "ABCDEFGHIJKLMNOP"
        let r = run("notes.md", "<!-- skillwright-disable SEC-02 -->\nkey \(fake)\n")
        #expect(ids(r).contains("SEC-02"))
        #expect(ids(r).contains("SW-01"))
    }

    @Test func unknownRule() {
        #expect(ids(run("notes.md", "<!-- skillwright-disable ZZ-99 -->\n")).contains("SW-01"))
    }

    @Test func suppressedRuleLeavesTheScore() {
        let text = goodSkill.replacingOccurrences(of: "# Tea Timer", with: "<!-- skillwright-disable SK-10 -->\n# Tea Timer")
        let r = run("tea-timer/SKILL.md", text)
        #expect(!r.countedRules.contains("SK-10"))
        #expect(r.passedCount == r.totalCount)
    }
}

@Suite("Estimates")
struct EstimateTests {
    @Test func tokens() {
        #expect(Linter.estimateTokens("abcd") == 1)
        #expect(Linter.estimateTokens("お茶") == 2)
    }

    @Test func sections() {
        let w = Linter.sectionWeights("# A\naaaa aaaa\n## B\nbb\n")
        #expect(w.map(\.title) == ["A", "B"])
        #expect(w[0].line == 1 && w[1].line == 3)
    }

    @Test func rulesVersionAndBilingualTexts() throws {
        let book = try RuleBook.bundled()
        #expect(book.version == "2026.10.30")
        for rule in book.rules {
            #expect(rule.title["en"] != nil && rule.title["ja"] != nil, "missing title: \(rule.id)")
            #expect(rule.message["en"] != nil && rule.message["ja"] != nil, "missing message: \(rule.id)")
            #expect(URL(string: rule.doc) != nil)
        }
        #expect(book.vagueWords["ja"]?.isEmpty == false)
        #expect(book.vagueWords["en"]?.isEmpty == false)
    }
}
