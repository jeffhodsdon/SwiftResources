// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a format argument extracted from a localized string.
///
/// Used to generate typed function parameters for strings containing
/// format specifiers like `"Hello, %@!"` or `"%lld items remaining"`.
struct StringFormatArgument: Equatable, Sendable {
    /// The 1-based position of this argument in the format string.
    ///
    /// For sequential specifiers (`%@`, `%d`), this is the order of appearance.
    /// For positional specifiers (`%1$@`, `%2$d`), this is the explicit position.
    let position: Int

    /// The format specifier that determines the Swift type for this argument.
    let specifier: StringFormatSpecifier

    /// Optional parameter label for the generated function.
    ///
    /// When available (from xcstrings substitution keys), this provides a
    /// meaningful parameter name like `count` or `name`. Otherwise, a label
    /// will be inferred from context or position.
    ///
    /// Examples:
    /// - Substitution key `"count"` → `func items(count: Int)`
    /// - No label → `func greet(_ arg1: String)`
    let label: String?

    /// Creates a format argument.
    ///
    /// - Parameters:
    ///   - position: 1-based position in the format string
    ///   - specifier: The format specifier determining Swift type
    ///   - label: Optional parameter label from substitution key
    init(position: Int, specifier: StringFormatSpecifier, label: String? = nil) {
        self.position = position
        self.specifier = specifier
        self.label = label
    }
}
