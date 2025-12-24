// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

@testable import SwiftResources
import Testing

@Suite("CLI Argument Parsing")
struct CLIParserTests {
    // MARK: - Basic Flag Parsing

    @Test("Parses --module-name correctly")
    func moduleName() throws {
        let config = try parseGenerateArgs(["--module-name", "DesignSystem"])
        #expect(config.moduleName == "DesignSystem")
    }

    @Test("Parses --access-level correctly")
    func accessLevel() throws {
        let config = try parseGenerateArgs(["--access-level", "public"])
        #expect(config.accessLevel == "public")
    }

    @Test("Parses --output correctly")
    func output() throws {
        let config = try parseGenerateArgs(["--output", "/tmp/Resources.swift"])
        #expect(config.output == "/tmp/Resources.swift")
    }

    @Test("Parses --bundle correctly")
    func bundle() throws {
        let config = try parseGenerateArgs(["--bundle", ".module"])
        #expect(config.bundle == ".module")
    }

    @Test("Parses --no-register-fonts correctly")
    func noRegisterFonts() throws {
        let config = try parseGenerateArgs(["--no-register-fonts"])
        #expect(config.registerFonts == false)
    }

    // MARK: - Directory Flags (Multi-value)

    @Test("Parses single --fonts directory")
    func singleFontsDir() throws {
        let config = try parseGenerateArgs(["--fonts", "/path/to/fonts"])
        #expect(config.fonts == ["/path/to/fonts"])
    }

    @Test("Parses multiple values for --fonts")
    func multipleFontsValues() throws {
        let config = try parseGenerateArgs(["--fonts", "/fonts1", "/fonts2", "/fonts3"])
        #expect(config.fonts == ["/fonts1", "/fonts2", "/fonts3"])
    }

    @Test("Parses --fonts repeated multiple times")
    func repeatedFontsFlag() throws {
        let config = try parseGenerateArgs([
            "--fonts", "/fonts1",
            "--fonts", "/fonts2",
        ])
        #expect(config.fonts == ["/fonts1", "/fonts2"])
    }

    @Test("Parses single --images directory")
    func singleImagesDir() throws {
        let config = try parseGenerateArgs(["--images", "/path/to/images"])
        #expect(config.images == ["/path/to/images"])
    }

    @Test("Parses single --files directory")
    func singleFilesDir() throws {
        let config = try parseGenerateArgs(["--files", "/path/to/data"])
        #expect(config.files == ["/path/to/data"])
    }

    // MARK: - Individual File Path Flags

    @Test("Parses single --font-file path")
    func singleFontFile() throws {
        let config = try parseGenerateArgs(["--font-file", "/fonts/Inter.ttf"])
        #expect(config.fontFiles == ["/fonts/Inter.ttf"])
    }

    @Test("Parses multiple values for --font-file")
    func multipleFontFiles() throws {
        let config = try parseGenerateArgs(["--font-file", "/Inter.ttf", "/Roboto.otf"])
        #expect(config.fontFiles == ["/Inter.ttf", "/Roboto.otf"])
    }

    @Test("Parses single --image-file path")
    func singleImageFile() throws {
        let config = try parseGenerateArgs(["--image-file", "/images/logo.png"])
        #expect(config.imageFiles == ["/images/logo.png"])
    }

    @Test("Parses single --file-path")
    func singleFilePath() throws {
        let config = try parseGenerateArgs(["--file-path", "/data/config.json"])
        #expect(config.filePaths == ["/data/config.json"])
    }

    // MARK: - Multi-value Collection Behavior

    @Test("Stops collecting values at next flag")
    func stopsAtNextFlag() throws {
        let config = try parseGenerateArgs([
            "--fonts", "/fonts1", "/fonts2",
            "--images", "/images1",
        ])
        #expect(config.fonts == ["/fonts1", "/fonts2"])
        #expect(config.images == ["/images1"])
    }

