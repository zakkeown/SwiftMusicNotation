import Foundation
import Compression

/// Manages test scores for validation testing.
public final class TestScoreLibrary {

    // MARK: - Types

    /// Category of test score.
    public enum Category: String, Codable, CaseIterable, Sendable {
        case basic
        case intermediate
        case advanced
        case percussion
        case orchestral
    }

    /// Complexity level of a score.
    public enum Complexity: Int, Codable, Comparable, Sendable {
        case minimal = 1
        case simple = 2
        case moderate = 3
        case complex = 4
        case massive = 5

        public static func < (lhs: Complexity, rhs: Complexity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Features that a score may exercise.
    public enum MusicXMLFeature: String, Codable, CaseIterable, Sendable {
        // Notes
        case pitchedNotes
        case unpitchedNotes
        case rests
        case chords
        case graceNotes
        case dots
        case ties
        case beams
        case tuplets

        // Notation
        case dynamics
        case articulations
        case ornaments
        case slurs
        case crescendo
        case pedal
        case lyrics

        // Structure
        case multipleVoices
        case multipleStaves
        case multipleParts
        case repeats
        case endings
        case codas

        // Advanced
        case percussion
        case transposition
        case meterChanges
        case keyChanges
    }

    /// Metadata for a test score.
    public struct ScoreMetadata: Codable, Sendable {
        public let filename: String
        public let title: String
        public let composer: String?
        public let category: Category
        public let complexity: Complexity
        public let expectedFeatures: Set<MusicXMLFeature>
        public let knownLimitations: [String]
        public let expectedPartCount: Int?
        public let expectedMeasureCount: Int?
        public let expectedNoteCount: Int?

        public init(
            filename: String,
            title: String,
            composer: String? = nil,
            category: Category,
            complexity: Complexity,
            expectedFeatures: Set<MusicXMLFeature> = [],
            knownLimitations: [String] = [],
            expectedPartCount: Int? = nil,
            expectedMeasureCount: Int? = nil,
            expectedNoteCount: Int? = nil
        ) {
            self.filename = filename
            self.title = title
            self.composer = composer
            self.category = category
            self.complexity = complexity
            self.expectedFeatures = expectedFeatures
            self.knownLimitations = knownLimitations
            self.expectedPartCount = expectedPartCount
            self.expectedMeasureCount = expectedMeasureCount
            self.expectedNoteCount = expectedNoteCount
        }
    }

    /// The test manifest containing all score metadata.
    public struct TestManifest: Codable, Sendable {
        public let scores: [ScoreMetadata]
        public let version: String

        public init(scores: [ScoreMetadata], version: String = "1.0") {
            self.scores = scores
            self.version = version
        }
    }

    // MARK: - Properties

    private let bundle: Bundle
    private var manifest: TestManifest?
    private let resourceSubdirectory: String

    // MARK: - Initialization

    /// Creates a library using the test bundle.
    public init(bundle: Bundle? = nil, resourceSubdirectory: String = "Resources/TestScores") {
        self.bundle = bundle ?? Bundle.module
        self.resourceSubdirectory = resourceSubdirectory
        loadManifest()
    }

    // MARK: - Public Methods

    /// Returns all score metadata.
    public func allScores() -> [ScoreMetadata] {
        manifest?.scores ?? []
    }

    /// Returns scores in a specific category.
    public func scores(for category: Category) -> [ScoreMetadata] {
        allScores().filter { $0.category == category }
    }

    /// Returns scores with a specific feature.
    public func scores(withFeature feature: MusicXMLFeature) -> [ScoreMetadata] {
        allScores().filter { $0.expectedFeatures.contains(feature) }
    }

    /// Returns scores with any of the given features.
    public func scores(withAnyFeature features: Set<MusicXMLFeature>) -> [ScoreMetadata] {
        allScores().filter { !$0.expectedFeatures.isDisjoint(with: features) }
    }

    /// Returns scores with all of the given features.
    public func scores(withAllFeatures features: Set<MusicXMLFeature>) -> [ScoreMetadata] {
        allScores().filter { features.isSubset(of: $0.expectedFeatures) }
    }

    /// Returns scores up to a specific complexity.
    public func scores(maxComplexity: Complexity) -> [ScoreMetadata] {
        allScores().filter { $0.complexity <= maxComplexity }
    }

    /// Returns scores matching a filter.
    public func scores(where predicate: (ScoreMetadata) -> Bool) -> [ScoreMetadata] {
        allScores().filter(predicate)
    }

    /// Loads the MusicXML data for a score.
    public func loadScore(_ metadata: ScoreMetadata) throws -> Data {
        return try loadScore(filename: metadata.filename, category: metadata.category)
    }

    /// Loads the MusicXML data for a score by filename.
    public func loadScore(filename: String, category: Category) throws -> Data {
        // Try to find the file in the category subdirectory
        let subdirectory = "\(resourceSubdirectory)/\(category.rawValue)"

        // Try .mxl first (compressed)
        if let url = bundle.url(forResource: filename.replacingOccurrences(of: ".mxl", with: ""),
                                 withExtension: "mxl",
                                 subdirectory: subdirectory) {
            return try extractMXL(at: url)
        }

        // Try .musicxml
        if let url = bundle.url(forResource: filename.replacingOccurrences(of: ".musicxml", with: ""),
                                 withExtension: "musicxml",
                                 subdirectory: subdirectory) {
            return try Data(contentsOf: url)
        }

        // Try .xml
        if let url = bundle.url(forResource: filename.replacingOccurrences(of: ".xml", with: ""),
                                 withExtension: "xml",
                                 subdirectory: subdirectory) {
            return try Data(contentsOf: url)
        }

        // Try direct path
        if let url = bundle.url(forResource: filename, withExtension: nil, subdirectory: subdirectory) {
            let data = try Data(contentsOf: url)
            if filename.hasSuffix(".mxl") {
                return try extractMXLData(data)
            }
            return data
        }

        throw LibraryError.scoreNotFound(filename)
    }

    /// Returns the URL for a score file.
    public func url(for metadata: ScoreMetadata) -> URL? {
        let subdirectory = "\(resourceSubdirectory)/\(metadata.category.rawValue)"

        if let url = bundle.url(forResource: metadata.filename.replacingOccurrences(of: ".mxl", with: ""),
                                 withExtension: "mxl",
                                 subdirectory: subdirectory) {
            return url
        }

        if let url = bundle.url(forResource: metadata.filename.replacingOccurrences(of: ".musicxml", with: ""),
                                 withExtension: "musicxml",
                                 subdirectory: subdirectory) {
            return url
        }

        return bundle.url(forResource: metadata.filename, withExtension: nil, subdirectory: subdirectory)
    }

    // MARK: - Feature Coverage

    /// Returns which features are covered by the available scores.
    public func featureCoverage() -> [MusicXMLFeature: Int] {
        var coverage: [MusicXMLFeature: Int] = [:]
        for feature in MusicXMLFeature.allCases {
            coverage[feature] = scores(withFeature: feature).count
        }
        return coverage
    }

    /// Returns features that have no test coverage.
    public func uncoveredFeatures() -> [MusicXMLFeature] {
        MusicXMLFeature.allCases.filter { scores(withFeature: $0).isEmpty }
    }

    // MARK: - Private Methods

    private func loadManifest() {
        guard let url = bundle.url(forResource: "TestManifest", withExtension: "json", subdirectory: "Resources") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            manifest = try decoder.decode(TestManifest.self, from: data)
        } catch {
            print("Warning: Failed to load test manifest: \(error)")
        }
    }

