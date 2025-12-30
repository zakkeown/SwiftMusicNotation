import Foundation
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Validates MusicXML round-trip fidelity (import → export → reimport).
public struct RoundTripValidator {

    // MARK: - Types

    /// Result of a round-trip validation.
    public struct Result: Sendable {
        /// The original imported score.
        public let originalScore: Score

        /// The exported MusicXML data.
        public let exportedXML: Data

        /// The reimported score.
        public let reimportedScore: Score

        /// The differences between original and reimported scores.
        public let diff: ScoreDiff

        /// Whether the round-trip passed (no significant differences).
        public var passed: Bool { diff.isEqual }

        /// Human-readable summary.
        public func summary() -> String {
            if passed {
                return "Round-trip validation PASSED"
            } else {
                return "Round-trip validation FAILED:\n\(diff.report())"
            }
        }
    }

    /// Options for round-trip validation.
    public struct Options: Sendable {
        /// Comparison options to use.
        public var comparisonOptions: ScoreComparator.Options

        /// Import options for the initial import.
        public var importOptions: ImportOptions

        /// Export configuration.
        public var exportConfig: ExportConfiguration

        /// Whether to keep intermediate XML for debugging.
        public var keepIntermediateXML: Bool

        public init(
            comparisonOptions: ScoreComparator.Options = .roundTrip,
            importOptions: ImportOptions = .default,
            exportConfig: ExportConfiguration = ExportConfiguration(),
            keepIntermediateXML: Bool = false
        ) {
            self.comparisonOptions = comparisonOptions
            self.importOptions = importOptions
            self.exportConfig = exportConfig
            self.keepIntermediateXML = keepIntermediateXML
        }

        public static let `default` = Options()
    }

    // MARK: - Properties

    private let options: Options
    private let importer: MusicXMLImporter
    private let exporter: MusicXMLExporter
    private let comparator: ScoreComparator

    // MARK: - Initialization

    public init(options: Options = .default) {
        self.options = options
        self.importer = MusicXMLImporter(options: options.importOptions)
        self.exporter = MusicXMLExporter(config: options.exportConfig)
        self.comparator = ScoreComparator(options: options.comparisonOptions)
    }

    // MARK: - Public Methods

    /// Validates a round-trip from MusicXML data.
    public func validate(data: Data) throws -> Result {
        // Step 1: Import original
        let originalScore = try importer.importScore(from: data)

        // Step 2: Export
        let exportedXML = try exporter.export(originalScore)

        // Step 3: Reimport
        let reimportedScore = try importer.importScore(from: exportedXML)

        // Step 4: Compare
        let diff = comparator.compare(originalScore, reimportedScore)

        return Result(
            originalScore: originalScore,
            exportedXML: exportedXML,
            reimportedScore: reimportedScore,
            diff: diff
        )
    }

    /// Validates a round-trip from a URL.
    public func validate(url: URL) throws -> Result {
        let data = try Data(contentsOf: url)
        return try validate(data: data)
    }

    /// Validates a round-trip from a file path.
    public func validate(path: String) throws -> Result {
        let url = URL(fileURLWithPath: path)
        return try validate(url: url)
    }

    // MARK: - Batch Validation

    /// Batch result for multiple validations.
    public struct BatchResult: Sendable {
        public let results: [(filename: String, result: Swift.Result<Result, Error>)]

        public var passCount: Int {
            results.filter { if case .success(let r) = $0.result { return r.passed } else { return false } }.count
        }

        public var failCount: Int {
            results.count - passCount
        }

        public var errorCount: Int {
            results.filter { if case .failure = $0.result { return true } else { return false } }.count
        }

        public func summary() -> String {
            var lines: [String] = []
            lines.append("Batch Validation Results")
            lines.append("========================")
            lines.append("Total: \(results.count)")
            lines.append("Passed: \(passCount)")
            lines.append("Failed: \(failCount - errorCount)")
            lines.append("Errors: \(errorCount)")
            lines.append("")

            for (filename, result) in results {
                switch result {
                case .success(let r):
                    let status = r.passed ? "PASS" : "FAIL"
                    lines.append("[\(status)] \(filename)")
                    if !r.passed {
                        // Add first few differences
                        for diff in r.diff.differences.prefix(3) {
                            lines.append("  - \(diff)")
                        }
                        if r.diff.differences.count > 3 {
                            lines.append("  ... and \(r.diff.differences.count - 3) more")
                        }
                    }
                case .failure(let error):
                    lines.append("[ERROR] \(filename): \(error.localizedDescription)")
                }
            }

            return lines.joined(separator: "\n")
        }
    }

    /// Validates multiple files.
    public func validateBatch(urls: [URL]) -> BatchResult {
        var results: [(filename: String, result: Swift.Result<Result, Error>)] = []

        for url in urls {
            let filename = url.lastPathComponent
            do {
                let result = try validate(url: url)
                results.append((filename, .success(result)))
            } catch {
                results.append((filename, .failure(error)))
            }
        }

        return BatchResult(results: results)
    }

    /// Validates all files in a directory.
    public func validateDirectory(at url: URL, extensions: [String] = ["musicxml", "xml", "mxl"]) throws -> BatchResult {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

        let matchingFiles = contents.filter { fileURL in
            extensions.contains(fileURL.pathExtension.lowercased())
        }

        return validateBatch(urls: matchingFiles)
    }
}

// MARK: - Validation Statistics

extension RoundTripValidator {
    /// Statistics about a validation result.
    public struct ValidationStatistics {
        public let originalNoteCount: Int
        public let reimportedNoteCount: Int
        public let originalMeasureCount: Int
        public let reimportedMeasureCount: Int
        public let originalPartCount: Int
        public let reimportedPartCount: Int
        public let differenceCount: Int

        public init(result: Result) {
            self.originalNoteCount = result.originalScore.parts.flatMap { $0.measures.flatMap { $0.notes } }.count
            self.reimportedNoteCount = result.reimportedScore.parts.flatMap { $0.measures.flatMap { $0.notes } }.count
            self.originalMeasureCount = result.originalScore.parts.first?.measures.count ?? 0
            self.reimportedMeasureCount = result.reimportedScore.parts.first?.measures.count ?? 0
            self.originalPartCount = result.originalScore.parts.count
            self.reimportedPartCount = result.reimportedScore.parts.count
            self.differenceCount = result.diff.differences.count
        }

        public var summary: String {
            """
            Validation Statistics:
              Parts: \(originalPartCount) → \(reimportedPartCount)
              Measures: \(originalMeasureCount) → \(reimportedMeasureCount)
              Notes: \(originalNoteCount) → \(reimportedNoteCount)
              Differences: \(differenceCount)
            """
        }
    }

    /// Gets statistics for a validation result.
    public func statistics(for result: Result) -> ValidationStatistics {
        ValidationStatistics(result: result)
    }
}
