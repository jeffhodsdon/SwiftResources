// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a discovered color resource (from asset catalogs).
struct DiscoveredColor {
    /// Asset name used with UIColor(named:) / NSColor(named:)
    /// Possibly namespaced ("Brand/Primary")
    let name: String
}
