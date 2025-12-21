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
          --fonts <dir>         Directories containing font files (.ttf, .otf) (repeatable)
          --images <dir>        Directories containing image files (repeatable)
          --files <dir>         Directories containing arbitrary files (repeatable)
          --output <path>       Output path for generated Swift file (default: stdout)
          --module-name <name>  Name of the generated enum namespace (default: Resources)
          --access-level <lvl>  Access level: public or internal (default: internal)
          --bundle <expr>       Bundle override (e.g., .module, .main)
          --register-fonts      Generate registerFonts() function (default)
          --no-register-fonts   Skip registerFonts() function
          --help, -h            Show help information
        """)
    }

    static func printError(_ message: String) {
        FileHandle.standardError.write("Error: \(message)\n".data(using: .utf8)!)
    }
}

// MARK: - Argument Parsing

struct GenerateConfig {
    var fonts: [String] = []
    var images: [String] = []
    var files: [String] = []
    var output: String?
    var moduleName: String = "Resources"
    var accessLevel: String = "internal"
    var bundle: String?
    var registerFonts: Bool = true
}

struct CLIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }

    init(_ message: String) {
        self.message = message
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

        case "--register-fonts":
            config.registerFonts = true
            i += 1

        case "--no-register-fonts":
            config.registerFonts = false
            i += 1

        default:
            throw CLIError("Unknown option: \(arg)")
        }
    }

    return config
}

/// Collects values until the next option (starting with --)
func collectValues(args: [String], from index: inout Int) -> [String] {
    var values: [String] = []
    index += 1

    while index < args.count && !args[index].hasPrefix("--") {
        values.append(args[index])
        index += 1
    }

    return values
}

// MARK: - Generate

func generate(config: GenerateConfig) throws {
    // Validate access level
    guard config.accessLevel == "public" || config.accessLevel == "internal" else {
        throw CLIError("Invalid access level '\(config.accessLevel)'. Must be: public or internal")
    }

    // Validate directories exist
    let fileManager = FileManager.default
    for dir in config.fonts + config.images + config.files {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: dir, isDirectory: &isDirectory) {
            throw CLIError("Directory not found: \(dir)")
        }
        if !isDirectory.boolValue {
            throw CLIError("Not a directory: \(dir)")
        }
    }

    // Parse resources
    let fontResources = try FontParser.parse(directories: config.fonts)
    let imageResources = try ImageParser.parse(directories: config.images)
    let fileResources = try FileParser.parse(directories: config.files)

    // Warn if directories specified but no resources found
    if !config.fonts.isEmpty, fontResources.isEmpty {
        FileHandle.standardError.write("Warning: No font files (.ttf, .otf) found\n".data(using: .utf8)!)
    }
    if !config.images.isEmpty, imageResources.isEmpty {
        FileHandle.standardError.write("Warning: No image files found\n".data(using: .utf8)!)
    }
    if !config.files.isEmpty, fileResources.isEmpty {
        FileHandle.standardError.write("Warning: No files found\n".data(using: .utf8)!)
    }

    // Check for duplicates
    try DuplicateChecker.check(fonts: fontResources, category: "fonts")
    try DuplicateChecker.check(resources: imageResources, category: "images")
    try DuplicateChecker.check(resources: fileResources, category: "files")

    // Build configuration
    let emitterConfig = SwiftEmitter.Configuration(
        moduleName: config.moduleName,
        accessLevel: config.accessLevel,
        bundleOverride: config.bundle,
        registerFonts: config.registerFonts
    )

    // Generate code
    let code = SwiftEmitter.emit(
        fonts: fontResources,
        images: imageResources,
        files: fileResources,
        configuration: emitterConfig
    )

    // Output
    if let outputPath = config.output {
        try code.write(toFile: outputPath, atomically: true, encoding: .utf8)
    } else {
        print(code)
    }
}
