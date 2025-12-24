// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

@Suite("FontParser")
struct FontParserTests {
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

    @Test("Finds TTF files")
    func findsTTF() throws {
        let fontDir = tempDir.appendingPathComponent("Fonts")
        try FileManager.default.createDirectory(
            at: fontDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fontDir.appendingPathComponent("Inter-Bold.ttf"))

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.count == 1)
        // Empty file falls back to filename as postScriptName
        #expect(fonts[0].postScriptName == "Inter-Bold")
        #expect(fonts[0].fileName == "Inter-Bold")
        #expect(fonts[0].fileExtension == "ttf")
    }

    @Test("Finds OTF files")
    func findsOTF() throws {
        let fontDir = tempDir.appendingPathComponent("Fonts2")
        try FileManager.default.createDirectory(
            at: fontDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fontDir.appendingPathComponent("Roboto.otf"))

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.count == 1)
        #expect(fonts[0].postScriptName == "Roboto")
        #expect(fonts[0].fileExtension == "otf")
    }

    @Test("Ignores non-font files")
    func ignoresNonFonts() throws {
        let fontDir = tempDir.appendingPathComponent("Fonts3")
        try FileManager.default.createDirectory(
            at: fontDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fontDir.appendingPathComponent("Inter.ttf"))
        try Data().write(to: fontDir.appendingPathComponent("readme.txt"))
        try Data().write(to: fontDir.appendingPathComponent("logo.png"))

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.count == 1)
        #expect(fonts[0].postScriptName == "Inter")
    }

    @Test("Scans recursively")
    func scansRecursively() throws {
        let fontDir = tempDir.appendingPathComponent("Fonts4")
        let subDir = fontDir.appendingPathComponent("SubFolder")
        try FileManager.default.createDirectory(
            at: subDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fontDir.appendingPathComponent("Top.ttf"))
        try Data().write(to: subDir.appendingPathComponent("Nested.ttf"))

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.count == 2)
        let names = fonts.map(\.postScriptName)
        #expect(names.contains("Top"))
        #expect(names.contains("Nested"))
    }

    @Test("Returns empty for empty directory")
    func emptyDirectory() throws {
        let fontDir = tempDir.appendingPathComponent("EmptyFonts")
        try FileManager.default.createDirectory(
            at: fontDir,
            withIntermediateDirectories: true
        )

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.isEmpty)
    }

    @Test("Handles multiple directories")
    func multipleDirectories() throws {
        let dir1 = tempDir.appendingPathComponent("FontsA")
        let dir2 = tempDir.appendingPathComponent("FontsB")
        try FileManager.default.createDirectory(
            at: dir1,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: dir2,
            withIntermediateDirectories: true
        )
        try Data().write(to: dir1.appendingPathComponent("Font1.ttf"))
        try Data().write(to: dir2.appendingPathComponent("Font2.ttf"))

        let fonts = try FontParser.parse(directories: [dir1.path, dir2.path])

        #expect(fonts.count == 2)
    }

    @Test("Stores file info for registration")
    func storesFileInfo() throws {
        let fontDir = tempDir.appendingPathComponent("Fonts5")
        try FileManager.default.createDirectory(
            at: fontDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fontDir.appendingPathComponent("MyFont.ttf"))

        let fonts = try FontParser.parse(directories: [fontDir.path])

        #expect(fonts.count == 1)
        #expect(fonts[0].fileName == "MyFont")
        #expect(fonts[0].fileExtension == "ttf")
        #expect(fonts[0].relativePath == "MyFont.ttf")
    }
}