    private func extractMXL(at url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        return try extractMXLData(data)
    }

    private func extractMXLData(_ data: Data) throws -> Data {
        // MXL files are ZIP archives containing the MusicXML
        // We need to find the main document (usually referenced in META-INF/container.xml)

        guard let archive = try? extractZipEntries(from: data) else {
            throw LibraryError.invalidMXLFormat
        }

        // Look for the main MusicXML file
        // First try to find container.xml to get the rootfile path
        if let containerData = archive["META-INF/container.xml"] {
            if let rootfile = parseContainerXML(containerData) {
                if let xmlData = archive[rootfile] {
                    return xmlData
                }
            }
        }

        // Fallback: look for any .xml or .musicxml file
        for (path, fileData) in archive {
            let lowercasePath = path.lowercased()
            if (lowercasePath.hasSuffix(".xml") || lowercasePath.hasSuffix(".musicxml"))
                && !lowercasePath.contains("meta-inf") {
                return fileData
            }
        }

        throw LibraryError.noMusicXMLFound
    }

    private func extractZipEntries(from data: Data) throws -> [String: Data] {
        var entries: [String: Data] = [:]

        // Simple ZIP parsing (handles most MXL files)
        var offset = 0
        let bytes = [UInt8](data)

        while offset + 30 < bytes.count {
            // Check for local file header signature (0x04034b50)
            guard bytes[offset] == 0x50 && bytes[offset + 1] == 0x4b &&
                  bytes[offset + 2] == 0x03 && bytes[offset + 3] == 0x04 else {
                break
            }

            let compressionMethod = UInt16(bytes[offset + 8]) | (UInt16(bytes[offset + 9]) << 8)
            let compressedSize = UInt32(bytes[offset + 18]) | (UInt32(bytes[offset + 19]) << 8) |
                                 (UInt32(bytes[offset + 20]) << 16) | (UInt32(bytes[offset + 21]) << 24)
            let uncompressedSize = UInt32(bytes[offset + 22]) | (UInt32(bytes[offset + 23]) << 8) |
                                   (UInt32(bytes[offset + 24]) << 16) | (UInt32(bytes[offset + 25]) << 24)
            let filenameLength = Int(UInt16(bytes[offset + 26]) | (UInt16(bytes[offset + 27]) << 8))
            let extraLength = Int(UInt16(bytes[offset + 28]) | (UInt16(bytes[offset + 29]) << 8))

            let filenameStart = offset + 30
            let filenameEnd = filenameStart + filenameLength
            guard filenameEnd <= bytes.count else { break }

            let filenameBytes = Array(bytes[filenameStart..<filenameEnd])
            guard let filename = String(bytes: filenameBytes, encoding: .utf8) else {
                offset = filenameEnd + extraLength + Int(compressedSize)
                continue
            }

            let dataStart = filenameEnd + extraLength
            let dataEnd = dataStart + Int(compressedSize)
            guard dataEnd <= bytes.count else { break }

            let fileData = Data(bytes[dataStart..<dataEnd])

            if compressionMethod == 0 {
                // Stored (no compression)
                entries[filename] = fileData
            } else if compressionMethod == 8 {
                // Deflate
                if let decompressed = decompress(fileData, expectedSize: Int(uncompressedSize)) {
                    entries[filename] = decompressed
                }
            }

            offset = dataEnd
        }

        return entries
    }

