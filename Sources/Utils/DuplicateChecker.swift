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

    /// Checks file resources for duplicate sanitized identifiers.
    /// - Parameters:
    ///   - resources: File resources to check
    ///   - category: Category name for error messages (typically "files")
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

    /// Checks images for duplicate sanitized identifiers.
    /// - Parameters:
    ///   - images: Images to check
    ///   - category: Category name for error messages (typically "images")
    /// - Throws: DuplicateError if duplicates are found
    static func check(images: [DiscoveredImage], category: String) throws {
        var identifierToNames = [String: [String]]()

        for image in images {
            let identifier = NameSanitizer.sanitize(image.name)
            identifierToNames[identifier, default: []].append(image.name)
        }

        for (identifier, names) in identifierToNames {
            if names.count > 1 {
                throw DuplicateError(
                    category: category,
                    identifier: identifier,
                    conflictingPaths: names
                )
            }
        }
    }

    /// Checks colors for duplicate sanitized identifiers.
    /// - Parameters:
    ///   - colors: Colors to check
    ///   - category: Category name for error messages (typically "colors")
    /// - Throws: DuplicateError if duplicates are found
    static func check(colors: [DiscoveredColor], category: String) throws {
        var identifierToNames = [String: [String]]()

        for color in colors {
            let identifier = NameSanitizer.sanitize(color.name)
            identifierToNames[identifier, default: []].append(color.name)
        }

        for (identifier, names) in identifierToNames {
            if names.count > 1 {
                throw DuplicateError(
                    category: category,
                    identifier: identifier,
                    conflictingPaths: names
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
