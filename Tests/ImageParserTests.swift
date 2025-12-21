// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

@Suite("ImageParser")
struct ImageParserTests {
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

    @Test("Finds all supported image types")
    func findsAllTypes() throws {
        let imageDir = tempDir.appendingPathComponent("Images")
        try FileManager.default.createDirectory(
            at: imageDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageDir.appendingPathComponent("a.png"))
        try Data().write(to: imageDir.appendingPathComponent("b.jpg"))
        try Data().write(to: imageDir.appendingPathComponent("c.jpeg"))
        try Data().write(to: imageDir.appendingPathComponent("d.pdf"))
        try Data().write(to: imageDir.appendingPathComponent("e.svg"))
        try Data().write(to: imageDir.appendingPathComponent("f.heic"))

        let resources = try ImageParser.parse(directories: [imageDir.path])

        #expect(resources.count == 6)
    }

    @Test("Ignores non-image files")
    func ignoresNonImages() throws {
        let imageDir = tempDir.appendingPathComponent("Images2")
        try FileManager.default.createDirectory(
            at: imageDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageDir.appendingPathComponent("icon.png"))
        try Data().write(to: imageDir.appendingPathComponent("font.ttf"))
        try Data().write(to: imageDir.appendingPathComponent("data.json"))

        let resources = try ImageParser.parse(directories: [imageDir.path])

        #expect(resources.count == 1)
        #expect(resources[0].name == "icon")
    }

    @Test("Scans recursively")
    func scansRecursively() throws {
        let imageDir = tempDir.appendingPathComponent("Images3")
        let subDir = imageDir.appendingPathComponent("Icons")
        try FileManager.default.createDirectory(
            at: subDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: imageDir.appendingPathComponent("logo.png"))
        try Data().write(to: subDir.appendingPathComponent("arrow.png"))

        let resources = try ImageParser.parse(directories: [imageDir.path])

        #expect(resources.count == 2)
    }

    @Test("Returns empty for empty directory")
    func emptyDirectory() throws {
        let imageDir = tempDir.appendingPathComponent("EmptyImages")
        try FileManager.default.createDirectory(
            at: imageDir,
            withIntermediateDirectories: true
        )

        let resources = try ImageParser.parse(directories: [imageDir.path])

        #expect(resources.isEmpty)
    }

    @Test("Handles multiple directories")
    func multipleDirectories() throws {
        let dir1 = tempDir.appendingPathComponent("ImagesA")
        let dir2 = tempDir.appendingPathComponent("ImagesB")
        try FileManager.default.createDirectory(
            at: dir1,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: dir2,
            withIntermediateDirectories: true
        )
        try Data().write(to: dir1.appendingPathComponent("icon1.png"))
        try Data().write(to: dir2.appendingPathComponent("icon2.png"))

        let resources = try ImageParser.parse(directories: [dir1.path, dir2.path])

        #expect(resources.count == 2)
    }
}
