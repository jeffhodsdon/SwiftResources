// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parses printf-style format strings to extract format specifiers.
///
/// Handles standard C format specifiers used in Apple's localization:
/// - Simple: `%@`, `%d`, `%f`
/// - With length modifiers: `%lld`, `%lu`, `%lf`
/// - Positional: `%1$@`, `%2$lld`
/// - Escaped percent: `%%`
///
/// Does NOT handle xcstrings substitution placeholders (`%#@name@`),
/// which should be processed separately from the substitutions dictionary.
enum FormatStringParser {
    // swiftlint:disable:next line_length
    /// Regex pattern for printf-style format specifiers.
    ///
    /// Pattern breakdown:
    /// - `%` - literal percent sign
    /// - `(\d+\$)?` - optional positional argument (e.g., `1$`)
    /// - `[-+ #0]*` - optional flags
    /// - `(\d+|\*)?` - optional width
    /// - `(\.\d+|\.\*)?` - optional precision
    /// - `([hlLzjt]*)` - optional length modifiers
    /// - `([diuoxXeEfFgGaAcspn@%])` - conversion specifier
    private static let formatPattern =
        #/%(\d+\$)?[-+ #0]*(?:\d+|\*)?(?:\.\d+|\.\*)?([hlLzjt]*)([diuoxXeEfFgGaAcspn@%])/#

    /// Extracts format arguments from a format string.
    ///
    /// - Parameter formatString: The localized string potentially containing format
    /// specifiers
    /// - Returns: Array of format arguments in order, empty if no specifiers found
    ///
    /// Examples:
    /// - `"Hello, %@!"` → `[StringFormatArgument(position: 1, specifier: .string)]`
    /// - `"Hello, %@! You have %lld items."` → two arguments
    /// - `"100%% complete"` → empty (escaped percent)
    /// - `"Simple text"` → empty
    static func parse(_ formatString: String) -> [StringFormatArgument] {
        var arguments = [StringFormatArgument]()
        var sequentialPosition = 0

        let matches = formatString.matches(of: formatPattern)

        for match in matches {
            let fullMatch = String(match.0)

            // Skip escaped percent
            if fullMatch == "%%" {
                continue
            }

            // Extract components from regex groups
            let positionalGroup = match.1 // e.g., "1$" or nil
            let lengthModifier = String(match.2) // e.g., "ll", "l", ""
            let conversionChar = String(match.3) // e.g., "d", "@", "f"

            // Determine position
            let position: Int
            if let positional = positionalGroup {
                // Positional argument: %1$@, %2$d
                let posStr = positional.dropLast() // Remove trailing "$"
                position = Int(posStr) ?? {
                    sequentialPosition += 1
                    return sequentialPosition
                }()
            } else {
                // Sequential argument
                sequentialPosition += 1
                position = sequentialPosition
            }

            // Parse the specifier (length modifier + conversion)
            let specifierStr = lengthModifier + conversionChar
            let specifier = StringFormatSpecifier.parse(specifierStr)

            // Skip percent escape (conversion char is %)
            if conversionChar == "%" {
                continue
            }

            arguments.append(StringFormatArgument(
                position: position,
                specifier: specifier,
                label: nil // Labels come from xcstrings substitutions, not format parsing
            ))
        }

        // Sort by position to handle out-of-order positional arguments
        return arguments.sorted { $0.position < $1.position }
    }

    /// Infers a parameter label from the string key or default value.
    ///
    /// Used when xcstrings doesn't provide explicit substitution labels.
    ///
    /// - Parameters:
    ///   - key: The localization key
    ///   - defaultValue: The default value string
    ///   - specifier: The format specifier
    ///   - position: The argument position
    /// - Returns: An inferred label or nil
    ///
    /// Examples:
    /// - Key `"items.count"`, specifier `.int` → `"count"`
    /// - Key `"user.greeting"`, specifier `.string` → `"name"` (common pattern)
    /// - Key `"%lld items"`, specifier `.int` → `"count"`
    static func inferLabel(
        fromKey key: String,
        defaultValue: String,
        specifier: StringFormatSpecifier,
        position: Int
    ) -> String? {
        // Try to extract meaningful label from key
        let keyParts = key.components(separatedBy: CharacterSet(charactersIn: ".-_"))

        // Common patterns in keys
        let commonLabels: [StringFormatSpecifier: [String]] = [
            .int: ["count", "number", "total", "amount", "quantity", "index", "id"],
            .string: ["name", "title", "message", "text", "value", "label", "user"],
            .double: ["amount", "price", "value", "rate", "percentage"],
        ]

        // Check if any key part matches common labels for this type
        if let labelsForType = commonLabels[specifier] {
            for part in keyParts {
                let lowercased = part.lowercased()
                if labelsForType.contains(lowercased) {
                    return lowercased
                }
            }
        }

        // Check default value for context clues
        let valueParts = defaultValue
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        // Look for words near the format specifier
        if let labelsForType = commonLabels[specifier] {
            for part in valueParts {
                let lowercased = part.lowercased()
                if labelsForType.contains(lowercased) {
                    return lowercased
                }
            }
        }

        // Fallback based on specifier type and position
        switch specifier {
        case .int,
             .uint:
            return position == 1 ? "count" : "value\(position)"
        case .string:
            return position == 1 ? "value" : "value\(position)"
        case .double:
            return position == 1 ? "amount" : "value\(position)"
        case .character:
            return "char"
        case .unknown:
            return "arg\(position)"
        }
    }
}
