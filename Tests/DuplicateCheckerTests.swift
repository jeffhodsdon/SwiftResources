// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

@testable import SwiftResources
import Testing

@Suite("DuplicateChecker")
struct DuplicateCheckerTests {
    @Test("No duplicates passes without error")
    func noDuplicates() throws {
        let resources = [
            DiscoveredResource(
                name: "icon-home",
                extension: "png",
                relativePath: "icon-home.png"
            ),
            DiscoveredResource(
                name: "icon-settings",
                extension: "png",
                relativePath: "icon-settings.png"
            ),
            DiscoveredResource(name: "logo", extension: "png", relativePath: "logo.png"),
        ]

        // Should not throw
        try DuplicateChecker.check(resources: resources, category: "images")
    }

    @Test("Single duplicate is detected")
    func singleDuplicate() throws {
        let resources = [
            DiscoveredResource(
                name: "icon-home",
                extension: "png",
                relativePath: "icon-home.png"
            ),
            DiscoveredResource(
                name: "icon_home",
                extension: "png",
                relativePath: "icon_home.png"
            ),
        ]

        #expect(throws: DuplicateChecker.DuplicateError.self) {
            try DuplicateChecker.check(resources: resources, category: "images")
        }
    }

    @Test("Duplicate error contains correct identifier")
    func duplicateErrorIdentifier() {
        let resources = [
            DiscoveredResource(
                name: "hero-background",
                extension: "png",
                relativePath: "hero-background.png"
            ),
            DiscoveredResource(
                name: "hero_background",
                extension: "png",
                relativePath: "hero_background.png"
            ),
        ]

        do {
            try DuplicateChecker.check(resources: resources, category: "images")
            Issue.record("Expected error to be thrown")
        } catch let error as DuplicateChecker.DuplicateError {
            #expect(error.identifier == "heroBackground")
            #expect(error.category == "images")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Duplicate error lists all conflicting paths")
    func duplicateErrorPaths() {
        let resources = [
            DiscoveredResource(
                name: "icon-home",
                extension: "png",
                relativePath: "Icons/icon-home.png"
            ),
            DiscoveredResource(
                name: "icon_home",
                extension: "png",
                relativePath: "Legacy/icon_home.png"
            ),
        ]

        do {
            try DuplicateChecker.check(resources: resources, category: "images")
            Issue.record("Expected error to be thrown")
        } catch let error as DuplicateChecker.DuplicateError {
            #expect(error.conflictingPaths.count == 2)
            #expect(error.conflictingPaths.contains("Icons/icon-home.png"))
            #expect(error.conflictingPaths.contains("Legacy/icon_home.png"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Error description is formatted correctly")
    func errorDescription() {
        let resources = [
            DiscoveredResource(
                name: "icon-home",
                extension: "png",
                relativePath: "icon-home.png"
            ),
            DiscoveredResource(
                name: "icon_home",
                extension: "png",
                relativePath: "icon_home.png"
            ),
        ]

        do {
            try DuplicateChecker.check(resources: resources, category: "images")
            Issue.record("Expected error to be thrown")
        } catch let error as DuplicateChecker.DuplicateError {
            let description = error.description
            #expect(description.contains("Duplicate identifier 'iconHome' for images:"))
            #expect(description.contains("icon-home.png"))
            #expect(description.contains("icon_home.png"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Empty resources passes")
    func emptyResources() throws {
        try DuplicateChecker.check(resources: [], category: "fonts")
    }

    @Test("Single resource passes")
    func singleResource() throws {
        let resources = [
            DiscoveredResource(name: "logo", extension: "png", relativePath: "logo.png"),
        ]

        try DuplicateChecker.check(resources: resources, category: "images")
    }

    @Test("Different extensions same name are duplicates")
    func differentExtensionsSameName() throws {
        // icon-home.png and icon-home.jpg both sanitize to "iconHome"
        // This is actually not a duplicate since the names are the same
        // but with different extensions, they're separate resources
        // Wait, no - DiscoveredResource.name is the filename without extension
        // So both would have name="icon-home" which isn't a duplicate issue per se
        // Let me test same sanitized name from different original names
        let resources = [
            DiscoveredResource(
                name: "Config",
                extension: "json",
                relativePath: "Config.json"
            ),
            DiscoveredResource(
                name: "config",
                extension: "xml",
                relativePath: "config.xml"
            ),
        ]

        // Both sanitize to "config", so this should be a duplicate
        #expect(throws: DuplicateChecker.DuplicateError.self) {
            try DuplicateChecker.check(resources: resources, category: "files")
        }
    }
}
