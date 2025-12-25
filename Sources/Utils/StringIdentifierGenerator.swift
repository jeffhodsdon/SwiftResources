// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Generates Swift identifiers for localized strings.
///
/// Handles conversion of localization keys to valid Swift identifiers,
/// including complex keys with format specifiers.
///
/// Examples:
/// - `"welcome.title"` → `welcomeTitle`
/// - `"%lld items"` → `items`
/// - `"greet.user"` with `%@` → `greetUser` (function)
enum StringIdentifierGenerator {
    /// Generates a Swift identifier for a discovered string.
    ///
    /// For simple strings, returns a property-style identifier.
    /// For strings with arguments, returns a function-style identifier.
    ///
    /// - Parameter string: The discovered string
    /// - Returns: A valid Swift identifier
    static func generateIdentifier(for string: DiscoveredString) -> String {
        let baseName = generateBaseName(
            from: string.key,
            defaultValue: string.defaultValue
        )
        return NameSanitizer.sanitize(baseName)
    }

    /// Generates the base name from a key, stripping format specifiers.
    ///
    /// - Parameters:
    ///   - key: The localization key
    ///   - defaultValue: The default value (used for context)
    /// - Returns: A base name suitable for sanitization
    static func generateBaseName(from key: String, defaultValue: String) -> String {
        // If key starts with format specifier (e.g., "%lld items"), extract meaningful
        // part
        var workingKey = key

        // Remove leading format specifiers like "%lld ", "%@ ", etc.
        // Note: Character class uses \-+ instead of +- to avoid range interpretation
        let leadingFormatPattern =
            #/^%[\d$]*[\-+\s#0]*[\d.*]*[hlLzjt]*[@diouxXeEfFgGaAcspn%]\s*/#
        while let match = workingKey.firstMatch(of: leadingFormatPattern) {
            workingKey = String(workingKey[match.range.upperBound...])
        }

        // Remove trailing format specifiers
        let trailingFormatPattern =
            #/\s*%[\d$]*[\-+\s#0]*[\d.*]*[hlLzjt]*[@diouxXeEfFgGaAcspn%]$/#
        while let match = workingKey.firstMatch(of: trailingFormatPattern) {
            workingKey = String(workingKey[..<match.range.lowerBound])
        }

        // Remove inline format specifiers but keep surrounding text
        let inlineFormatPattern =
            #/%[\d$]*[\-+\s#0]*[\d.*]*[hlLzjt]*[@diouxXeEfFgGaAcspn%]/#
        workingKey = workingKey.replacing(inlineFormatPattern, with: " ")

        // Clean up multiple spaces
        workingKey = workingKey.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespaces)

        // If nothing meaningful remains, try to extract from defaultValue
        if workingKey.isEmpty || workingKey.allSatisfy({ !$0.isLetter }) {
            workingKey = generateBaseName(fromDefaultValue: defaultValue)
        }

        // If still empty, use a generic name
        if workingKey.isEmpty {
            return "string"
        }

        return workingKey
    }

    /// Generates parameter labels for a string's format arguments.
    ///
    /// - Parameter string: The discovered string
    /// - Returns: Array of parameter labels in order
    static func generateParameterLabels(for string: DiscoveredString) -> [String] {
        var usedLabels = Set<String>()
        var labels = [String]()

        for (index, arg) in string.arguments.enumerated() {
            let label: String =
                if let explicitLabel = arg.label, !explicitLabel.isEmpty {
                    // Use explicit label from substitution
                    explicitLabel
                } else {
                    // Infer label from context
                    FormatStringParser.inferLabel(
                        fromKey: string.key,
                        defaultValue: string.defaultValue,
                        specifier: arg.specifier,
                        position: index + 1
                    ) ?? "arg\(index + 1)"
                }

            // Ensure uniqueness
            var finalLabel = label
            var counter = 2
            while usedLabels.contains(finalLabel) {
                finalLabel = "\(label)\(counter)"
                counter += 1
            }

            usedLabels.insert(finalLabel)
            labels.append(finalLabel)
        }

        return labels
    }

    /// Generates a full function signature for a string with arguments.
    ///
    /// - Parameters:
    ///   - string: The discovered string
    ///   - accessLevel: Access level prefix (e.g., "public ")
    /// - Returns: Function signature string
    static func generateFunctionSignature(
        for string: DiscoveredString,
        accessLevel: String
    ) -> String {
        let identifier = generateIdentifier(for: string)
        let labels = generateParameterLabels(for: string)

        var params = [String]()
        for (index, arg) in string.arguments.enumerated() {
            let label = labels[index]
            let type = arg.specifier.swiftType
            params.append("_ \(label): \(type)")
        }

        let paramList = params.joined(separator: ", ")
        return "\(accessLevel)static func \(identifier)(\(paramList)) -> String"
    }

    /// Extracts a meaningful name from the default value.
    private static func generateBaseName(fromDefaultValue value: String) -> String {
        var working = value

        // Remove format specifiers
        let formatPattern = #/%[\d$]*[\-+\s#0]*[\d.*]*[hlLzjt]*[@diouxXeEfFgGaAcspn%]/#
        working = working.replacing(formatPattern, with: " ")

        // Clean up
        working = working.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespaces)

        // Take first few meaningful words (up to 3)
        let words = working.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && $0.first?.isLetter == true }
            .prefix(3)

        return words.joined(separator: " ")
    }
}
