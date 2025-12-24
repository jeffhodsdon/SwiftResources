// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

@Suite("AssetCatalogParser")
struct AssetCatalogParserTests {
    let tempDir: URL

    init() throws {
        tempDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("SwiftResourcesTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Basic Parsing

    @Test("Finds imagesets in asset catalog")
    func findsImagesets() throws {
        let catalog = tempDir.appendingPathComponent("Assets.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create an imageset
        let imageset = catalog.appendingPathComponent("logo.imageset")
        try FileManager.default.createDirectory(
            at: imageset,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset.appendingPathComponent("Contents.json"))

        let (images, colors) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 1)
        #expect(images[0].name == "logo")
        #expect(colors.isEmpty)
    }

    @Test("Finds colorsets in asset catalog")
    func findsColorsets() throws {
        let catalog = tempDir.appendingPathComponent("Colors.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create a colorset
        let colorset = catalog.appendingPathComponent("Primary.colorset")
        try FileManager.default.createDirectory(
            at: colorset,
            withIntermediateDirectories: true
        )
        try Data().write(to: colorset.appendingPathComponent("Contents.json"))

        let (images, colors) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.isEmpty)
        #expect(colors.count == 1)
        #expect(colors[0].name == "Primary")
    }

    @Test("Finds both images and colors")
    func findsBothTypes() throws {
        let catalog = tempDir.appendingPathComponent("Mixed.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create imageset
        let imageset = catalog.appendingPathComponent("icon.imageset")
        try FileManager.default.createDirectory(
            at: imageset,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset.appendingPathComponent("Contents.json"))

        // Create colorset
        let colorset = catalog.appendingPathComponent("accent.colorset")
        try FileManager.default.createDirectory(
            at: colorset,
            withIntermediateDirectories: true
        )
        try Data().write(to: colorset.appendingPathComponent("Contents.json"))

        let (images, colors) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 1)
        #expect(images[0].name == "icon")
        #expect(colors.count == 1)
        #expect(colors[0].name == "accent")
    }

    // MARK: - Nested Folders (No Namespace)

    @Test("Finds assets in nested folders without namespace")
    func nestedFoldersNoNamespace() throws {
        let catalog = tempDir.appendingPathComponent("Nested.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create folder without provides-namespace
        let folder = catalog.appendingPathComponent("Icons")
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        // Create imageset inside folder
        let imageset = folder.appendingPathComponent("arrow.imageset")
        try FileManager.default.createDirectory(
            at: imageset,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset.appendingPathComponent("Contents.json"))

        let (images, _) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 1)
        #expect(images[0].name == "arrow")
    }

    // MARK: - Namespace Support

    @Test("Applies namespace when provides-namespace is true")
    func appliesNamespace() throws {
        let catalog = tempDir.appendingPathComponent("Namespaced.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create folder with provides-namespace
        let folder = catalog.appendingPathComponent("Brand")
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        // Add Contents.json with provides-namespace
        let contentsJSON = """
        {
            "info": { "version": 1, "author": "xcode" },
            "properties": { "provides-namespace": true }
        }
        """
        try contentsJSON.write(
            to: folder.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )

        // Create imageset inside namespaced folder
        let imageset = folder.appendingPathComponent("logo.imageset")
        try FileManager.default.createDirectory(
            at: imageset,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset.appendingPathComponent("Contents.json"))

        let (images, _) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 1)
        #expect(images[0].name == "Brand/logo")
    }

    @Test("Nested namespaces create path")
    func nestedNamespaces() throws {
        let catalog = tempDir.appendingPathComponent("DeepNested.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        let contentsJSON = """
        {
            "info": { "version": 1, "author": "xcode" },
            "properties": { "provides-namespace": true }
        }
        """

        // Create Level1/Level2 with namespaces
        let level1 = catalog.appendingPathComponent("Level1")
        try FileManager.default.createDirectory(
            at: level1,
            withIntermediateDirectories: true
        )
        try contentsJSON.write(
            to: level1.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )

        let level2 = level1.appendingPathComponent("Level2")
        try FileManager.default.createDirectory(
            at: level2,
            withIntermediateDirectories: true
        )
        try contentsJSON.write(
            to: level2.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )

        // Create imageset
        let imageset = level2.appendingPathComponent("deep.imageset")
        try FileManager.default.createDirectory(
            at: imageset,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset.appendingPathComponent("Contents.json"))

        let (images, _) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 1)
        #expect(images[0].name == "Level1/Level2/deep")
    }

    // MARK: - Multiple Catalogs

    @Test("Parses multiple catalogs")
    func multipleCatalogs() throws {
        let catalog1 = tempDir.appendingPathComponent("Assets1.xcassets")
        let catalog2 = tempDir.appendingPathComponent("Assets2.xcassets")

        for catalog in [catalog1, catalog2] {
            try FileManager.default.createDirectory(
                at: catalog,
                withIntermediateDirectories: true
            )
        }

        // Add imageset to catalog1
        let imageset1 = catalog1.appendingPathComponent("icon1.imageset")
        try FileManager.default.createDirectory(
            at: imageset1,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset1.appendingPathComponent("Contents.json"))

        // Add imageset to catalog2
        let imageset2 = catalog2.appendingPathComponent("icon2.imageset")
        try FileManager.default.createDirectory(
            at: imageset2,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageset2.appendingPathComponent("Contents.json"))

        let (images, _) = try AssetCatalogParser.parse(catalogs: [
            catalog1.path,
            catalog2.path,
        ])

        #expect(images.count == 2)
        let names = Set(images.map(\.name))
        #expect(names.contains("icon1"))
        #expect(names.contains("icon2"))
    }

    // MARK: - Empty Catalog

    @Test("Returns empty for empty catalog")
    func emptyCatalog() throws {
        let catalog = tempDir.appendingPathComponent("Empty.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        let (images, colors) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.isEmpty)
        #expect(colors.isEmpty)
    }

    // MARK: - Sorting

    @Test("Results are sorted by name")
    func sortedResults() throws {
        let catalog = tempDir.appendingPathComponent("Sorted.xcassets")
        try FileManager.default.createDirectory(
            at: catalog,
            withIntermediateDirectories: true
        )

        // Create imagesets out of order
        for name in ["zebra", "apple", "mango"] {
            let imageset = catalog.appendingPathComponent("\(name).imageset")
            try FileManager.default.createDirectory(
                at: imageset,
                withIntermediateDirectories: true
            )
            try Data().write(to: imageset.appendingPathComponent("Contents.json"))
        }

        let (images, _) = try AssetCatalogParser.parse(catalogs: [catalog.path])

        #expect(images.count == 3)
        #expect(images[0].name == "apple")
        #expect(images[1].name == "mango")
        #expect(images[2].name == "zebra")
    }
}
