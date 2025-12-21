// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import CoreText
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

    /// Extracts PostScript names from a font file using Core Text.
    /// - Parameter url: URL to the font file
    /// - Returns: Array of PostScript names (multiple for .ttc files)
    private static func extractPostScriptNames(from url: URL) -> [String] {
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
    }
}
