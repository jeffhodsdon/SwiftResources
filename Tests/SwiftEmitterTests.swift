// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

@testable import SwiftResources
import Testing

@Suite("SwiftEmitter")
struct SwiftEmitterTests {
    // MARK: - Test Data

    let sampleFonts = [
        DiscoveredFont(
            postScriptName: "Inter-Bold",
            fileName: "Inter-Bold",
            fileExtension: "ttf",
            relativePath: "Inter-Bold.ttf"
        ),
        DiscoveredFont(
            postScriptName: "Inter-Regular",
            fileName: "Inter-Regular",
            fileExtension: "ttf",
            relativePath: "Inter-Regular.ttf"
        ),
    ]

    let sampleImages = [
        DiscoveredImage(name: "logo"),
        DiscoveredImage(name: "hero-background"),
    ]

    let sampleFiles = [
        DiscoveredResource(
            name: "config",
            extension: "json",
            relativePath: "config.json"
        ),
    ]

    let sampleColors = [
        DiscoveredColor(name: "primary"),
        DiscoveredColor(name: "secondary"),
    ]

    func makeConfig(
        moduleName: String = "Resources",
        accessLevel: String = "internal",
        bundleOverride: String? = nil,
        registerFonts: Bool = true,
        forceUnwrap: Bool = false
    ) -> SwiftEmitter.Configuration {
        SwiftEmitter.Configuration(
            moduleName: moduleName,
            accessLevel: accessLevel,
            bundleOverride: bundleOverride,
            registerFonts: registerFonts,
            forceUnwrap: forceUnwrap
        )
    }

    // MARK: - Multi-Framework Tests

