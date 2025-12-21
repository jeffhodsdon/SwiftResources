# SwiftResources

Type-safe resource accessors for Swift. Generates code for fonts, images, and files.

## Why?

- No Xcode dependency
- No runtime dependencies
- Bazel rules included

Inspired by [R.swift](https://github.com/mac-cain13/R.swift) and [SwiftGen](https://github.com/SwiftGen/SwiftGen).

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/jeffhodsdon/SwiftResources.git", from: "0.1.0")
```

### Bazel

```python
bazel_dep(name = "swift_resources", version = "0.1.0")
git_override(
    module_name = "swift_resources",
    remote = "https://github.com/jeffhodsdon/SwiftResources.git",
    tag = "0.1.0",
)
```

## Usage

### CLI

```bash
sr generate \
  --fonts Resources/Fonts \
  --images Resources/Images \
  --files Resources/Data \
  --output Generated/Resources.swift \
  --module-name DesignSystem \
  --access-level public
```

### Bazel

```python
load("@swift_resources//swift_resources:defs.bzl", "swift_resources_library")

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
// Fonts
let font = DesignSystem.fonts.interBold.uiFont(size: 16)

// Images
let image = DesignSystem.images.logo.uiImage

// Files
let data = DesignSystem.files.config.data
```

## License

Apache 2.0
