import Foundation

/// The rules data (values and wording only — no code). Bundled, and replaceable by a
/// signed download later (design spec §8, rule delivery).
public struct RuleBook: Sendable, Decodable {
    public struct Rule: Sendable, Decodable {
        public let id: String
        public let severity: Severity
        public let kinds: [FileKind]
        public let doc: String
        public let title: [String: String]
        public let message: [String: String]
    }

    public struct Params: Sendable, Decodable {
        public let nameMaxLength: Int
        public let descriptionMaxLength: Int
        public let compatibilityMaxLength: Int
        public let bodyMaxLines: Int
        public let bodyMaxTokens: Int
        public let listingMaxChars: Int
        public let claudeMdMaxLines: Int
        public let importMaxDepth: Int
        public let reservedNames: [String]
        public let reservedPrefixes: [String]
        public let specFields: [String]
        public let claudeCodeBooleanFields: [String]
        public let booleanValues: [String]
        public let skillFolders: [String]
        public let dangerousPatterns: [String]
        public let secretPatterns: [String]
        public let toolHints: [String]
    }

    public let version: String
    public let params: Params
    public let rules: [Rule]
    /// Vague words per language. Not part of the JSON above; loaded from vague-*.json.
    public var vagueWords: [String: [String]] = [:]

    private enum CodingKeys: String, CodingKey { case version, params, rules }

    public func rule(_ id: String) -> Rule? { rules.first { $0.id == id } }

    /// Title of a rule in the given language (falls back to English).
    public func title(_ id: String, language: String) -> String {
        guard let r = rule(id) else { return id }
        return r.title[language] ?? r.title["en"] ?? id
    }

    /// Message of a rule with `{placeholders}` filled in.
    public func message(_ id: String, language: String, _ values: [String: String] = [:]) -> String {
        guard let r = rule(id) else { return id }
        var text = r.message[language] ?? r.message["en"] ?? id
        for (key, value) in values {
            text = text.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return text
    }

    /// The rules bundled with the app.
    public static func bundled() throws -> RuleBook {
        guard let url = Bundle.module.url(forResource: "rules-v1", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        var book = try load(from: Data(contentsOf: url))
        for lang in ["en", "ja"] {
            if let u = Bundle.module.url(forResource: "vague-\(lang)", withExtension: "json"),
               let words = try? JSONDecoder().decode([String].self, from: Data(contentsOf: u)) {
                book.vagueWords[lang] = words
            }
        }
        return book
    }

    public static func load(from data: Data) throws -> RuleBook {
        try JSONDecoder().decode(RuleBook.self, from: data)
    }
}
