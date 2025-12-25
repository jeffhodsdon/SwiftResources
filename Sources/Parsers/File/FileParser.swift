// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Discovers arbitrary files in directories.
enum FileParser {
    /// Recursively scans directories for all files.
    /// - Parameter directories: Paths to directories to scan
    /// - Returns: Discovered file resources, sorted by name
    static func parse(directories: [String]) throws -> [DiscoveredResource] {
        var resources = [DiscoveredResource]()
        let fileManager = FileManager.default

        for directory in directories {
            let directoryURL = URL(fileURLWithPath: directory).standardizedFileURL

            guard let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                // Skip files that resolve outside the root directory (symlink protection)
                guard isContainedWithin(file: fileURL, root: directoryURL) else {
                    continue
                }

                // Check it's a regular file (not a directory)
                guard let resourceValues = try? fileURL
                    .resourceValues(forKeys: [.isRegularFileKey]),
                    resourceValues.isRegularFile == true
                else {
                    continue
                }

                let standardizedFileURL = fileURL.standardizedFileURL
                let ext = standardizedFileURL.pathExtension.lowercased()
                let name = standardizedFileURL.deletingPathExtension().lastPathComponent
                let relativePath = standardizedFileURL.path.replacingOccurrences(
                    of: directoryURL.path + "/",
                    with: ""
                )

                // Validate name and extension are safe for code generation
                try StringValidator.validate(name, context: "filename '\(relativePath)'")
                try StringValidator.validate(
                    ext,
                    context: "file extension '\(relativePath)'"
                )

                resources.append(DiscoveredResource(
                    name: name,
                    extension: ext,
                    relativePath: relativePath
                ))
            }
        }

        return resources.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Parses individual file paths directly.
    /// - Parameter paths: File paths to parse
    /// - Returns: Discovered file resources, sorted by name
    static func parseFiles(_ paths: [String]) throws -> [DiscoveredResource] {
        var resources = [DiscoveredResource]()

        for path in paths {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            let ext = url.pathExtension.lowercased()
            let name = url.deletingPathExtension().lastPathComponent

            // Validate name and extension are safe for code generation
            try StringValidator.validate(
                name,
                context: "filename '\(url.lastPathComponent)'"
            )
            try StringValidator.validate(
                ext,
                context: "file extension '\(url.lastPathComponent)'"
            )

            resources.append(DiscoveredResource(
                name: name,
                extension: ext,
                relativePath: url.lastPathComponent
            ))
        }

        return resources.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Validates that a file path is contained within the root directory.
    /// Prevents symlink-based path traversal attacks.
    private static func isContainedWithin(file: URL, root: URL) -> Bool {
        let resolvedFile = file.resolvingSymlinksInPath().standardized.path
        let resolvedRoot = root.resolvingSymlinksInPath().standardized.path
        return resolvedFile.hasPrefix(resolvedRoot + "/") || resolvedFile == resolvedRoot
    }
}
