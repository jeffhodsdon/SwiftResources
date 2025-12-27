// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import SwiftResources
import Testing

// MARK: - StringFormatSpecifier Tests

@Suite("StringFormatSpecifier")
struct StringFormatSpecifierTests {
    @Test("Parses object specifier")
    func objectSpecifier() {
        #expect(StringFormatSpecifier.parse("@") == .string)
        #expect(StringFormatSpecifier.parse("@").swiftType == "String")
    }

    @Test("Parses integer specifiers")
    func integerSpecifiers() {
        #expect(StringFormatSpecifier.parse("d") == .int)
        #expect(StringFormatSpecifier.parse("i") == .int)
        #expect(StringFormatSpecifier.parse("ld") == .int)
        #expect(StringFormatSpecifier.parse("lld") == .int)
        #expect(StringFormatSpecifier.parse("d").swiftType == "Int")
    }

    @Test("Parses unsigned integer specifiers")
    func unsignedSpecifiers() {
        #expect(StringFormatSpecifier.parse("u") == .uint)
        #expect(StringFormatSpecifier.parse("lu") == .uint)
        #expect(StringFormatSpecifier.parse("llu") == .uint)
        #expect(StringFormatSpecifier.parse("x") == .uint)
        #expect(StringFormatSpecifier.parse("u").swiftType == "UInt")
    }

    @Test("Parses float specifiers")
    func floatSpecifiers() {
        #expect(StringFormatSpecifier.parse("f") == .double)
        #expect(StringFormatSpecifier.parse("lf") == .double)
        #expect(StringFormatSpecifier.parse("e") == .double)
        #expect(StringFormatSpecifier.parse("g") == .double)
        #expect(StringFormatSpecifier.parse("f").swiftType == "Double")
    }

    @Test("Parses character specifier")
    func charSpecifier() {
        #expect(StringFormatSpecifier.parse("c") == .character)
        #expect(StringFormatSpecifier.parse("c").swiftType == "Character")
    }

    @Test("Unknown specifier returns unknown case")
    func unknownSpecifier() {
        let spec = StringFormatSpecifier.parse("xyz")
        if case .unknown(let val) = spec {
            #expect(val == "xyz")
        } else {
            Issue.record("Expected unknown case")
        }
        #expect(spec.swiftType == "CVarArg")
    }
}

// MARK: - FormatStringParser Tests

@Suite("FormatStringParser")
struct FormatStringParserTests {
    @Test("Parses simple format string")
    func simpleFormat() {
        let args = FormatStringParser.parse("Hello, %@!")
        #expect(args.count == 1)
        #expect(args[0].position == 1)
        #expect(args[0].specifier == .string)
    }

    @Test("Parses multiple format specifiers")
    func multipleFormats() {
        let args = FormatStringParser.parse("%@ has %lld items")
        #expect(args.count == 2)
        #expect(args[0].specifier == .string)
        #expect(args[1].specifier == .int)
    }

    @Test("Parses positional format specifiers")
    func positionalFormats() {
        let args = FormatStringParser.parse("%2$lld of %1$@")
        #expect(args.count == 2)
        #expect(args[0].position == 1)
        #expect(args[0].specifier == .string)
        #expect(args[1].position == 2)
        #expect(args[1].specifier == .int)
    }

    @Test("Ignores escaped percent")
    func escapedPercent() {
        let args = FormatStringParser.parse("100%% complete")
        #expect(args.isEmpty)
    }

    @Test("Returns empty for plain string")
    func plainString() {
        let args = FormatStringParser.parse("Hello, World!")
        #expect(args.isEmpty)
    }

    @Test("Handles float specifier")
    func floatFormat() {
        let args = FormatStringParser.parse("Price: $%.2f")
        #expect(args.count == 1)
        #expect(args[0].specifier == .double)
    }
}

// MARK: - StringIdentifierGenerator Tests

@Suite("StringIdentifierGenerator")
struct StringIdentifierGeneratorTests {
    @Test("Generates identifier from simple key")
    func simpleKey() {
        let string = DiscoveredString(
            key: "welcome.title",
            tableName: "Localizable",
            defaultValue: "Welcome",
            relativePath: "test.xcstrings"
        )
        let id = StringIdentifierGenerator.generateIdentifier(for: string)
        #expect(id == "welcomeTitle")
    }

