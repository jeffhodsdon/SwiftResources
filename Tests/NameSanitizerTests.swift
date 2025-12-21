// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

@testable import SwiftResources
import Testing

@Suite("NameSanitizer")
struct NameSanitizerTests {
    @Test("Basic hyphen separation")
    func hyphenSeparation() {
        #expect(NameSanitizer.sanitize("hero-background") == "heroBackground")
    }

    @Test("Uppercase input becomes lowerCamelCase")
    func uppercaseInput() {
        #expect(NameSanitizer.sanitize("Inter-Bold") == "interBold")
    }

    @Test("Underscore separation")
    func underscoreSeparation() {
        #expect(NameSanitizer.sanitize("icon_home") == "iconHome")
    }

    @Test("Dot separation")
    func dotSeparation() {
        #expect(NameSanitizer.sanitize("icon.home.settings") == "iconHomeSettings")
    }

    @Test("Leading digit gets underscore prefix")
    func leadingDigit() {
        #expect(NameSanitizer.sanitize("2x_logo") == "_2xLogo")
    }

    @Test("Simple name unchanged")
    func simpleName() {
        #expect(NameSanitizer.sanitize("config") == "config")
    }

    @Test("Empty string returns underscore")
    func emptyString() {
        #expect(NameSanitizer.sanitize("") == "_")
    }

    @Test("Only separators returns underscore")
    func onlySeparators() {
        #expect(NameSanitizer.sanitize("---") == "_")
    }

    @Test("Mixed separators")
    func mixedSeparators() {
        #expect(NameSanitizer.sanitize("my-icon_set.large") == "myIconSetLarge")
    }

    @Test("All uppercase becomes lowercase camelCase")
    func allUppercase() {
        #expect(NameSanitizer.sanitize("HERO-BACKGROUND") == "heroBackground")
    }

    @Test("Numbers in middle preserved")
    func numbersInMiddle() {
        #expect(NameSanitizer.sanitize("icon-24px") == "icon24px")
    }

    @Test("All numeric with prefix")
    func allNumeric() {
        #expect(NameSanitizer.sanitize("123") == "_123")
    }

    // MARK: - Reserved Keyword Tests

    @Test("Reserved keyword 'class' gets backticks")
    func reservedClass() {
        #expect(NameSanitizer.sanitize("class") == "`class`")
    }

    @Test("Reserved keyword 'default' gets backticks")
    func reservedDefault() {
        #expect(NameSanitizer.sanitize("default") == "`default`")
    }

    @Test("Reserved keyword 'self' gets backticks")
    func reservedSelf() {
        #expect(NameSanitizer.sanitize("self") == "`self`")
    }

    @Test("Reserved keyword 'default' from uppercase gets backticks")
    func reservedDefaultUppercase() {
        #expect(NameSanitizer.sanitize("DEFAULT") == "`default`")
    }

    @Test("Non-reserved word unchanged")
    func nonReserved() {
        #expect(NameSanitizer.sanitize("myClass") == "myclass")
    }

    @Test("Reserved word in compound name not escaped")
    func reservedInCompound() {
        // "icon-class" becomes "iconClass" which is not a reserved word
        #expect(NameSanitizer.sanitize("icon-class") == "iconClass")
    }
}
