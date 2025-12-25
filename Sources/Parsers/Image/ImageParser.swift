// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Discovers image files in directories.
enum ImageParser {
    static let supportedExtensions: Set<String> = [
        "png",
        "jpg",
        "jpeg",
        "pdf",
        "svg",
        "heic",
    ]

    /// Recursively scans directories for image files.
    /// - Parameter directories: Paths to directories to scan
    /// - Returns: Discovered images, sorted by name
    static func parse(directories: [String]) throws -> [DiscoveredImage] {
        var images = [DiscoveredImage]()
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

                let ext = fileURL.pathExtension.lowercased()
                guard supportedExtensions.contains(ext) else {
                    continue
                }

                let name = fileURL.standardizedFileURL
                    .deletingPathExtension()
                    .lastPathComponent

                // Validate image name is safe for code generation
                try StringValidator.validate(
                    name,
                    context: "image filename '\(fileURL.lastPathComponent)'"
                )

                images.append(DiscoveredImage(name: name))
            }
        }

        return images.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Parses individual image file paths directly.
    /// - Parameter paths: File paths to parse
    /// - Returns: Discovered images, sorted by name
    static func parseFiles(_ paths: [String]) throws -> [DiscoveredImage] {
        var images = [DiscoveredImage]()

        for path in paths {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            let ext = url.pathExtension.lowercased()

            guard supportedExtensions.contains(ext) else {
                continue
            }

            let name = url.deletingPathExtension().lastPathComponent

            // Validate image name is safe for code generation
            try StringValidator.validate(
                name,
                context: "image filename '\(url.lastPathComponent)'"
            )

            images.append(DiscoveredImage(name: name))
        }

        return images.sorted {
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