    @Test("Generates identifier from format key")
    func formatKey() {
        let string = DiscoveredString(
            key: "%lld items",
            tableName: "Localizable",
            defaultValue: "%lld items",
            arguments: [StringFormatArgument(position: 1, specifier: .int)],
            relativePath: "test.xcstrings"
        )
        let id = StringIdentifierGenerator.generateIdentifier(for: string)
        #expect(id == "items")
    }

    @Test("Generates parameter labels")
    func parameterLabels() {
        let string = DiscoveredString(
            key: "greeting",
            tableName: "Localizable",
            defaultValue: "Hello, %@!",
            arguments: [StringFormatArgument(position: 1, specifier: .string)],
            relativePath: "test.xcstrings"
        )
        let labels = StringIdentifierGenerator.generateParameterLabels(for: string)
        #expect(labels.count == 1)
        #expect(labels[0] == "value")
    }

    @Test("Uses explicit label from substitution")
    func explicitLabel() {
        let string = DiscoveredString(
            key: "items.count",
            tableName: "Localizable",
            defaultValue: "%lld items",
            arguments: [StringFormatArgument(
                position: 1,
                specifier: .int,
                label: "count"
            )],
            relativePath: "test.xcstrings"
        )
        let labels = StringIdentifierGenerator.generateParameterLabels(for: string)
        #expect(labels.count == 1)
        #expect(labels[0] == "count")
    }
}

// MARK: - StringCatalogParser Tests

@Suite("StringCatalogParser")
struct StringCatalogParserTests {
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

    @Test("Parses simple xcstrings file")
    func simpleXcstrings() throws {
        let xcstrings = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {
            "hello": {
              "localizations": {
                "en": {
                  "stringUnit": {
                    "state": "translated",
                    "value": "Hello"
                  }
                }
              }
            }
          }
        }
        """

        let file = tempDir.appendingPathComponent("Test.xcstrings")
        try xcstrings.write(to: file, atomically: true, encoding: .utf8)

        let result = try StringCatalogParser.parse(file: file.path)
        #expect(result.sourceLanguage == "en")
        #expect(result.tableName == "Test")
        #expect(result.strings.count == 1)
        #expect(result.strings[0].key == "hello")
        #expect(result.strings[0].defaultValue == "Hello")
    }

    @Test("Parses string with format specifier")
    func formatString() throws {
        let xcstrings = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {
            "greeting": {
              "localizations": {
                "en": {
                  "stringUnit": {
                    "state": "translated",
                    "value": "Hello, %@!"
                  }
                }
              }
            }
          }
        }
        """

        let file = tempDir.appendingPathComponent("Localizable.xcstrings")
        try xcstrings.write(to: file, atomically: true, encoding: .utf8)