    @Test("Generates all framework imports with canImport")
    func multiFrameworkImports() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("import Foundation"))
        #expect(output.contains("#if canImport(UIKit)"))
        #expect(output.contains("import UIKit"))
        #expect(output.contains("#if canImport(AppKit)"))
        #expect(output.contains("import AppKit"))
        #expect(output.contains("#if canImport(SwiftUI)"))
        #expect(output.contains("import SwiftUI"))
    }

    @Test("Generates all framework accessors for fonts")
    func multiFrameworkFontAccessors() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output
            .contains(
                "func uiFont(size: CGFloat, relativeTo textStyle: UIFont.TextStyle? = nil) -> UIFont?"
            ))
        #expect(output.contains("func nsFont(size: CGFloat) -> NSFont?"))
        #expect(output
            .contains(
                "func font(size: CGFloat, relativeTo textStyle: Font.TextStyle? = nil) -> Font"
            ))
    }

    @Test("Generates all framework accessors for images")
    func multiFrameworkImageAccessors() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("var uiImage: UIImage?"))
        #expect(output.contains("var nsImage: NSImage?"))
        #expect(output.contains("var image: Image"))
    }

    // MARK: - BundleFinder Tests

    @Test("Generates BundleFinder with fallback pattern when no bundle override")
    func bundleFinderGenerated() {
        let config = makeConfig(bundleOverride: nil)
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        // Check BundleFinder class with fallback pattern
        #expect(output.contains("private final class BundleFinder {"))
        #expect(output.contains("static let resourceBundle: Bundle"))

        // Check SWIFT_PACKAGE conditional for Bundle.module
        #expect(output.contains("#if SWIFT_PACKAGE"))
        #expect(output.contains("return Bundle.module"))
        #expect(output.contains("#else"))

        // Check fallback candidates
        #expect(output.contains("let bundleName = \"Resources_Resources\""))
        #expect(output.contains("Bundle.main.resourceURL"))
        #expect(output.contains("bundleResourceURL"))
        #expect(output.contains("Bundle(for: BundleFinder.self)"))
        #expect(output.contains("#endif"))

        // Check that enum uses BundleFinder.resourceBundle
        #expect(output.contains("private static let bundle = BundleFinder.resourceBundle"))
    }

    @Test("No BundleFinder when bundle override specified")
    func bundleOverrideNoBundleFinder() {
        let config = makeConfig(bundleOverride: ".module")
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(!output.contains("BundleFinder"))
        #expect(output.contains("bundle: Bundle.module"))
    }

    @Test("Custom bundle expression used")
    func customBundleExpression() {
        let config = makeConfig(bundleOverride: "Bundle.myCustomBundle")
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("bundle: Bundle.myCustomBundle"))
    }

    // MARK: - Sendable/Hashable Tests

    @Test("FontResource has Sendable and Hashable")
    func fontResourceProtocols() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("struct FontResource: Sendable, Hashable"))
    }

    @Test("ImageResource has Sendable and Hashable")
    func imageResourceProtocols() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("struct ImageResource: Sendable, Hashable"))
    }

    @Test("FileResource has Sendable and Hashable")
    func fileResourceProtocols() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: sampleFiles,
            configuration: config
        )

        #expect(output.contains("struct FileResource: Sendable, Hashable"))
    }

    // MARK: - Optional Return Tests

    @Test("UIFont returns optional")
    func uiFontReturnsOptional() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("-> UIFont?"))
        #expect(!output.contains("UIFont(name: fontName, size: size)!"))
    }

    @Test("UIImage returns optional")
    func uiImageReturnsOptional() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains(": UIImage?"))
        #expect(!output.contains("UIImage(named: name, in: bundle, with: nil)!"))
    }

    @Test("FileResource url and data return optionals")
    func fileResourceReturnsOptional() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: sampleFiles,
            configuration: config
        )

        #expect(output.contains("var url: URL?"))
        #expect(output.contains("var data: Data?"))
    }

    // MARK: - Access Level Tests

    @Test("Public access level adds public keyword")
    func publicAccess() {
        let config = makeConfig(accessLevel: "public")
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("public enum Resources"))
        #expect(output.contains("public struct FontResource"))
        #expect(output.contains("public static var interBold"))
    }

    @Test("Internal access level omits access keyword")
    func internalAccess() {
        let config = makeConfig(accessLevel: "internal")
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("enum Resources {"))
        #expect(output.contains("struct FontResource:"))
        #expect(!output.contains("public enum"))
    }

    // MARK: - Module Name Tests

    @Test("Custom module name is used")
    func customModuleName() {
        let config = makeConfig(moduleName: "DesignSystem")
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("enum DesignSystem {"))
        #expect(output.contains("// DesignSystem.swift"))
    }

    // MARK: - registerFonts Tests

    @Test("registerFonts enabled generates function")
    func registerFontsEnabled() {
        let config = makeConfig(registerFonts: true)
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("static func registerFonts()"))
        #expect(output.contains("CTFontManagerRegisterFontsForURL"))
    }

    @Test("registerFonts disabled omits function")
    func registerFontsDisabled() {
        let config = makeConfig(registerFonts: false)
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(!output.contains("registerFonts"))
    }

    @Test("registerFonts with no fonts omits function")
    func registerFontsNoFonts() {
        let config = makeConfig(registerFonts: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(!output.contains("registerFonts"))
    }

    // MARK: - Property Naming Tests

    @Test("FontResource uses fontName property")
    func fontNameProperty() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("let fontName: String"))
        #expect(output.contains("fontName: \"Inter-Bold\""))
    }

    @Test("FileResource uses fileExtension property")
    func fileExtensionProperty() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: sampleFiles,
            configuration: config
        )

        #expect(output.contains("let fileExtension: String"))
        #expect(output.contains("fileExtension: \"json\""))
    }

    // MARK: - Empty Resources Tests

    @Test("Empty resources generates minimal output")
    func emptyResources() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("enum Resources {"))
        #expect(output.contains("}"))
        #expect(!output.contains("struct FontResource"))
        #expect(!output.contains("struct ImageResource"))
        #expect(!output.contains("struct FileResource"))
    }

    // MARK: - Mixed Resources Tests

    @Test("Mixed resources generates all sections")
    func mixedResources() {
        let config = makeConfig()
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: sampleImages,
            colors: [],
            files: sampleFiles,
            configuration: config
        )

        #expect(output.contains("struct FontResource"))
        #expect(output.contains("struct ImageResource"))
        #expect(output.contains("struct FileResource"))
        #expect(output.contains("enum fonts {"))
        #expect(output.contains("enum images {"))
        #expect(output.contains("enum files {"))
    }

    // MARK: - Force Unwrap Tests

    @Test("Force unwrap generates non-optional UIFont")
    func forceUnwrapUIFont() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("-> UIFont {"))
        #expect(!output.contains("-> UIFont?"))
        #expect(output.contains("UIFont(name: fontName, size: size)!"))
    }

    @Test("Force unwrap generates non-optional NSFont")
    func forceUnwrapNSFont() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: sampleFonts,
            images: [],
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("-> NSFont {"))
        #expect(!output.contains("-> NSFont?"))
        #expect(output.contains("NSFont(name: fontName, size: size)!"))
    }

    @Test("Force unwrap generates non-optional UIImage")
    func forceUnwrapUIImage() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("var uiImage: UIImage {"))
        #expect(!output.contains("var uiImage: UIImage?"))
        #expect(output.contains("UIImage(named: name, in: bundle, with: nil)!"))
    }

    @Test("Force unwrap generates non-optional NSImage")
    func forceUnwrapNSImage() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: sampleImages,
            colors: [],
            files: [],
            configuration: config
        )

        #expect(output.contains("var nsImage: NSImage {"))
        #expect(!output.contains("var nsImage: NSImage?"))
        #expect(output.contains("bundle.image(forResource: name)!"))
    }

    @Test("Force unwrap generates non-optional UIColor")
    func forceUnwrapUIColor() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: sampleColors,
            files: [],
            configuration: config
        )

        #expect(output.contains("var uiColor: UIColor {"))
        #expect(!output.contains("var uiColor: UIColor?"))
        #expect(output.contains("UIColor(named: name, in: bundle, compatibleWith: nil)!"))
    }

    @Test("Force unwrap generates non-optional NSColor")
    func forceUnwrapNSColor() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: sampleColors,
            files: [],
            configuration: config
        )

        #expect(output.contains("var nsColor: NSColor {"))
        #expect(!output.contains("var nsColor: NSColor?"))
        #expect(output.contains("NSColor(named: name, bundle: bundle)!"))
    }

    @Test("Force unwrap generates non-optional FileResource url and data")
    func forceUnwrapFileResource() {
        let config = makeConfig(forceUnwrap: true)
        let output = SwiftEmitter.emit(
            fonts: [],
            images: [],
            colors: [],
            files: sampleFiles,
            configuration: config
        )

        #expect(output.contains("var url: URL {"))
        #expect(!output.contains("var url: URL?"))
        #expect(output
            .contains("bundle.url(forResource: name, withExtension: fileExtension)!"))
        #expect(output.contains("var data: Data {"))
        #expect(!output.contains("var data: Data?"))
        #expect(output.contains("try! Data(contentsOf: url)"))
    }
}
