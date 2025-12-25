// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a discovered image resource (from raw files or asset catalogs).
struct DiscoveredImage {
    /// Asset name used with UIImage(named:) / NSImage(named:)
    /// For raw files: filename without extension ("logo")
    /// For xcassets: folder name, possibly namespaced ("Icons/settings")
    let name: String
}
