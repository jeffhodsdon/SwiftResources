// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

@Suite("FileParser")
struct FileParserTests {
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

    @Test("Finds all file types")
    func findsAllTypes() throws {
        let fileDir = tempDir.appendingPathComponent("Data")
        try FileManager.default.createDirectory(
            at: fileDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fileDir.appendingPathComponent("config.json"))
        try Data().write(to: fileDir.appendingPathComponent("data.xml"))
        try Data().write(to: fileDir.appendingPathComponent("template.html"))

        let resources = try FileParser.parse(directories: [fileDir.path])

        #expect(resources.count == 3)
    }

    @Test("Stores extension correctly")
    func storesExtension() throws {
        let fileDir = tempDir.appendingPathComponent("Data2")
        try FileManager.default.createDirectory(
            at: fileDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fileDir.appendingPathComponent("config.json"))

        let resources = try FileParser.parse(directories: [fileDir.path])

        #expect(resources.count == 1)
        #expect(resources[0].name == "config")
        #expect(resources[0].extension == "json")
    }

    @Test("Scans recursively")
    func scansRecursively() throws {
        let fileDir = tempDir.appendingPathComponent("Data3")
        let subDir = fileDir.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(
            at: subDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: fileDir.appendingPathComponent("top.json"))
        try Data().write(to: subDir.appendingPathComponent("deep.json"))

        let resources = try FileParser.parse(directories: [fileDir.path])

        #expect(resources.count == 2)
    }

    @Test("Returns empty for empty directory")
    func emptyDirectory() throws {
        let fileDir = tempDir.appendingPathComponent("EmptyData")
        try FileManager.default.createDirectory(
            at: fileDir,
            withIntermediateDirectories: true
        )

        let resources = try FileParser.parse(directories: [fileDir.path])

        #expect(resources.isEmpty)
    }

    @Test("Handles multiple directories")
    func multipleDirectories() throws {
        let dir1 = tempDir.appendingPathComponent("DataA")
        let dir2 = tempDir.appendingPathComponent("DataB")
        try FileManager.default.createDirectory(
            at: dir1,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: dir2,
            withIntermediateDirectories: true
        )
        try Data().write(to: dir1.appendingPathComponent("file1.json"))
        try Data().write(to: dir2.appendingPathComponent("file2.json"))

        let resources = try FileParser.parse(directories: [dir1.path, dir2.path])

        #expect(resources.count == 2)
    }
}
