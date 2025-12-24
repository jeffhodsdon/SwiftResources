# SwiftResources

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Bazel](https://img.shields.io/badge/Bazel-7.x%20%7C%208.x-43A047)](https://bazel.build)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138)](https://swift.org)

Type-safe resource accessors for Swift. Zero dependencies and Bazel rules included.

## Why?

- **Use without Xcode** — Works with Bazel, SPM, or any build system
- **No runtime dependencies** — Generated code is pure Swift
- **Bazel support** — With `rules_swift`, create `swift_resources_library` rules
- **Cross-platform output** — Generated code supports UIKit, AppKit, and SwiftUI

Inspired by [R.swift](https://github.com/mac-cain13/R.swift) and [SwiftGen](https://github.com/SwiftGen/SwiftGen), but designed for Bazel-first workflows without Xcode project file dependencies.

## Supported Resource Types

| Resource Type | SwiftResources | R.swift | SwiftGen |
|---------------|:--------------:|:-------:|:--------:|
| **Fonts** (.ttf, .otf) | ✅ | ✅ | ✅ |
| **Images** (.png, .jpg, .jpeg, .pdf, .svg, .heic) | ✅ | ✅ | ✅ |
| **Data Files** (.json, .plist, .xml, .txt, etc.) | ✅ | ✅ | ✅ |
| **Asset Catalogs** (.xcassets) | ✅ | ✅ | ✅ |
| **Colors** (from .xcassets) | ✅ | ✅ | ✅ |
| **Localized Strings** (.strings) | ❌ | ✅ | ✅ |
| **Storyboards** | ❌ | ✅ | ✅ |
| **Nibs/XIBs** | ❌ | ✅ | ✅ |
| **Segues** | ❌ | ✅ | ❌ |
| **Reusable Cells** | ❌ | ✅ | ❌ |
| **Core Data Models** | ❌ | ❌ | ✅ |
| **Plists** | ❌ | ✅ | ✅ |
| **Info.plist** | ❌ | ✅ | ❌ |
| **Entitlements** | ❌ | ✅ | ❌ |

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

```bash
sr generate \
  --fonts Resources/Fonts \
  --images Resources/Images \
  --xcassets Resources/Assets.xcassets \
  --files Resources/Data \
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
    module_name = "DesignSystem",
)
```

**Note:** `swift_resources_library` generates a `swift_library` with type-safe accessors—it does not bundle the resource files. Add resources to your `ios_application` or bundle rule separately. This allows you to use resources with type safety in static libraries.

### Generated Code

```swift
// Fonts — automatically registered on first access
let uiFont = DesignSystem.fonts.interBold.uiFont(size: 16)     // UIKit
let nsFont = DesignSystem.fonts.interBold.nsFont(size: 16)     // AppKit
let font = DesignSystem.fonts.interBold.font(size: 16)         // SwiftUI

// Images (raw files + xcassets merged)
let uiImage = DesignSystem.images.logo.uiImage                 // UIKit
let nsImage = DesignSystem.images.logo.nsImage                 // AppKit
let image = DesignSystem.images.logo.image                     // SwiftUI

// Colors (from xcassets)
let uiColor = DesignSystem.colors.primary.uiColor              // UIKit
let nsColor = DesignSystem.colors.primary.nsColor              // AppKit
let color = DesignSystem.colors.primary.color                  // SwiftUI

// Files
let url = DesignSystem.files.config.url
let data = DesignSystem.files.config.data
```

## License

Apache 2.0
