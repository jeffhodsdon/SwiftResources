// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a discovered font file with its PostScript name extracted via Core Text.
struct DiscoveredFont {
    /// The PostScript name of the font (e.g., "Inter-Bold"), used for UIFont/NSFont
    /// loading.
    let postScriptName: String

    /// The filename without extension (e.g., "Inter-Bold"), used for file lookup.
    let fileName: String

    /// The file extension (e.g., "ttf"), used for file lookup during registration.
    let fileExtension: String

    /// Relative path from input directory, for error messages.
    let relativePath: String
}
