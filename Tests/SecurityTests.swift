// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

@Suite("Security")
struct SecurityTests {
    // MARK: - StringValidator Tests

    @Test("Rejects double quotes in strings")
    func rejectsDoubleQuotes() {
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("evil\"injection", context: "test")
        }
    }

    @Test("Rejects backslashes in strings")
    func rejectsBackslashes() {
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("path\\to\\file", context: "test")
        }
    }

    @Test("Rejects newlines in strings")
    func rejectsNewlines() {
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("line1\nline2", context: "test")
        }
    }

    @Test("Rejects carriage returns in strings")
    func rejectsCarriageReturns() {
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("line1\rline2", context: "test")
        }
    }

    @Test("Rejects null characters in strings")
    func rejectsNullChars() {
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("trunc\0ated", context: "test")
        }
    }

    @Test("Rejects Unicode characters")
    func rejectsUnicode() {
        // Cyrillic 'а' (looks like Latin 'a') - homograph attack
        #expect(throws: StringValidator.UnsafeStringError.self) {
            try StringValidator.validate("tеst", context: "test") // 'е' is Cyrillic
        }
    }

    @Test("Accepts valid ASCII resource names")
    func acceptsValidNames() throws {
        try StringValidator.validate("Inter-Bold", context: "font")
        try StringValidator.validate("hero_background", context: "image")
        try StringValidator.validate("config.json", context: "file")
        try StringValidator.validate("Icons/settings", context: "asset")
        try StringValidator.validate("My Font Name", context: "font")
    }

    // MARK: - Module Name Validation Tests

    @Test("Rejects module name with injection")
    func rejectsModuleNameInjection() {
        #expect(throws: CLIError.self) {
            try validateModuleName("Foo { } enum Bar")
        }
    }

    @Test("Rejects module name starting with digit")
    func rejectsModuleNameWithDigit() {
        #expect(throws: CLIError.self) {
            try validateModuleName("2Fast")
        }
    }

    @Test("Accepts valid module names")
    func acceptsValidModuleNames() throws {
        try validateModuleName("Resources")
        try validateModuleName("DesignSystem")
        try validateModuleName("MyApp_Resources")
        try validateModuleName("_Private")
    }

    // MARK: - Bundle Expression Validation Tests

    @Test("Rejects bundle expression with injection")
    func rejectsBundleInjection() {
        #expect(throws: CLIError.self) {
            try validateBundleExpression("bundle); evil(); (x")
        }
    }

    @Test("Rejects arbitrary bundle expressions")
    func rejectsArbitraryBundle() {
        #expect(throws: CLIError.self) {
            try validateBundleExpression("someRandomCode")
        }
    }

    @Test("Accepts valid bundle expressions")
    func acceptsValidBundleExpressions() throws {
        try validateBundleExpression(".module")
        try validateBundleExpression(".main")
        try validateBundleExpression("bundle")
        try validateBundleExpression("Bundle.myBundle")
    }

    // MARK: - NameSanitizer ASCII Tests

    @Test("Strips Unicode from identifiers")
    func stripsUnicodeFromIdentifiers() {
        // Cyrillic characters should be stripped
        let result = NameSanitizer.sanitize("tеst") // 'е' is Cyrillic
        #expect(result == "tst") // Cyrillic 'е' removed
    }

    @Test("Keeps only ASCII in identifiers")
    func keepsOnlyASCII() {
        let result = NameSanitizer.sanitize("café")
        #expect(result == "caf") // 'é' removed
    }

    // MARK: - Path Traversal Tests

    @Test("ImageParser skips symlinks pointing outside root")
    func imageParserSkipsExternalSymlinks() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let imagesDir = tempDir.appendingPathComponent("images")
        let externalDir = tempDir.appendingPathComponent("external")

        // Setup
        try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: externalDir, withIntermediateDirectories: true)

        // Create a real image in images dir
        let realImage = imagesDir.appendingPathComponent("real.png")
        try Data().write(to: realImage)

        // Create an external image
        let externalImage = externalDir.appendingPathComponent("secret.png")
        try Data().write(to: externalImage)

        // Create symlink pointing outside
        let symlinkPath = imagesDir.appendingPathComponent("evil.png")
        try fm.createSymbolicLink(at: symlinkPath, withDestinationURL: externalImage)

        defer { try? fm.removeItem(at: tempDir) }

        // Parse should only find the real image, not the symlinked one
        let images = try ImageParser.parse(directories: [imagesDir.path])
        #expect(images.count == 1)
        #expect(images.first?.name == "real")
    }

    @Test("FileParser skips symlinks pointing outside root")
    func fileParserSkipsExternalSymlinks() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let filesDir = tempDir.appendingPathComponent("files")
        let externalDir = tempDir.appendingPathComponent("external")

        // Setup
        try fm.createDirectory(at: filesDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: externalDir, withIntermediateDirectories: true)

        // Create a real file
        let realFile = filesDir.appendingPathComponent("config.json")
        try Data().write(to: realFile)

        // Create an external file
        let externalFile = externalDir.appendingPathComponent("passwd.txt")
        try Data().write(to: externalFile)

        // Create symlink pointing outside
        let symlinkPath = filesDir.appendingPathComponent("evil.txt")
        try fm.createSymbolicLink(at: symlinkPath, withDestinationURL: externalFile)

        defer { try? fm.removeItem(at: tempDir) }

        // Parse should only find the real file, not the symlinked one
        let files = try FileParser.parse(directories: [filesDir.path])
        #expect(files.count == 1)
        #expect(files.first?.name == "config")
    }

    @Test("Parsers allow symlinks within root directory")
    func parsersAllowInternalSymlinks() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let imagesDir = tempDir.appendingPathComponent("images")
        let subDir = imagesDir.appendingPathComponent("subdir")

        // Setup
        try fm.createDirectory(at: subDir, withIntermediateDirectories: true)

        // Create a real image in subdir
        let realImage = subDir.appendingPathComponent("real.png")
        try Data().write(to: realImage)

        // Create symlink within root pointing to subdir image
        let symlinkPath = imagesDir.appendingPathComponent("alias.png")
        try fm.createSymbolicLink(at: symlinkPath, withDestinationURL: realImage)

        defer { try? fm.removeItem(at: tempDir) }

        // Parse should find both (symlink points within root)
        let images = try ImageParser.parse(directories: [imagesDir.path])
        #expect(images.count == 2)
    }
}
