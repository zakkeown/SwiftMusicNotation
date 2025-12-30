# Installation

Add SwiftMusicNotation to your Swift project using Swift Package Manager.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation is distributed as a Swift Package. You can add it to your project using Xcode or by editing your `Package.swift` file directly.

## Adding via Xcode

1. Open your project in Xcode
2. Select **File > Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/zakkeown/SwiftMusicNotation.git
   ```
4. Select the version rule (recommended: "Up to Next Major Version")
5. Click **Add Package**
6. Select the libraries you need:
   - **SwiftMusicNotation** - Full library (recommended for most projects)
   - Or select individual modules for more control

## Adding via Package.swift

Add SwiftMusicNotation to your package dependencies:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(
            url: "https://github.com/zakkeown/SwiftMusicNotation.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["SwiftMusicNotation"]
        )
    ]
)
```

## Choosing What to Import

### Full Library (Recommended)

For most projects, import the umbrella module to access all functionality:

```swift
import SwiftMusicNotation
```

This re-exports all modules, giving you access to:
- Score models and types
- MusicXML import/export
- Layout computation
- Rendering and views
- MIDI playback

### Individual Modules

For more control over dependencies, import only what you need:

```swift
// Just the core models
import MusicNotationCore

// MusicXML parsing only
import MusicXMLImport

// Layout without rendering
import MusicNotationLayout
```

This is useful when:
- You want to minimize binary size
- You're building a tool that only needs certain features
- You're creating a custom renderer

## Module Dependencies

The modules have these dependencies:

| Module | Depends On |
|--------|------------|
| SMuFLKit | (none) |
| MusicNotationCore | SMuFLKit |
| MusicXMLImport | MusicNotationCore, XMLCoder, ZIPFoundation |
| MusicXMLExport | MusicNotationCore, ZIPFoundation |
| MusicNotationLayout | MusicNotationCore, SMuFLKit |
| MusicNotationRenderer | MusicNotationLayout, SMuFLKit |
| MusicNotationPlayback | MusicNotationCore |

## Requirements

- **Swift**: 5.9 or later
- **Xcode**: 15.0 or later
- **macOS**: 13.0 or later (for deployment)
- **iOS**: 16.0 or later (for deployment)

## Verifying Installation

After adding the package, verify the installation:

```swift
import SwiftMusicNotation

// This should compile without errors
let importer = MusicXMLImporter()
print("SwiftMusicNotation installed successfully!")
```

## Next Steps

- Continue to <doc:QuickStart> to display your first score
