// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Printf-style format specifiers mapped to Swift types.
///
/// Used to generate type-safe function signatures for localized strings
/// containing format placeholders like `%@`, `%lld`, `%f`, etc.
enum StringFormatSpecifier: Equatable, Hashable, Sendable {
    /// Object/string format (`%@`) → `String`
    case string

    /// Signed integer formats (`%d`, `%i`, `%ld`, `%lld`) → `Int`
    case int

    /// Unsigned integer formats (`%u`, `%lu`, `%llu`) → `UInt`
    case uint

    /// Floating-point formats (`%f`, `%lf`, `%e`, `%g`) → `Double`
    case double

    /// Character format (`%c`) → `Character`
    case character

    /// Unrecognized specifier (fallback) → `CVarArg`
    case unknown(String)

    /// The Swift type name for this specifier, used in generated function signatures.
    var swiftType: String {
        switch self {
        case .string: "String"
        case .int: "Int"
        case .uint: "UInt"
        case .double: "Double"
        case .character: "Character"
        case .unknown: "CVarArg"
        }
    }

    /// Parses a format specifier string (without the leading `%`).
    ///
    /// Handles length modifiers (`l`, `ll`, `h`, `hh`, `z`, `j`, `t`, `L`) and
    /// common conversion specifiers.
    ///
    /// Examples:
    /// - `"@"` → `.string`
    /// - `"d"`, `"ld"`, `"lld"` → `.int`
    /// - `"u"`, `"lu"`, `"llu"` → `.uint`
    /// - `"f"`, `"lf"`, `"e"`, `"g"` → `.double`
    /// - `"c"` → `.character`
    ///
    /// - Parameter specifier: The format specifier without `%` (e.g., `"lld"`, `"@"`)
    /// - Returns: The corresponding `StringFormatSpecifier`
    static func parse(_ specifier: String) -> StringFormatSpecifier {
        // Normalize: strip any flags, width, precision that might have been included
        // We mainly care about the length modifier + conversion specifier
        let normalized = specifier.lowercased()

        switch normalized {
        // Object/String
        case "@":
            return .string

        // Signed integers (various lengths all map to Int in Swift)
        case "d",
             "hd",
             "hhd",
             "hhi",
             "hi",
             "i",
             "jd",
             "ji",
             "ld",
             "li",
             "lld",
             "lli",
             "td",
             "ti",
             "zd",
             "zi":
            return .int

        // Unsigned integers
        case "hho", // Octal
             "hhu",
             "hhx", // Hex lowercase
             "hhX", // Hex uppercase (keep original case check)
             "ho",
             "hu",
             "hx",
             "hX",
             "ju",
             "llo",
             "llu",
             "llx",
             "llX", // Octal
             "lo",
             "lu",
             "lx",
             "lX",
             "o", // Hex lowercase
             "tu",
             "u",
             "x",
             "X",
             "zu": // Hex uppercase (keep original case check)
            return .uint

        // Floating point
        case "a",
             "e",
             "f",
             "g",
             "la",
             "La",
             "le",
             "Le",
             "lf",
             "Lf",
             "lg",
             "Lg":
            return .double

        // Character
        case "c",
             "C",
             "lc":
            return .character

        // Pointer (treat as unknown since we can't easily represent in Swift)
        case "p":
            return .unknown(specifier)

        // C string (could be String but risky, treat as unknown)
        case "ls",
             "s",
             "S":
            return .unknown(specifier)

        default:
            return .unknown(specifier)
        }
    }
}