    private func decompress(_ data: Data, expectedSize: Int) -> Data? {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = data.withUnsafeBytes { sourceBuffer -> Int in
            guard let sourcePointer = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            return compression_decode_buffer(
                destinationBuffer,
                expectedSize,
                sourcePointer,
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard decompressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }

    private func parseContainerXML(_ data: Data) -> String? {
        guard let xml = String(data: data, encoding: .utf8) else { return nil }

        // Simple regex to find rootfile full-path
        if let range = xml.range(of: #"full-path="([^"]+)""#, options: .regularExpression) {
            let match = xml[range]
            let pathStart = match.index(match.startIndex, offsetBy: 11)
            let pathEnd = match.index(before: match.endIndex)
            return String(match[pathStart..<pathEnd])
        }

        return nil
    }

    // MARK: - Errors

    public enum LibraryError: Error, LocalizedError {
        case scoreNotFound(String)
        case invalidMXLFormat
        case noMusicXMLFound
        case manifestNotFound

        public var errorDescription: String? {
            switch self {
            case .scoreNotFound(let filename):
                return "Test score not found: \(filename)"
            case .invalidMXLFormat:
                return "Invalid MXL file format"
            case .noMusicXMLFound:
                return "No MusicXML document found in MXL archive"
            case .manifestNotFound:
                return "Test manifest not found"
            }
        }
    }
}

// MARK: - Bundle Extension

#if canImport(SwiftPM)
// When running in SPM test context
extension Bundle {
    static var testModule: Bundle {
        Bundle.module
    }
}
#endif
