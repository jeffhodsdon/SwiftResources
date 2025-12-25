// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parses `.xcstrings` (String Catalog) files into `DiscoveredString` objects.
///
/// String Catalogs are Apple's modern localization format (Xcode 15+) that
/// combines the functionality of `.strings` and `.stringsdict` files into
/// a single JSON-based format.
enum StringCatalogParser {
    /// Result of parsing a string catalog, including strings and metadata.
    struct ParseResult {
        /// Discovered strings from the catalog
        let strings: [DiscoveredString]

        /// The source/development language from the catalog
        let sourceLanguage: String

        /// The table name derived from the filename
        let tableName: String
    }

    /// Errors that can occur during parsing.
    enum ParseError: Error, CustomStringConvertible {
        case fileNotFound(String)
        case invalidJSON(String, Error)
        case missingSourceLanguage(String)
        case noStringsFound(String)

        var description: String {
            switch self {
            case .fileNotFound(let path):
                "String catalog not found: \(path)"
            case .invalidJSON(let path, let error):
                "Invalid JSON in string catalog '\(path)': \(error.localizedDescription)"
            case .missingSourceLanguage(let path):
                "String catalog missing sourceLanguage: \(path)"
            case .noStringsFound(let path):
                "No strings found in catalog: \(path)"
            }
        }
    }

    /// Parses a single `.xcstrings` file.
    ///
    /// - Parameter path: Path to the `.xcstrings` file
    /// - Returns: Parse result containing strings and metadata
    /// - Throws: `ParseError` if parsing fails
    static func parse(file path: String) throws -> ParseResult {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw ParseError.fileNotFound(path)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ParseError.invalidJSON(path, error)
        }

        let catalog: StringCatalog
        do {
            catalog = try JSONDecoder().decode(StringCatalog.self, from: data)
        } catch {
            throw ParseError.invalidJSON(path, error)
        }

        // Derive table name from filename (without extension)
        let tableName = url.deletingPathExtension().lastPathComponent

        // Extract strings from the catalog
        var discoveredStrings = [DiscoveredString]()

        for (key, entry) in catalog.strings {
            // Skip strings marked as not translatable (rare, but possible)
            if entry.shouldTranslate == false {
                continue
            }

            // Get the localization for the source language
            guard let localization = entry.localizations?[catalog.sourceLanguage] else {
                // String exists but no source language value - use key as default
                let discovered = DiscoveredString(
                    key: key,
                    tableName: tableName,
                    defaultValue: key,
                    comment: entry.comment,
                    arguments: FormatStringParser.parse(key),
                    relativePath: path
                )
                discoveredStrings.append(discovered)
                continue
            }

            // Extract default value and arguments
            let (defaultValue, arguments) = extractValueAndArguments(
                from: localization,
                key: key,
                tableName: tableName
            )

            // Validate the key and default value (using string-specific validation)
            do {
                try StringValidator.validateString(key, context: "string key")
                try StringValidator.validateString(defaultValue, context: "string value")
            } catch {
                // Skip strings with invalid characters
                continue
            }

            let discovered = DiscoveredString(
                key: key,
                tableName: tableName,
                defaultValue: defaultValue,
                comment: entry.comment,
                arguments: arguments,
                relativePath: path
            )
            discoveredStrings.append(discovered)
        }

        // Sort by key for deterministic output
        discoveredStrings.sort { $0.key < $1.key }

        return ParseResult(
            strings: discoveredStrings,
            sourceLanguage: catalog.sourceLanguage,
            tableName: tableName
        )
    }

    /// Parses multiple `.xcstrings` files.
    ///
    /// - Parameter paths: Paths to `.xcstrings` files
    /// - Returns: Dictionary of table name to discovered strings
    /// - Throws: `ParseError` if any file fails to parse
    static func parse(files paths: [String]) throws -> [String: [DiscoveredString]] {
        var results = [String: [DiscoveredString]]()

        for path in paths {
            let result = try parse(file: path)
            results[result.tableName] = result.strings
        }

        return results
    }

    // MARK: - Private Helpers

    /// Extracts the default value and format arguments from a localization.
    private static func extractValueAndArguments(
        from localization: StringCatalogLocalization,
        key: String,
        tableName: String
    ) -> (String, [StringFormatArgument]) {
        // Case 1: Simple string unit
        if let stringUnit = localization.stringUnit {
            let defaultValue = stringUnit.value
            let arguments = FormatStringParser.parse(defaultValue)
            return (defaultValue, arguments)
        }

        // Case 2: Has substitutions (complex interpolated string)
        if let substitutions = localization.substitutions, !substitutions.isEmpty {
            let arguments = extractArgumentsFromSubstitutions(substitutions)

            // For substitutions, the "value" is the key itself (contains %#@name@
            // placeholders)
            // We use the key as the default value since that's what gets passed to
            // NSLocalizedString
            return (key, arguments)
        }

        // Case 3: Has variations (plural/device) without substitutions
        if let variations = localization.variations {
            // Get the first available value from variations (prefer "other" for plurals)
            let defaultValue = extractDefaultFromVariations(variations) ?? key
            let arguments = FormatStringParser.parse(defaultValue)
            return (defaultValue, arguments)
        }

        // Fallback: use key as value
        return (key, FormatStringParser.parse(key))
    }

    /// Extracts format arguments from xcstrings substitutions.
    private static func extractArgumentsFromSubstitutions(
        _ substitutions: [String: StringCatalogSubstitution]
    ) -> [StringFormatArgument] {
        var arguments = [StringFormatArgument]()

        for (name, substitution) in substitutions {
            guard let formatSpecifier = substitution.formatSpecifier else {
                continue
            }

            let position = substitution.argNum ?? (arguments.count + 1)
            let specifier = StringFormatSpecifier.parse(formatSpecifier)

            // Use the substitution key as the parameter label
            let label = NameSanitizer.sanitize(name)

            arguments.append(StringFormatArgument(
                position: position,
                specifier: specifier,
                label: label
            ))
        }

        // Sort by position
        return arguments.sorted { $0.position < $1.position }
    }

    /// Extracts a default value from variations (prefers "other" plural form).
    private static func extractDefaultFromVariations(
        _ variations: StringCatalogVariations
    ) -> String? {
        // Try plural variations first (most common)
        if let plural = variations.plural {
            // Prefer "other" as it's the most general form
            if let other = plural["other"]?.stringUnit?.value {
                return other
            }
            // Fall back to "one" or any available
            if let one = plural["one"]?.stringUnit?.value {
                return one
            }
            // Use first available
            for (_, value) in plural {
                if let stringValue = value.stringUnit?.value {
                    return stringValue
                }
                // Check for nested variations (device -> plural)
                if let nested = value.variations {
                    if let nestedValue = extractDefaultFromVariations(nested) {
                        return nestedValue
                    }
                }
            }
        }

        // Try device variations
        if let device = variations.device {
            // Prefer "other" as fallback
            if let other = device["other"]?.stringUnit?.value {
                return other
            }
            // Use first available
            for (_, value) in device {
                if let stringValue = value.stringUnit?.value {
                    return stringValue
                }
                if let nested = value.variations {
                    if let nestedValue = extractDefaultFromVariations(nested) {
                        return nestedValue
                    }
                }
            }
        }

        return nil
    }
}
