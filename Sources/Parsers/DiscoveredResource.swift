// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a discovered resource file (font, image, or arbitrary file).
struct DiscoveredResource {
    /// Filename without extension: "Inter-Bold"
    let name: String

    /// File extension without dot: "ttf"
    let `extension`: String

    /// Relative path from input directory, for error messages
    let relativePath: String
}
