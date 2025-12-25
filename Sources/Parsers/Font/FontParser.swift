// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#if canImport(CoreText)
import CoreText
#endif
import Foundation

/// Discovers font files (.ttf, .otf) and extracts PostScript names via Core Text.
enum FontParser {
    static let supportedExtensions: Set<String> = ["ttf", "otf"]

    /// Recursively scans directories for font files and extracts PostScript names.
    /// - Parameter directories: Paths to directories to scan
    /// - Returns: Discovered fonts with PostScript names, sorted by name
    static func parse(directories: [String]) throws -> [DiscoveredFont] {
        var fonts = [DiscoveredFont]()
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

                let standardizedFileURL = fileURL.standardizedFileURL
                let fileName = standardizedFileURL.deletingPathExtension()
                    .lastPathComponent
                let relativePath = standardizedFileURL.path.replacingOccurrences(
                    of: directoryURL.path + "/",
                    with: ""
                )

                // Extract PostScript name(s) using Core Text
                let postScriptNames = extractPostScriptNames(from: fileURL)

                // Validate filename is safe for code generation
                try StringValidator.validate(
                    fileName,
                    context: "font filename '\(relativePath)'"
                )

                if postScriptNames.isEmpty {
                    // Fallback to filename if Core Text fails
                    fonts.append(DiscoveredFont(
                        postScriptName: fileName,
                        fileName: fileName,
                        fileExtension: ext,
                        relativePath: relativePath
                    ))
                } else {
                    // Create entry for each font in file (handles .ttc)
                    for postScriptName in postScriptNames {
                        // Validate PostScript name from font metadata
                        try StringValidator.validate(
                            postScriptName,
                            context: "font PostScript name in '\(relativePath)'"
                        )
                        fonts.append(DiscoveredFont(
                            postScriptName: postScriptName,
                            fileName: fileName,
                            fileExtension: ext,
                            relativePath: relativePath
                        ))
                    }
                }
            }
        }

        return fonts
            .sorted {
                $0.postScriptName
                    .localizedStandardCompare($1.postScriptName) == .orderedAscending
            }
    }

    /// Parses individual font file paths directly.
    /// - Parameter paths: File paths to parse
    /// - Returns: Discovered fonts with PostScript names, sorted by name
    static func parseFiles(_ paths: [String]) throws -> [DiscoveredFont] {
        var fonts = [DiscoveredFont]()

        for path in paths {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            let ext = url.pathExtension.lowercased()

            guard supportedExtensions.contains(ext) else {
                continue
            }

            let fileName = url.deletingPathExtension().lastPathComponent
            let postScriptNames = extractPostScriptNames(from: url)

            // Validate filename is safe for code generation
            try StringValidator.validate(
                fileName,
                context: "font filename '\(url.lastPathComponent)'"
            )

            if postScriptNames.isEmpty {
                fonts.append(DiscoveredFont(
                    postScriptName: fileName,
                    fileName: fileName,
                    fileExtension: ext,
                    relativePath: url.lastPathComponent
                ))
            } else {
                for postScriptName in postScriptNames {
                    // Validate PostScript name from font metadata
                    try StringValidator.validate(
                        postScriptName,
                        context: "font PostScript name in '\(url.lastPathComponent)'"
                    )
                    fonts.append(DiscoveredFont(
                        postScriptName: postScriptName,
                        fileName: fileName,
                        fileExtension: ext,
                        relativePath: url.lastPathComponent
                    ))
                }
            }
        }

        return fonts.sorted {
            $0.postScriptName
                .localizedStandardCompare($1.postScriptName) == .orderedAscending
        }
    }

    /// Validates that a file path is contained within the root directory.
    /// Prevents symlink-based path traversal attacks.
    private static func isContainedWithin(file: URL, root: URL) -> Bool {
        let resolvedFile = file.resolvingSymlinksInPath().standardized.path
        let resolvedRoot = root.resolvingSymlinksInPath().standardized.path
        return resolvedFile.hasPrefix(resolvedRoot + "/") || resolvedFile == resolvedRoot
    }

    /// Extracts PostScript names from a font file using Core Text.
    /// - Parameter url: URL to the font file
    /// - Returns: Array of PostScript names (multiple for .ttc files)
    /// - Note: On non-Apple platforms, returns empty array (triggering filename fallback)
    private static func extractPostScriptNames(from url: URL) -> [String] {
        #if canImport(CoreText)
        guard let descriptors =
            CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor]
        else {
            return []
        }

        var names = [String]()
        for descriptor in descriptors {
            let font = CTFontCreateWithFontDescriptor(descriptor, 0.0, nil)
            let postScriptName = CTFontCopyPostScriptName(font) as String
            names.append(postScriptName)
        }

        return names
        #else
        // CoreText not available on this platform, use filename fallback
        return []
        #endif
    }
}
