// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Converts resource filenames to valid Swift identifiers in lowerCamelCase.
enum NameSanitizer {
    /// Swift reserved keywords that require backtick escaping.
    static let reservedKeywords: Set<String> = [
        // Declarations
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var",
        // Statements
        "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
        "switch", "where", "while",
        // Expressions and types
        "Any", "as", "catch", "false", "is", "nil", "self", "Self", "super",
        "throw", "throws", "true", "try",
        // Patterns
        "_",
        // Context-sensitive (but still best to escape)
        "associativity", "convenience", "didSet", "dynamic", "final", "get",
        "indirect", "infix", "lazy", "left", "mutating", "none", "nonmutating",
        "optional", "override", "postfix", "prefix", "Protocol", "required",
        "right", "set", "some", "any", "Type", "unowned", "weak", "willSet",
    ]

    /// Converts a filename (without extension) to a valid Swift identifier.
    ///
    /// Rules:
    /// 1. Split on `-`, `_`, `.`
    /// 2. lowerCamelCase: lowercase first segment, capitalize subsequent segments
    /// 3. Prefix with `_` if result starts with a digit
    /// 4. Remove any characters that aren't valid in Swift identifiers
    ///
    /// Examples:
    /// - `hero-background` → `heroBackground`
    /// - `Inter-Bold` → `interBold`
    /// - `icon_home` → `iconHome`
    /// - `icon.home.settings` → `iconHomeSettings`
    /// - `2x_logo` → `_2xLogo`
    static func sanitize(_ name: String) -> String {
        guard !name.isEmpty else {
            return "_"
        }

        // Split on common separators
        let segments = name
            .components(separatedBy: CharacterSet(charactersIn: "-_."))
            .filter { !$0.isEmpty }

        guard !segments.isEmpty else {
            return "_"
        }

        // Build lowerCamelCase
        var result = segments.enumerated()
            .map { index, segment in
                // Clean segment: keep only alphanumeric and underscore
                let cleaned = segment.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                guard !cleaned.isEmpty else {
                    return ""
                }

                if index == 0 {
                    // First segment: lowercase
                    return cleaned.lowercased()
                } else {
                    // Subsequent segments: capitalize first letter
                    return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
                        .lowercased()
                }
            }
            .joined()

        guard !result.isEmpty else {
            return "_"
        }

        // Prefix with underscore if starts with digit
        if let first = result.first, first.isNumber {
            result = "_" + result
        }

        // Escape reserved keywords with backticks
        if reservedKeywords.contains(result) {
            return "`\(result)`"
        }

        return result
    }
}