    @Test("Handles interleaved directory and file flags")
    func interleavedFlags() throws {
        let config = try parseGenerateArgs([
            "--fonts", "/fonts",
            "--font-file", "/extra/Font.ttf",
            "--images", "/images",
        ])
        #expect(config.fonts == ["/fonts"])
        #expect(config.fontFiles == ["/extra/Font.ttf"])
        #expect(config.images == ["/images"])
    }

    // MARK: - Complex Combinations

    @Test("Parses full configuration")
    func fullConfig() throws {
        let config = try parseGenerateArgs([
            "--fonts", "/fonts",
            "--images", "/images",
            "--files", "/data",
            "--output", "/out/Resources.swift",
            "--module-name", "AppResources",
            "--access-level", "public",
            "--bundle", ".module",
            "--no-register-fonts",
        ])

        #expect(config.fonts == ["/fonts"])
        #expect(config.images == ["/images"])
        #expect(config.files == ["/data"])
        #expect(config.output == "/out/Resources.swift")
        #expect(config.moduleName == "AppResources")
        #expect(config.accessLevel == "public")
        #expect(config.bundle == ".module")
        #expect(config.registerFonts == false)
    }

    @Test("Parses mixed directory and file inputs")
    func mixedInputs() throws {
        let config = try parseGenerateArgs([
            "--fonts", "/fonts/dir",
            "--font-file", "/extra/Font1.ttf", "/extra/Font2.otf",
            "--image-file", "/img/logo.png",
            "--file-path", "/data/a.json", "/data/b.json",
        ])

        #expect(config.fonts == ["/fonts/dir"])
        #expect(config.fontFiles == ["/extra/Font1.ttf", "/extra/Font2.otf"])
        #expect(config.imageFiles == ["/img/logo.png"])
        #expect(config.filePaths == ["/data/a.json", "/data/b.json"])
    }

    // MARK: - Default Values

    @Test("Uses default values when no args provided")
    func defaults() throws {
        let config = try parseGenerateArgs([])
        #expect(config.fonts.isEmpty)
        #expect(config.images.isEmpty)
        #expect(config.files.isEmpty)
        #expect(config.fontFiles.isEmpty)
        #expect(config.imageFiles.isEmpty)
        #expect(config.filePaths.isEmpty)
        #expect(config.output == nil)
        #expect(config.moduleName == "Resources")
        #expect(config.accessLevel == "internal")
        #expect(config.bundle == nil)
        #expect(config.registerFonts == true)
    }

    // MARK: - Error Cases

    @Test("Throws error for --fonts without value")
    func fontsMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--fonts"])
        }
    }

    @Test("Throws error for --images without value")
    func imagesMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--images"])
        }
    }

    @Test("Throws error for --files without value")
    func filesMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--files"])
        }
    }

    @Test("Throws error for --font-file without value")
    func fontFileMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--font-file"])
        }
    }

    @Test("Throws error for --image-file without value")
    func imageFileMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--image-file"])
        }
    }

    @Test("Throws error for --file-path without value")
    func filePathMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--file-path"])
        }
    }

    @Test("Throws error for --output without value")
    func outputMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--output"])
        }
    }

    @Test("Throws error for --module-name without value")
    func moduleNameMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--module-name"])
        }
    }

    @Test("Throws error for --access-level without value")
    func accessLevelMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--access-level"])
        }
    }

    @Test("Throws error for --bundle without value")
    func bundleMissingValue() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--bundle"])
        }
    }

    @Test("Throws error for unknown option")
    func unknownOption() {
        #expect(throws: CLIError.self) {
            _ = try parseGenerateArgs(["--unknown-flag"])
        }
    }

    @Test("Error message contains the unknown option name")
    func unknownOptionMessage() {
        do {
            _ = try parseGenerateArgs(["--foobar"])
            Issue.record("Expected error to be thrown")
        } catch let error as CLIError {
            #expect(error.message.contains("--foobar"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
