// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftMusicNotation",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        // Main library combining all modules
        .library(
            name: "SwiftMusicNotation",
            targets: ["SwiftMusicNotation"]
        ),
        // Individual modules for selective imports
        .library(
            name: "MusicNotationCore",
            targets: ["MusicNotationCore"]
        ),
        .library(
            name: "SMuFLKit",
            targets: ["SMuFLKit"]
        ),
        .library(
            name: "MusicXMLImport",
            targets: ["MusicXMLImport"]
        ),
        .library(
            name: "MusicXMLExport",
            targets: ["MusicXMLExport"]
        ),
        .library(
            name: "MusicNotationLayout",
            targets: ["MusicNotationLayout"]
        ),
        .library(
            name: "MusicNotationRenderer",
            targets: ["MusicNotationRenderer"]
        ),
        .library(
            name: "MusicNotationPlayback",
            targets: ["MusicNotationPlayback"]
        ),
        .library(
            name: "MIDIImport",
            targets: ["MIDIImport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // MARK: - Core Data Model
        .target(
            name: "MusicNotationCore",
            dependencies: ["SMuFLKit"],
            path: "Sources/MusicNotationCore"
        ),

        // MARK: - SMuFL Font Integration
        .target(
            name: "SMuFLKit",
            dependencies: [],
            path: "Sources/SMuFLKit",
            resources: [
                .copy("Resources/glyphnames.json"),
                .copy("Resources/ranges.json"),
                .copy("Resources/Fonts")
            ]
        ),

        // MARK: - MusicXML Import
        .target(
            name: "MusicXMLImport",
            dependencies: [
                "MusicNotationCore",
                .product(name: "XMLCoder", package: "XMLCoder"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "Sources/MusicXMLImport"
        ),

        // MARK: - MusicXML Export
        .target(
            name: "MusicXMLExport",
            dependencies: [
                "MusicNotationCore",
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "Sources/MusicXMLExport"
        ),

        // MARK: - Layout Engine
        .target(
            name: "MusicNotationLayout",
            dependencies: [
                "MusicNotationCore",
                "SMuFLKit"
            ],
            path: "Sources/MusicNotationLayout"
        ),

        // MARK: - Core Graphics Renderer
        .target(
            name: "MusicNotationRenderer",
            dependencies: [
                "MusicNotationCore",
                "MusicNotationLayout",
                "SMuFLKit"
            ],
            path: "Sources/MusicNotationRenderer"
        ),

        // MARK: - Audio Playback
        .target(
            name: "MusicNotationPlayback",
            dependencies: ["MusicNotationCore"],
            path: "Sources/MusicNotationPlayback"
        ),

        // MARK: - MIDI Import
        .target(
            name: "MIDIImport",
            dependencies: ["MusicNotationCore"],
            path: "Sources/MIDIImport"
        ),

        // MARK: - Umbrella Target
        .target(
            name: "SwiftMusicNotation",
            dependencies: [
                "MusicNotationCore",
                "SMuFLKit",
                "MusicXMLImport",
                "MusicXMLExport",
                "MusicNotationLayout",
                "MusicNotationRenderer",
                "MusicNotationPlayback",
                "MIDIImport"
            ],
            path: "Sources/SwiftMusicNotation"
        ),

        // MARK: - Tests
        .testTarget(
            name: "MusicNotationCoreTests",
            dependencies: ["MusicNotationCore"],
            path: "Tests/MusicNotationCoreTests"
        ),
        .testTarget(
            name: "SMuFLKitTests",
            dependencies: ["SMuFLKit"],
            path: "Tests/SMuFLKitTests"
        ),
        .testTarget(
            name: "MusicXMLImportTests",
            dependencies: ["MusicXMLImport", "MusicXMLExport"],
            path: "Tests/MusicXMLImportTests",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "MusicXMLExportTests",
            dependencies: ["MusicXMLExport", "MusicNotationCore"],
            path: "Tests/MusicXMLExportTests"
        ),
        .testTarget(
            name: "MusicNotationLayoutTests",
            dependencies: ["MusicNotationLayout"],
            path: "Tests/MusicNotationLayoutTests"
        ),
        .testTarget(
            name: "MusicNotationPlaybackTests",
            dependencies: ["MusicNotationPlayback"],
            path: "Tests/MusicNotationPlaybackTests"
        ),
        .testTarget(
            name: "MusicNotationRendererTests",
            dependencies: ["MusicNotationRenderer", "MusicNotationLayout", "MusicNotationCore"],
            path: "Tests/MusicNotationRendererTests"
        ),
        .testTarget(
            name: "MIDIImportTests",
            dependencies: ["MIDIImport", "MusicNotationCore"],
            path: "Tests/MIDIImportTests"
        ),
        .testTarget(
            name: "MusicXMLValidationTests",
            dependencies: [
                "MusicNotationCore",
                "MusicXMLImport",
                "MusicXMLExport"
            ],
            path: "Tests/MusicXMLValidationTests",
            resources: [.copy("Resources"), .copy("Scripts")]
        ),
    ]
)
