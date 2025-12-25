// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parses .xcassets asset catalogs to discover images and colors.
enum AssetCatalogParser {
    /// Parses asset catalogs to discover images and colors.
    /// - Parameter catalogs: Paths to .xcassets directories
    /// - Returns: Tuple of discovered images and colors, sorted by name
    static func parse(catalogs: [String]) throws
        -> (images: [DiscoveredImage], colors: [DiscoveredColor])
    {
        var images = [DiscoveredImage]()
        var colors = [DiscoveredColor]()
        let fileManager = FileManager.default

        for catalog in catalogs {
            let catalogURL = URL(fileURLWithPath: catalog).standardizedFileURL
            try parseDirectory(
                at: catalogURL,
                namespace: [],
                fileManager: fileManager,
                images: &images,
                colors: &colors
            )
        }

        let sortedImages = images.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        let sortedColors = colors.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }

        return (sortedImages, sortedColors)
    }

    // MARK: - Private

    private static func parseDirectory(
        at url: URL,
        namespace: [String],
        fileManager: FileManager,
        images: inout [DiscoveredImage],
        colors: inout [DiscoveredColor]
    ) throws {
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in contents {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?
                .isDirectory ?? false

            guard isDirectory else {
                continue
            }

            let ext = item.pathExtension.lowercased()
            let name = item.deletingPathExtension().lastPathComponent

            switch ext {
            case "imageset":
                let fullName = (namespace + [name]).joined(separator: "/")
                // Validate asset name is safe for code generation
                try StringValidator.validate(
                    fullName,
                    context: "image asset '\(fullName)'"
                )
                images.append(DiscoveredImage(name: fullName))

            case "colorset":
                let fullName = (namespace + [name]).joined(separator: "/")
                // Validate asset name is safe for code generation
                try StringValidator.validate(
                    fullName,
                    context: "color asset '\(fullName)'"
                )
                colors.append(DiscoveredColor(name: fullName))

            default:
                // Regular folder - check if it provides namespace for its children
                let folderProvidesNamespace = directoryProvidesNamespace(
                    at: item,
                    fileManager: fileManager
                )
                let newNamespace = folderProvidesNamespace ? namespace + [name] :
                    namespace
                try parseDirectory(
                    at: item,
                    namespace: newNamespace,
                    fileManager: fileManager,
                    images: &images,
                    colors: &colors
                )
            }
        }
    }

    /// Checks if a directory's Contents.json has "provides-namespace": true
    private static func directoryProvidesNamespace(at url: URL,
                                                   fileManager: FileManager) -> Bool
    {
        let contentsURL = url.appendingPathComponent("Contents.json")

        guard fileManager.fileExists(atPath: contentsURL.path),
              let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any],
              let providesNamespace = properties["provides-namespace"] as? Bool
        else {
            return false
        }

        return providesNamespace
    }
}
