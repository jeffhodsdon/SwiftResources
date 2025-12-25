// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parses legacy `.strings` files into `DiscoveredString` objects.
///
/// Handles the traditional Apple strings file format:
/// ```
/// /* Comment */
/// "key" = "value";
/// ```
///
/// Supports files in `.lproj` directories (e.g., `en.lproj/Localizable.strings`).
enum StringsFileParser {
    /// Errors that can occur during parsing.
    enum ParseError: Error, CustomStringConvertible {
        case fileNotFound(String)
        case readError(String, Error)
        case parseError(String, String)
        case missingDevelopmentRegion(String)

        var description: String {
            switch self {
            case .fileNotFound(let path):
                "Strings file not found: \(path)"
            case .readError(let path, let error):
                "Failed to read strings file '\(path)': \(error.localizedDescription)"
            case .parseError(let path, let details):
                "Failed to parse strings file '\(path)': \(details)"
            case .missingDevelopmentRegion(let path):
                """
                Cannot determine development region for '\(path)'. \
                Use --development-region or place file in an .lproj directory.
                """
            }
        }
    }

    /// Parses a single `.strings` file.
    ///
    /// - Parameters:
    ///   - path: Path to the `.strings` file
    ///   - developmentRegion: Optional development region override.
    ///     If nil, attempts to infer from `.lproj` directory name.
    /// - Returns: Array of discovered strings
    /// - Throws: `ParseError` if parsing fails
    static func parse(file path: String,
                      developmentRegion: String? = nil) throws -> [DiscoveredString]
    {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw ParseError.fileNotFound(path)
        }

        // Determine if this is the development region file
        let region = try determineDevelopmentRegion(for: url, override: developmentRegion)

        // Check if this file is from the development region
        let fileRegion = inferRegionFromPath(url)
        guard fileRegion == nil || fileRegion == region else {
            // Skip non-development region files
            return []
        }

        // Derive table name from filename (without extension)
        let tableName = url.deletingPathExtension().lastPathComponent

        // Read and parse the file
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try UTF-16 (some .strings files use this)
            do {
                content = try String(contentsOf: url, encoding: .utf16)
            } catch {
                throw ParseError.readError(path, error)
            }
        }

        // Parse the strings file format
        let entries = try parseStringsFormat(content, path: path)

        var discoveredStrings = [DiscoveredString]()

        for (key, value, comment) in entries {
            // Validate the key and value (using string-specific validation)
            do {
                try StringValidator.validateString(key, context: "string key")
                try StringValidator.validateString(value, context: "string value")
            } catch {
                // Skip strings with invalid characters
                continue
            }

            let arguments = FormatStringParser.parse(value)

            let discovered = DiscoveredString(
                key: key,
                tableName: tableName,
                defaultValue: value,
                comment: comment,
                arguments: arguments,
                relativePath: path
            )
            discoveredStrings.append(discovered)
        }

        // Sort by key for deterministic output
        discoveredStrings.sort { $0.key < $1.key }

        return discoveredStrings
    }

    /// Parses multiple `.strings` files, grouping by table name.
    ///
    /// - Parameters:
    ///   - paths: Paths to `.strings` files
    ///   - developmentRegion: Development region to use
    /// - Returns: Dictionary of table name to discovered strings
    /// - Throws: `ParseError` if any file fails to parse
    static func parse(
        files paths: [String],
        developmentRegion: String?
    ) throws -> [String: [DiscoveredString]] {
        var results = [String: [DiscoveredString]]()

        for path in paths {
            let strings = try parse(file: path, developmentRegion: developmentRegion)
            if !strings.isEmpty {
                let tableName = strings.first?.tableName ?? "Localizable"
                results[tableName, default: []].append(contentsOf: strings)
            }
        }

        return results
    }

    // MARK: - Private Helpers

    /// Determines the development region for a strings file.
    private static func determineDevelopmentRegion(
        for url: URL,
        override: String?
    ) throws -> String {
        // Use override if provided
        if let override {
            return override
        }

        // Try to infer from .lproj directory
        if let region = inferRegionFromPath(url) {
            return region
        }

        // Cannot determine region
        throw ParseError.missingDevelopmentRegion(url.path)
    }

    /// Infers region from `.lproj` directory name.
    ///
    /// - Parameter url: File URL
    /// - Returns: Region code if file is in an `.lproj` directory
    private static func inferRegionFromPath(_ url: URL) -> String? {
        let parentDir = url.deletingLastPathComponent().lastPathComponent
        if parentDir.hasSuffix(".lproj") {
            return String(parentDir.dropLast(6)) // Remove ".lproj"
        }
        return nil
    }

    /// Parses the strings file format.
    ///
    /// Format:
    /// ```
    /// /* Optional comment */
    /// "key" = "value";
    /// ```
    ///
    /// - Parameters:
    ///   - content: File content
    ///   - path: File path for error messages
    /// - Returns: Array of (key, value, comment) tuples
    private static func parseStringsFormat(
        _ content: String,
        path: String
    ) throws -> [(key: String, value: String, comment: String?)] {
        var results = [(String, String, String?)]()
        var pendingComment: String?

        // Regex for key-value pairs: "key" = "value";
        // Handles escaped quotes within strings
        let kvPattern = #/"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;/#

        // Regex for comments: /* comment */ or // comment
        let blockCommentPattern = #/\/\*\s*(.*?)\s*\*\//#
        let lineCommentPattern = #/\/\/\s*(.*)$/#

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Check for block comment
            if let match = trimmed.firstMatch(of: blockCommentPattern) {
                pendingComment = String(match.1)
                continue
            }

            // Check for line comment
            if let match = trimmed.firstMatch(of: lineCommentPattern) {
                pendingComment = String(match.1)
                continue
            }

            // Check for key-value pair
            if let match = trimmed.firstMatch(of: kvPattern) {
                let key = unescapeString(String(match.1))
                let value = unescapeString(String(match.2))
                results.append((key, value, pendingComment))
                pendingComment = nil
            }
        }

        return results
    }

    /// Unescapes a string from .strings file format.
    ///
    /// Handles common escape sequences: `\\`, `\"`, `\n`, `\t`, `\r`
    private static func unescapeString(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "\\\"", with: "\"")
        result = result.replacingOccurrences(of: "\\\\", with: "\\")
        result = result.replacingOccurrences(of: "\\n", with: "\n")
        result = result.replacingOccurrences(of: "\\t", with: "\t")
        result = result.replacingOccurrences(of: "\\r", with: "\r")
        return result
    }
}
