// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Root Structure

/// Root structure of an `.xcstrings` (String Catalog) file.
///
/// Example:
/// ```json
/// {
///   "version": "1.0",
///   "sourceLanguage": "en",
///   "strings": { ... }
/// }
/// ```
struct StringCatalog: Codable {
    /// Format version (currently "1.0")
    let version: String

    /// The source/development language code (e.g., "en", "de")
    let sourceLanguage: String

    /// Dictionary of string entries keyed by localization key
    let strings: [String: StringCatalogEntry]
}

// MARK: - String Entry

/// A single string entry in the catalog.
///
/// Example:
/// ```json
/// {
///   "comment": "Greeting shown on home screen",
///   "extractionState": "manual",
///   "shouldTranslate": true,
///   "localizations": { ... }
/// }
/// ```
struct StringCatalogEntry: Codable {
    /// Developer comment describing the string's purpose
    let comment: String?

    /// How the string was added: "manual", "automatic", "stale"
    let extractionState: String?

    /// Whether this string should be translated
    let shouldTranslate: Bool?

    /// Localizations keyed by language code
    let localizations: [String: StringCatalogLocalization]?
}

// MARK: - Localization

/// Localization for a specific language.
///
/// Can contain either a simple `stringUnit` or complex `variations`/`substitutions`.
struct StringCatalogLocalization: Codable {
    /// Simple string value
    let stringUnit: StringCatalogStringUnit?

    /// Variations by device or plural
    let variations: StringCatalogVariations?

    /// Substitutions for complex interpolated strings
    let substitutions: [String: StringCatalogSubstitution]?
}

// MARK: - String Unit

/// A simple string value with translation state.
///
/// Example:
/// ```json
/// {
///   "state": "translated",
///   "value": "Hello, World!"
/// }
/// ```
struct StringCatalogStringUnit: Codable {
    /// Translation state: "translated", "needs_review", "new", "stale"
    let state: String?

    /// The actual string value
    let value: String
}

// MARK: - Variations

/// Container for device and/or plural variations.
struct StringCatalogVariations: Codable {
    /// Device-specific variations (mac, iphone, ipad, etc.)
    let device: [String: StringCatalogVariationValue]?

    /// Plural variations (zero, one, two, few, many, other)
    let plural: [String: StringCatalogVariationValue]?
}

/// A variation value, which can contain a stringUnit or nested variations.
struct StringCatalogVariationValue: Codable {
    /// Simple string for this variation
    let stringUnit: StringCatalogStringUnit?

    /// Nested variations (e.g., device → plural)
    let variations: StringCatalogVariations?
}

// MARK: - Substitutions

/// A substitution placeholder for complex interpolated strings.
///
/// Used for strings like `"%#@count@ items"` where the placeholder
/// needs to handle pluralization or other variations.
///
/// Example:
/// ```json
/// {
///   "count": {
///     "argNum": 1,
///     "formatSpecifier": "lld",
///     "variations": {
///       "plural": {
///         "one": { "stringUnit": { "value": "%arg item" } },
///         "other": { "stringUnit": { "value": "%arg items" } }
///       }
///     }
///   }
/// }
/// ```
struct StringCatalogSubstitution: Codable {
    /// 1-based argument position
    let argNum: Int?

    /// Format specifier without % (e.g., "lld", "@", "d")
    let formatSpecifier: String?

    /// Variations for this substitution
    let variations: StringCatalogVariations?
}

// MARK: - Plural Category

/// CLDR plural categories.
///
/// Different languages use different subsets of these categories.
/// English uses only `one` and `other`.
/// Arabic uses all six categories.
enum StringPluralCategory: String, CaseIterable, Codable {
    case zero
    case one
    case two
    case few
    case many
    case other
}

// MARK: - Device Category

/// Device categories for device-specific variations.
enum StringDeviceCategory: String, CaseIterable, Codable {
    case mac
    case iphone
    case ipad
    case applewatch
    case appletv
    case ipod
    case other
}
