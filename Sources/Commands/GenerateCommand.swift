// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import ArgumentParser
import Foundation

struct GenerateCommand: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "generate",
        abstract: "Generate Swift code for resources"
    )

    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Directories containing font files (.ttf, .otf)"
    )
    var fonts: [String] = []

    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Directories containing image files"
    )
    var images: [String] = []

    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Directories containing arbitrary files"
    )
    var files: [String] = []

    @Option(name: .long, help: "Output path for generated Swift file (default: stdout)")
    var output: String?

    @Option(name: .long, help: "Name of the generated enum namespace")
    var moduleName: String = "Resources"

    @Option(name: .long, help: "Access level: public or internal")
    var accessLevel: String = "internal"

    @Option(
        name: .long,
        help: "Bundle override (e.g., .module, .main). Default: auto-detect via BundleFinder"
    )
    var bundle: String?

    @Flag(name: .long, inversion: .prefixedNo, help: "Generate registerFonts() function")
    var registerFonts: Bool = true

    func run() throws {
        // Validate access level
        guard accessLevel == "public" || accessLevel == "internal" else {
            throw ValidationError(
                "Invalid access level '\(accessLevel)'. Must be: public or internal"
            )
        }

        // Validate directories exist
        let fileManager = FileManager.default
        for dir in fonts + images + files {
            var isDirectory: ObjCBool = false
            if !fileManager.fileExists(atPath: dir, isDirectory: &isDirectory) {
                throw ValidationError("Directory not found: \(dir)")
            }
            if !isDirectory.boolValue {
                throw ValidationError("Not a directory: \(dir)")
            }
        }

        // Parse resources
        let fontResources = try FontParser.parse(directories: fonts)
        let imageResources = try ImageParser.parse(directories: images)
        let fileResources = try FileParser.parse(directories: files)

        // Warn if directories specified but no resources found
        if !fonts.isEmpty, fontResources.isEmpty {
            FileHandle.standardError
                .write("Warning: No font files (.ttf, .otf) found\n".data(using: .utf8)!)
        }
        if !images.isEmpty, imageResources.isEmpty {
            FileHandle.standardError
                .write("Warning: No image files found\n".data(using: .utf8)!)
        }
        if !files.isEmpty, fileResources.isEmpty {
            FileHandle.standardError
                .write("Warning: No files found\n".data(using: .utf8)!)
        }

        // Check for duplicates
        try DuplicateChecker.check(fonts: fontResources, category: "fonts")
        try DuplicateChecker.check(resources: imageResources, category: "images")
        try DuplicateChecker.check(resources: fileResources, category: "files")

        // Build configuration
        let configuration = SwiftEmitter.Configuration(
            moduleName: moduleName,
            accessLevel: accessLevel,
            bundleOverride: bundle,
            registerFonts: registerFonts
        )

        // Generate code
        let code = SwiftEmitter.emit(
            fonts: fontResources,
            images: imageResources,
            files: fileResources,
            configuration: configuration
        )

        // Output
        if let outputPath = output {
            try code.write(toFile: outputPath, atomically: true, encoding: .utf8)
        } else {
            print(code)
        }
    }
}
