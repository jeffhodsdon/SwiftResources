# SwiftResources

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Bazel](https://img.shields.io/badge/Bazel-7.x%20%7C%208.x-43A047)](https://bazel.build)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138)](https://swift.org)

Type-safe resource accessors for Swift. Zero dependencies with a Bazel ruleset included.

## Why?

- **Xcode independent** — Works with Bazel, SPM, or CLI
- **No dependencies** — During runtime or generation
- **Bazel support** — `swift_resources_library` rule
- **Cross-platform** — Accessors for UIKit, AppKit, and SwiftUI

Inspired by [R.swift](https://github.com/mac-cain13/R.swift) and [SwiftGen](https://github.com/SwiftGen/SwiftGen)

## Supported Resource Types

Generated code uses `Resources` as the default namespace (change via `--module-name`).

### Fonts

**Input:** `.ttf`, `.otf`

```swift
// Fixed size
let font = Resources.fonts.lilexBold.font(size: 16)         // SwiftUI
let uiFont = Resources.fonts.lilexBold.uiFont(size: 16)     // UIKit
let nsFont = Resources.fonts.lilexBold.nsFont(size: 16)     // AppKit

// Dynamic Type
let scaledFont = Resources.fonts.lilexBold.font(size: 16, relativeTo: .body)
let scaledUIFont = Resources.fonts.lilexBold.uiFont(size: 28, relativeTo: .title1)
```

### Images

**Input:** `.png`, `.jpg`, `.jpeg`, `.pdf`, `.svg`, `.heic`, or imagesets from `.xcassets`

```swift
let image = Resources.images.logo.image                     // SwiftUI
let uiImage = Resources.images.logo.uiImage                 // UIKit
let nsImage = Resources.images.logo.nsImage                 // AppKit
```

### Colors

**Input:** colorsets from `.xcassets`

```swift
let color = Resources.colors.primary.color                  // SwiftUI
let uiColor = Resources.colors.primary.uiColor              // UIKit
let nsColor = Resources.colors.primary.nsColor              // AppKit
```

### Files

**Input:** any file type (`.json`, `.plist`, `.xml`, `.txt`, etc.)

```swift
let url = Resources.files.config.url                        // URL?
let data = Resources.files.config.data                      // Data?
```

### Localized Strings

**Input:** `.xcstrings` or `.strings`

```swift
let title = Resources.strings.localizable.welcomeTitle      // Simple string
let msg = Resources.strings.localizable.greeting("World")   // With argument
let items = Resources.strings.localizable.itemsCount(5)     // Pluralized
```

## Requirements

- **Swift** 5.9+
- **macOS** 13+ (for CLI font name extraction via CoreText)
- **Bazel** 7.x or 8.x (for Bazel rules)

## Installation

### Bazel (BCR)

```python
bazel_dep(name = "rules_swift_resources", version = "0.1.0")
```

### Swift Package Manager

```swift
.package(url: "https://github.com/jeffhodsdon/SwiftResources.git", from: "0.1.0")
```

## Usage

### CLI

**Swift:**
```bash
swift build
.build/debug/sr generate --help
```

**Bazel:**
```bash
bazel run //:sr -- generate --help
```

**Example:**
```bash
sr generate \
  --fonts Resources/Fonts \
  --images Resources/Images \
  --xcassets Resources/Assets.xcassets \
  --files Resources/Data \
  --strings Resources/Localizable.xcstrings \
  --output Generated/Resources.swift \
  --module-name DesignSystem \
  --access-level public
```

#### CLI Options

| Flag | Default | Description |
|------|---------|-------------|
| `--fonts <dir>` | — | Directories containing .ttf/.otf files (repeatable) |
| `--images <dir>` | — | Directories containing image files (repeatable) |
| `--xcassets <dir>` | — | Asset catalog directories (.xcassets) (repeatable) |
| `--files <dir>` | — | Directories containing data files (repeatable) |
| `--strings <path>` | — | String catalog (.xcstrings) or .strings files (repeatable) |
| `--development-region <lang>` | — | Source language for .strings files (auto-detected for .xcstrings) |
| `--output <path>` | stdout | Output Swift file path |
| `--module-name <name>` | `Resources` | Generated enum namespace |
| `--access-level <level>` | `internal` | `public` or `internal` |
| `--bundle <expr>` | BundleFinder | Bundle expression (`.module`, `.main`, or custom) |
| `--no-register-fonts` | — | Disable font registration code generation |

### Bazel

```python
load("@rules_swift_resources//rules_swift_resources:defs.bzl", "swift_resources_library")

swift_resources_library(
    name = "DesignSystemResources",
    fonts = glob(["Fonts/**/*.ttf"]),
    images = glob(["Images/**/*.png"]),
    xcassets = glob(["Assets.xcassets/**"]),
    strings = ["Localizable.xcstrings"],
    module_name = "DesignSystem",
)
```

**Note:** `swift_resources_library` generates a `swift_library` with type-safe accessors—it does not bundle the resource files. Add resources to your `ios_application` or bundle rule separately. This allows you to use resources with type safety in static libraries.

## License

Apache 2.0
