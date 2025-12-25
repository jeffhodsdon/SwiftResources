// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Validates strings for safe inclusion in generated Swift code.
enum StringValidator {
    struct UnsafeStringError: Error, CustomStringConvertible {
        let value: String
        let reason: String
        let context: String

        var description: String {
            "Unsafe \(context): \(reason) in \"\(value.prefix(50))\(value.count > 50 ? "..." : "")\""
        }
    }

    /// Characters allowed in resource names.
    /// Explicitly permit only safe ASCII characters.
    private static let allowedCharacters: CharacterSet = .init(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_. /"
    )

    /// Characters allowed in localized string keys and values.
    /// Includes format specifier characters needed for printf-style strings.
    private static let allowedStringCharacters: CharacterSet = .init(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_. /%@$#!?,;:()[]{}*+<>=&|^~`'"
    )

    /// Validates a string contains only allowed characters.
    ///
    /// Permits: ASCII letters, digits, hyphen, underscore, dot, space, forward slash.
    /// Rejects: Everything else (quotes, backslashes, Unicode, control chars, etc.)
    ///
    /// - Parameters:
    ///   - string: The string to validate
    ///   - context: Description for error messages (e.g., "font name", "image name")
    /// - Throws: UnsafeStringError if validation fails
    static func validate(_ string: String, context: String) throws {
        for char in string {
            guard let scalar = char.unicodeScalars.first,
                  char.unicodeScalars.count == 1,
                  allowedCharacters.contains(scalar)
            else {
                throw UnsafeStringError(
                    value: string,
                    reason: "contains disallowed character '\(char)'",
                    context: context
                )
            }
        }
    }

    /// Validates a string is safe and returns it, for use in expressions.
    static func validated(_ string: String, context: String) throws -> String {
        try validate(string, context: context)
        return string
    }

    /// Validates a localized string key or value.
    ///
    /// More permissive than `validate()` - allows format specifier characters
    /// like `%`, `@`, `$` that are needed for printf-style localized strings.
    ///
    /// - Parameters:
    ///   - string: The string to validate
    ///   - context: Description for error messages
    /// - Throws: UnsafeStringError if validation fails
    static func validateString(_ string: String, context: String) throws {
        for char in string {
            guard let scalar = char.unicodeScalars.first,
                  char.unicodeScalars.count == 1,
                  allowedStringCharacters.contains(scalar)
            else {
                throw UnsafeStringError(
                    value: string,
                    reason: "contains disallowed character '\(char)'",
                    context: context
                )
            }
        }
    }
}