        let result = try StringCatalogParser.parse(file: file.path)
        #expect(result.strings.count == 1)
        #expect(result.strings[0].arguments.count == 1)
        #expect(result.strings[0].arguments[0].specifier == .string)
    }

    @Test("Parses plural variations")
    func pluralVariations() throws {
        let xcstrings = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {
            "items": {
              "localizations": {
                "en": {
                  "variations": {
                    "plural": {
                      "one": {
                        "stringUnit": {
                          "state": "translated",
                          "value": "%lld item"
                        }
                      },
                      "other": {
                        "stringUnit": {
                          "state": "translated",
                          "value": "%lld items"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """

        let file = tempDir.appendingPathComponent("Plural.xcstrings")
        try xcstrings.write(to: file, atomically: true, encoding: .utf8)

        let result = try StringCatalogParser.parse(file: file.path)
        #expect(result.strings.count == 1)
        #expect(result.strings[0].arguments.count == 1)
        #expect(result.strings[0].arguments[0].specifier == .int)
    }

    @Test("Extracts comment from entry")
    func extractsComment() throws {
        let xcstrings = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {
            "title": {
              "comment": "Main screen title",
              "localizations": {
                "en": {
                  "stringUnit": {
                    "state": "translated",
                    "value": "Welcome"
                  }
                }
              }
            }
          }
        }
        """

        let file = tempDir.appendingPathComponent("Comments.xcstrings")
        try xcstrings.write(to: file, atomically: true, encoding: .utf8)

        let result = try StringCatalogParser.parse(file: file.path)
        #expect(result.strings[0].comment == "Main screen title")
    }

    @Test("Throws for missing file")
    func missingFile() {
        #expect(throws: StringCatalogParser.ParseError.self) {
            _ = try StringCatalogParser.parse(file: "/nonexistent.xcstrings")
        }
    }
}

// MARK: - String Emitter Tests

@Suite("SwiftEmitter Strings")
struct SwiftEmitterStringTests {
    func makeConfig(
        moduleName: String = "Resources",
        accessLevel: String = "internal",
        bundle: String? = nil
    ) -> SwiftEmitter.Configuration {
        SwiftEmitter.Configuration(
            moduleName: moduleName,
            accessLevel: accessLevel,
            bundleOverride: bundle,
            registerFonts: false,
            forceUnwrap: false
        )
    }

    @Test("Generates simple string property")
    func simpleStringProperty() {
        let strings: [String: [DiscoveredString]] = [
            "Localizable": [
                DiscoveredString(
                    key: "hello",
                    tableName: "Localizable",
                    defaultValue: "Hello",
                    relativePath: "test.xcstrings"
                ),
            ],
        ]

        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            strings: strings,
            configuration: makeConfig()
        )

        #expect(output.contains("enum strings"))
        #expect(output.contains("enum localizable"))
        #expect(output.contains("static var hello: String"))
        #expect(output.contains("localizedString(forKey: \"hello\""))
    }

    @Test("Generates string function with argument")
    func stringFunction() {
        let strings: [String: [DiscoveredString]] = [
            "Localizable": [
                DiscoveredString(
                    key: "greeting",
                    tableName: "Localizable",
                    defaultValue: "Hello, %@!",
                    arguments: [StringFormatArgument(position: 1, specifier: .string)],
                    relativePath: "test.xcstrings"
                ),
            ],
        ]

        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            strings: strings,
            configuration: makeConfig()
        )

        #expect(output.contains("static func greeting(_ value: String) -> String"))
        #expect(output.contains("String(format:"))
    }

    @Test("Generates multiple tables as nested enums")
    func multipleTables() {
        let strings: [String: [DiscoveredString]] = [
            "Localizable": [
                DiscoveredString(
                    key: "hello",
                    tableName: "Localizable",
                    defaultValue: "Hello",
                    relativePath: "test.xcstrings"
                ),
            ],
            "Errors": [
                DiscoveredString(
                    key: "network",
                    tableName: "Errors",
                    defaultValue: "Network error",
                    relativePath: "errors.xcstrings"
                ),
            ],
        ]

        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            strings: strings,
            configuration: makeConfig()
        )

        #expect(output.contains("enum localizable"))
        #expect(output.contains("enum errors"))
    }

    @Test("Escapes special characters in string literals")
    func escapesSpecialChars() {
        let strings: [String: [DiscoveredString]] = [
            "Localizable": [
                DiscoveredString(
                    key: "quote",
                    tableName: "Localizable",
                    defaultValue: "He said \"Hello\"",
                    relativePath: "test.xcstrings"
                ),
            ],
        ]

        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            strings: strings,
            configuration: makeConfig()
        )

        #expect(output.contains("\\\"Hello\\\""))
    }

    @Test("Public access level applied to strings")
    func publicAccessLevel() {
        let strings: [String: [DiscoveredString]] = [
            "Localizable": [
                DiscoveredString(
                    key: "hello",
                    tableName: "Localizable",
                    defaultValue: "Hello",
                    relativePath: "test.xcstrings"
                ),
            ],
        ]

        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            strings: strings,
            configuration: makeConfig(accessLevel: "public")
        )

        #expect(output.contains("public enum strings"))
        #expect(output.contains("public static var hello"))
    }
}
