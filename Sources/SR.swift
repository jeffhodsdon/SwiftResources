// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

@main
struct SR {
    static let version = "0.1.0"

    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            printUsage()
            exit(0)
        } else if args.contains("--version") {
            print("sr \(version)")
            exit(0)
        } else if args.first == "generate" {
            let generateArgs = Array(args.dropFirst())
            runGenerate(args: generateArgs)
        } else {
            printError("Unknown command: \(args.first ?? "")")
            printUsage()
            exit(1)
        }
    }

    static func runGenerate(args: [String]) {
        if args.contains("--help") || args.contains("-h") {
            printGenerateUsage()
            exit(0)
        }

        do {
            let config = try parseGenerateArgs(args)
            try generate(config: config)
        } catch {
            printError(error.localizedDescription)
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        OVERVIEW: SwiftResources — generate type-safe resource accessors

        USAGE: sr <command> [options]

        COMMANDS:
          generate    Generate Swift code for resources (default)

        OPTIONS:
          --help, -h    Show help information
          --version     Show version
        """)
    }

    static func printGenerateUsage() {
        print("""
        OVERVIEW: Generate Swift code for resources

        USAGE: sr generate [options]

        OPTIONS:
          --fonts <dir>             Directories containing font files (.ttf, .otf) (repeatable)
          --images <dir>            Directories containing image files (repeatable)
          --files <dir>             Directories containing arbitrary files (repeatable)
          --xcassets <dir>          Asset catalog directories (.xcassets) (repeatable)
          --strings <path>          String catalog (.xcstrings) or strings file (.strings) (repeatable)
          --development-region <code>  Source language code (auto-detected from .xcstrings)
          --output <path>           Output path for generated Swift file (default: stdout)
          --module-name <name>      Name of the generated enum namespace (default: Resources)
          --access-level <lvl>      Access level: public or internal (default: internal)
          --bundle <expr>           Bundle override (e.g., .module, .main)
          --no-register-fonts       Skip registerFonts() generation (enabled by default)
          --force-unwrap            Generate non-optional accessors with force unwrap
          --help, -h                Show help information
        """)
    }

    static func printError(_ message: String) {
        FileHandle.standardError.write("Error: \(message)\n".data(using: .utf8)!)
    }
}

// MARK: - Argument Parsing

struct GenerateConfig {
    var fonts: [String] = [] // directories
    var images: [String] = [] // directories
    var files: [String] = [] // directories
    var xcassets: [String] = [] // .xcassets directories
    var strings: [String] = [] // .xcstrings or .strings files
    var fontFiles: [String] = [] // individual file paths
    var imageFiles: [String] = [] // individual file paths
    var filePaths: [String] = [] // individual file paths
    var output: String?
    var moduleName: String = "Resources"
    var accessLevel: String = "internal"
    var bundle: String?
    var registerFonts: Bool = true
    var forceUnwrap: Bool = false
    var developmentRegion: String? // source language for .strings files
}

struct CLIError: LocalizedError {
    let message: String

    var errorDescription: String? { message }

    init(_ message: String) {
        self.message = message
    }
}

// MARK: - CLI Parameter Validation

/// Valid Swift identifier pattern: starts with letter or underscore, followed by
/// alphanumerics/underscores
private let swiftIdentifierPattern = try! NSRegularExpression(
    pattern: "^[a-zA-Z_][a-zA-Z0-9_]*$"
)

/// Validates module name is a valid Swift identifier.
func validateModuleName(_ name: String) throws {
    let range = NSRange(name.startIndex..., in: name)
    guard swiftIdentifierPattern.firstMatch(in: name, range: range) != nil else {
        throw CLIError(
            "Invalid module name '\(name)': must be a valid Swift identifier (letters, digits, underscores; cannot start with digit)"
        )
    }
}

/// Safe bundle expression patterns (allowlist approach).
private let safeBundlePatterns: [NSRegularExpression] = [
    try! NSRegularExpression(pattern: "^\\.module$"),
    try! NSRegularExpression(pattern: "^\\.main$"),
    try! NSRegularExpression(pattern: "^Bundle\\.[a-zA-Z_][a-zA-Z0-9_]*$"),
    try! NSRegularExpression(pattern: "^bundle$"),
]

/// Validates bundle expression against safe patterns.
func validateBundleExpression(_ expr: String) throws {
    let range = NSRange(expr.startIndex..., in: expr)
    let isValid = safeBundlePatterns.contains { pattern in
        pattern.firstMatch(in: expr, range: range) != nil
    }
    guard isValid else {
        throw CLIError(
            "Invalid bundle expression '\(expr)': use .module, .main, bundle, or Bundle.<identifier>"
        )
    }
}

func parseGenerateArgs(_ args: [String]) throws -> GenerateConfig {
    var config = GenerateConfig()
    var i = 0

    while i < args.count {
        let arg = args[i]

        switch arg {
        case "--fonts":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--fonts requires at least one directory")
            }
            config.fonts.append(contentsOf: values)

        case "--images":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--images requires at least one directory")
            }
            config.images.append(contentsOf: values)

        case "--files":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--files requires at least one directory")
            }
            config.files.append(contentsOf: values)

        case "--xcassets":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--xcassets requires at least one directory")
            }
            config.xcassets.append(contentsOf: values)

        case "--strings":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--strings requires at least one file path")
            }
            config.strings.append(contentsOf: values)

        case "--development-region":
            i += 1
            guard i < args.count else {
                throw CLIError("--development-region requires a language code")
            }

            config.developmentRegion = args[i]
            i += 1

        case "--font-file":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--font-file requires at least one file path")
            }
            config.fontFiles.append(contentsOf: values)

        case "--image-file":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--image-file requires at least one file path")
            }
            config.imageFiles.append(contentsOf: values)

        case "--file-path":
            let values = collectValues(args: args, from: &i)
            if values.isEmpty {
                throw CLIError("--file-path requires at least one file path")
            }
            config.filePaths.append(contentsOf: values)

        case "--output":
            i += 1
            guard i < args.count else {
                throw CLIError("--output requires a path")
            }

            config.output = args[i]
            i += 1

        case "--module-name":
            i += 1
            guard i < args.count else {
                throw CLIError("--module-name requires a name")
            }

            config.moduleName = args[i]
            i += 1

        case "--access-level":
            i += 1
            guard i < args.count else {
                throw CLIError("--access-level requires a value")
            }

            config.accessLevel = args[i]
            i += 1

        case "--bundle":
            i += 1
            guard i < args.count else {
                throw CLIError("--bundle requires a value")
            }

            config.bundle = args[i]
            i += 1

        case "--no-register-fonts":
            config.registerFonts = false
            i += 1

        case "--force-unwrap":
            config.forceUnwrap = true
            i += 1

        default:
            throw CLIError("Unknown option: \(arg)")
        }
    }

    return config
}

/// Collects values until the next option (starting with --)
func collectValues(args: [String], from index: inout Int) -> [String] {
    var values = [String]()
    index += 1

    while index < args.count, !args[index].hasPrefix("--") {
        values.append(args[index])
        index += 1
    }

    return values
}

// MARK: - Generate

func generate(config: GenerateConfig) throws {
    // Validate access level
    guard config.accessLevel == "public" || config.accessLevel == "internal" else {
        throw CLIError(
            "Invalid access level '\(config.accessLevel)'. Must be: public or internal"
        )
    }

    // Validate module name is a safe Swift identifier
    try validateModuleName(config.moduleName)

    // Validate bundle expression if provided
    if let bundle = config.bundle {
        try validateBundleExpression(bundle)
    }

    // Validate directories exist
    let fileManager = FileManager.default
    for dir in config.fonts + config.images + config.files + config.xcassets {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: dir, isDirectory: &isDirectory) {
            throw CLIError("Directory not found: \(dir)")
        }
        if !isDirectory.boolValue {
            throw CLIError("Not a directory: \(dir)")
        }
    }

    // Parse resources from directories
    var fontResources = try FontParser.parse(directories: config.fonts)
    var imageResources = try ImageParser.parse(directories: config.images)
    var fileResources = try FileParser.parse(directories: config.files)

    // Parse individual file paths
    try fontResources.append(contentsOf: FontParser.parseFiles(config.fontFiles))
    try imageResources.append(contentsOf: ImageParser.parseFiles(config.imageFiles))
    try fileResources.append(contentsOf: FileParser.parseFiles(config.filePaths))

    // Parse asset catalogs and merge with raw resources
    var colorResources = [DiscoveredColor]()
    if !config.xcassets.isEmpty {
        let (xcImages, xcColors) = try AssetCatalogParser.parse(catalogs: config.xcassets)
        imageResources.append(contentsOf: xcImages)
        colorResources.append(contentsOf: xcColors)
    }

    // Parse string catalogs and strings files
    var stringResources = [String: [DiscoveredString]]()
    for stringPath in config.strings {
        let ext = URL(fileURLWithPath: stringPath).pathExtension.lowercased()
        if ext == "xcstrings" {
            // Parse xcstrings file
            let result = try StringCatalogParser.parse(file: stringPath)
            stringResources[result.tableName, default: []]
                .append(contentsOf: result.strings)
        } else if ext == "strings" {
            // Parse legacy .strings file
            let strings = try StringsFileParser.parse(
                file: stringPath,
                developmentRegion: config.developmentRegion
            )
            if let first = strings.first {
                stringResources[first.tableName, default: []].append(contentsOf: strings)
            }
        } else {
            throw CLIError(
                "Unsupported string file format: \(stringPath). Use .xcstrings or .strings"
            )
        }
    }

    // Warn if directories specified but no resources found
    if !config.fonts.isEmpty, fontResources.isEmpty {
        FileHandle.standardError
            .write("Warning: No font files (.ttf, .otf) found\n".data(using: .utf8)!)
    }
    if !config.images.isEmpty, imageResources.isEmpty {
        FileHandle.standardError
            .write("Warning: No image files found\n".data(using: .utf8)!)
    }
    if !config.files.isEmpty, fileResources.isEmpty {
        FileHandle.standardError.write("Warning: No files found\n".data(using: .utf8)!)
    }
    if !config.xcassets.isEmpty, colorResources.isEmpty {
        // Only warn about colors - images may come from --images flag
        let xcImagesEmpty = imageResources.isEmpty
        if xcImagesEmpty {
            FileHandle.standardError
                .write("Warning: No images or colors found in asset catalogs\n"
                    .data(using: .utf8)!)
        }
    }
    if !config.strings.isEmpty, stringResources.isEmpty {
        FileHandle.standardError
            .write("Warning: No strings found in string catalogs\n".data(using: .utf8)!)
    }

    // Check for duplicates
    try DuplicateChecker.check(fonts: fontResources, category: "fonts")
    try DuplicateChecker.check(images: imageResources, category: "images")
    try DuplicateChecker.check(resources: fileResources, category: "files")
    try DuplicateChecker.check(colors: colorResources, category: "colors")
    for (tableName, strings) in stringResources {
        try DuplicateChecker.check(strings: strings, category: "strings.\(tableName)")
    }

    // Build configuration
    let emitterConfig = SwiftEmitter.Configuration(
        moduleName: config.moduleName,
        accessLevel: config.accessLevel,
        bundleOverride: config.bundle,
        registerFonts: config.registerFonts,
        forceUnwrap: config.forceUnwrap
    )

    // Generate code
    let code = SwiftEmitter.emit(
        fonts: fontResources,
        images: imageResources,
        colors: colorResources,
        files: fileResources,
        strings: stringResources,
        configuration: emitterConfig
    )

    // Output
    if let outputPath = config.output {
        try code.write(toFile: outputPath, atomically: true, encoding: .utf8)
    } else {
        print(code)
    }
}
