// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a localized string discovered from `.xcstrings` or `.strings` files.
///
/// Contains all information needed to generate type-safe Swift accessors:
/// - Simple strings become computed properties
/// - Strings with format specifiers become functions with typed parameters
struct DiscoveredString: Equatable {
    /// The localization key used for lookup at runtime.
    ///
    /// Examples:
    /// - `"welcome.title"`
    /// - `"%lld items remaining"`
    /// - `"greet.user"`
    let key: String

    /// The table name derived from the source filename.
    ///
    /// Used as the `table` parameter in `bundle.localizedString(forKey:value:table:)`.
    ///
    /// Examples:
    /// - `"Localizable"` from `Localizable.xcstrings`
    /// - `"Errors"` from `Errors.strings`
    let tableName: String

    /// The default value from the development/source language.
    ///
    /// Used as the fallback value in `bundle.localizedString` and for
    /// generating documentation comments.
    let defaultValue: String

    /// Developer comment describing the string's purpose.
    ///
    /// Extracted from xcstrings `comment` field. Used to generate
    /// documentation comments in the generated code.
    let comment: String?

    /// Format arguments extracted from the string, in order.
    ///
    /// Empty for simple strings without format specifiers.
    /// Populated for strings containing `%@`, `%lld`, etc.
    let arguments: [StringFormatArgument]

    /// Source file path relative to input, for error messages.
    let relativePath: String

    /// Whether this string requires a function (has format arguments)
    /// versus a computed property (simple string).
    var requiresFunction: Bool {
        !arguments.isEmpty
    }

    /// Creates a discovered string.
    ///
    /// - Parameters:
    ///   - key: The localization key
    ///   - tableName: Table name from filename
    ///   - defaultValue: Default value from source language
    ///   - comment: Optional developer comment
    ///   - arguments: Format arguments (empty for simple strings)
    ///   - relativePath: Source file path for errors
    init(
        key: String,
        tableName: String,
        defaultValue: String,
        comment: String? = nil,
        arguments: [StringFormatArgument] = [],
        relativePath: String
    ) {
        self.key = key
        self.tableName = tableName
        self.defaultValue = defaultValue
        self.comment = comment
        self.arguments = arguments
        self.relativePath = relativePath
    }
}
