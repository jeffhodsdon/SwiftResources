// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a discovered arbitrary file resource (data files like .json, .plist, etc.).
struct DiscoveredResource {
    /// Filename without extension: "config"
    let name: String

    /// File extension without dot: "json"
    let `extension`: String

    /// Relative path from input directory, for error messages
    let relativePath: String
}
