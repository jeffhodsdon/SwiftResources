// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Checks for duplicate sanitized identifiers in resource lists.
enum DuplicateChecker {
    struct DuplicateError: Error, CustomStringConvertible {
        let category: String
        let identifier: String
        let conflictingPaths: [String]

        var description: String {
            var message = "Error: Duplicate identifier '\(identifier)' for \(category):"
            for path in conflictingPaths {
                message += "\n  - \(path)"
            }
            return message
        }
    }

    /// Checks resources for duplicate sanitized identifiers.
    /// - Parameters:
    ///   - resources: Resources to check
    ///   - category: Category name for error messages (e.g., "images", "files")
    /// - Throws: DuplicateError if duplicates are found
    static func check(resources: [DiscoveredResource], category: String) throws {
        var identifierToPaths = [String: [String]]()

        for resource in resources {
            let identifier = NameSanitizer.sanitize(resource.name)
            identifierToPaths[identifier, default: []].append(resource.relativePath)
        }

        for (identifier, paths) in identifierToPaths {
            if paths.count > 1 {
                throw DuplicateError(
                    category: category,
                    identifier: identifier,
                    conflictingPaths: paths
                )
            }
        }
    }

    /// Checks fonts for duplicate sanitized identifiers.
    /// - Parameters:
    ///   - fonts: Fonts to check
    ///   - category: Category name for error messages (typically "fonts")
    /// - Throws: DuplicateError if duplicates are found
    static func check(fonts: [DiscoveredFont], category: String) throws {
        var identifierToPaths = [String: [String]]()

        for font in fonts {
            let identifier = NameSanitizer.sanitize(font.postScriptName)
            identifierToPaths[identifier, default: []].append(font.relativePath)
        }

        for (identifier, paths) in identifierToPaths {
            if paths.count > 1 {
                throw DuplicateError(
                    category: category,
                    identifier: identifier,
                    conflictingPaths: paths
                )
            }
        }
    }
}
