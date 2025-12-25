# Examples

Demonstration of SwiftResources with real resources covering all supported types.

## Resources

```
Resources/
├── Fonts/
│   ├── Lilex-Regular.ttf
│   ├── Lilex-Bold.ttf
│   └── Lilex-Italic.ttf
├── Images/
│   ├── Logo.png
│   └── Banner.png
├── Assets.xcassets/
│   ├── AppIcon.imageset/
│   ├── Colors/
│   │   ├── Primary.colorset/     # With dark mode variant
│   │   └── Secondary.colorset/
│   └── Icons/                    # Namespaced folder
│       └── Settings.imageset/
├── Data/
│   ├── config.json
│   ├── settings.plist
│   └── countries.txt
├── Localizable.xcstrings         # Strings with plurals & format args
└── Errors.xcstrings              # Second string table
```

## Generate

**With Swift:**
```bash
# From repo root
swift build
.build/debug/sr generate \
  --fonts "$PWD/examples/Resources/Fonts" \
  --images "$PWD/examples/Resources/Images" \
  --xcassets "$PWD/examples/Resources/Assets.xcassets" \
  --files "$PWD/examples/Resources/Data" \
  --strings "$PWD/examples/Resources/Localizable.xcstrings" \
  --strings "$PWD/examples/Resources/Errors.xcstrings" \
  --output "$PWD/examples/Generated.swift" \
  --module-name Example \
  --access-level public
```

**With Bazel:**
```bash
# From repo root
bazel run //:sr -- generate \
  --fonts "$PWD/examples/Resources/Fonts" \
  --images "$PWD/examples/Resources/Images" \
  --xcassets "$PWD/examples/Resources/Assets.xcassets" \
  --files "$PWD/examples/Resources/Data" \
  --strings "$PWD/examples/Resources/Localizable.xcstrings" \
  --strings "$PWD/examples/Resources/Errors.xcstrings" \
  --output "$PWD/examples/Generated.swift" \
  --module-name Example \
  --access-level public
```

## Usage Examples

### Fonts

```swift
// Fixed size
let regular = Example.fonts.lilexRegular.font(size: 14)
let bold = Example.fonts.lilexBold.uiFont(size: 16)

// Dynamic Type (scales with user's text size preference)
let scaledBody = Example.fonts.lilexRegular.font(size: 14, relativeTo: .body)
let scaledTitle = Example.fonts.lilexBold.uiFont(size: 28, relativeTo: .title1)
```

### Images

```swift
// Raw images from Images/ directory
let logo = Example.images.logo.image                 // SwiftUI
let uiLogo = Example.images.logo.uiImage             // UIKit
let banner = Example.images.banner.image

// From asset catalog (with 1x, 2x, 3x variants)
let appIcon = Example.images.appIcon.image
let uiIcon = Example.images.appIcon.uiImage

// Namespaced (from Icons/ folder with provides-namespace)
let settings = Example.images.iconsSettings.image
```

### Colors

```swift
// Primary automatically adapts to light/dark mode
let primary = Example.colors.primary.color           // SwiftUI
let uiPrimary = Example.colors.primary.uiColor       // UIKit

let secondary = Example.colors.secondary.color
```

### Files

```swift
// JSON
if let data = Example.files.config.data {
    let config = try JSONDecoder().decode(Config.self, from: data)
}

// Plist
if let url = Example.files.settings.url {
    let settings = NSDictionary(contentsOf: url)
}

// Text
if let data = Example.files.countries.data,
   let text = String(data: data, encoding: .utf8) {
    let countries = text.components(separatedBy: "\n")
}
```

### Localized Strings

```swift
// Simple string
let title = Example.strings.localizable.appTitle

// String with argument
let greeting = Example.strings.localizable.greetingPersonal("Alice")
// → "Hello, Alice!"

// Pluralized (runtime selects correct form)
let items = Example.strings.localizable.itemsCount(5)   // "5 items"
let item = Example.strings.localizable.itemsCount(1)    // "1 item"

// Multiple arguments (positional)
let progress = Example.strings.localizable.progressStatus("Alice", 3, 10)
// → "Alice completed 3 of 10 tasks"

// Formatted values
let price = Example.strings.localizable.priceFormat(29.99)
// → "Price: $29.99"

// Separate error table
let networkError = Example.strings.errors.errorNetwork
let notFound = Example.strings.errors.errorNotfound("user")
// → "The requested user could not be found."
```

## Minimal Example

Generate only fonts:

```bash
.build/debug/sr generate \
  --fonts examples/Resources/Fonts \
  --module-name Fonts
```

## Notes

- **Fonts**: Uses [Lilex](https://github.com/mishamyrt/Lilex), an open source programming font (OFL-1.1)
- **Pluralization**: Runtime automatically selects singular/plural based on count and locale
- **Dark Mode**: Colors with appearance variants adapt automatically
- **Namespaces**: Folders with `provides-namespace: true` prefix the asset name
