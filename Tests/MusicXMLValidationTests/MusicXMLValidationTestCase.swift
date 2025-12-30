import XCTest
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Base class for MusicXML validation tests.
///
/// Provides common utilities for round-trip validation, score comparison,
/// and test score loading.
class MusicXMLValidationTestCase: XCTestCase {

    // MARK: - Properties

    /// The test score library.
    var library: TestScoreLibrary!

    /// The round-trip validator.
    var roundTripValidator: RoundTripValidator!

    /// The score comparator.
    var comparator: ScoreComparator!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        library = TestScoreLibrary()
        roundTripValidator = RoundTripValidator()
        comparator = ScoreComparator(options: .roundTrip)
    }

    override func tearDown() {
        library = nil
        roundTripValidator = nil
        comparator = nil
        super.tearDown()
    }

    // MARK: - Assertion Helpers

    /// Asserts that a score round-trips successfully.
    ///
    /// - Parameters:
    ///   - data: The MusicXML data to validate.
    ///   - metadata: Optional metadata for better error messages.
    ///   - file: The file where the assertion is made.
    ///   - line: The line where the assertion is made.
    func assertRoundTrip(
        _ data: Data,
        metadata: TestScoreLibrary.ScoreMetadata? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try roundTripValidator.validate(data: data)

        if !result.passed {
            let title = metadata?.title ?? "Unknown Score"
            let report = result.diff.report()
            XCTFail("Round-trip failed for '\(title)':\n\(report)", file: file, line: line)
        }
    }

    /// Asserts that a score from the library round-trips successfully.
    ///
    /// - Parameters:
    ///   - metadata: The score metadata.
    ///   - file: The file where the assertion is made.
    ///   - line: The line where the assertion is made.
    func assertRoundTrip(
        _ metadata: TestScoreLibrary.ScoreMetadata,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let data = try library.loadScore(metadata)
        try assertRoundTrip(data, metadata: metadata, file: file, line: line)
    }

    /// Asserts that a score can be imported without errors.
    ///
    /// - Parameters:
    ///   - data: The MusicXML data to import.
    ///   - file: The file where the assertion is made.
    ///   - line: The line where the assertion is made.
    /// - Returns: The imported score.
    @discardableResult
    func assertImportSucceeds(
        _ data: Data,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Score {
        let importer = MusicXMLImporter()
        do {
            return try importer.importScore(from: data)
        } catch {
            XCTFail("Import failed: \(error)", file: file, line: line)
            throw error
        }
    }

    /// Asserts that two scores are equal according to the comparator.
    ///
    /// - Parameters:
    ///   - score1: The first score.
    ///   - score2: The second score.
    ///   - options: Comparison options.
    ///   - file: The file where the assertion is made.
    ///   - line: The line where the assertion is made.
    func assertEqual(
        _ score1: Score,
        _ score2: Score,
        options: ScoreComparator.Options = .roundTrip,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let comparator = ScoreComparator(options: options)
        let diff = comparator.compare(score1, score2)

        if !diff.isEqual {
            XCTFail("Scores are not equal:\n\(diff.report())", file: file, line: line)
        }
    }

    // MARK: - Structural Assertions

    /// Asserts that a score has the expected number of parts.
    func assertPartCount(
        _ score: Score,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(score.parts.count, expected, "Part count mismatch", file: file, line: line)
    }

    /// Asserts that a score has the expected number of measures.
    func assertMeasureCount(
        _ score: Score,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(score.measureCount, expected, "Measure count mismatch", file: file, line: line)
    }

    /// Asserts that a score has at least the expected number of notes.
    func assertMinimumNoteCount(
        _ score: Score,
        minimum: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let noteCount = score.parts.flatMap { $0.measures.flatMap { $0.notes } }.count
        XCTAssertGreaterThanOrEqual(noteCount, minimum, "Too few notes", file: file, line: line)
    }

    // MARK: - Category Test Helpers

    /// Runs round-trip validation for all scores in a category.
    ///
    /// - Parameters:
    ///   - category: The category to test.
    ///   - continueOnFailure: Whether to continue testing after a failure.
    /// - Returns: Array of (metadata, result) tuples.
    func validateCategory(
        _ category: TestScoreLibrary.Category,
        continueOnFailure: Bool = true
    ) throws -> [(TestScoreLibrary.ScoreMetadata, RoundTripValidator.Result)] {
        var results: [(TestScoreLibrary.ScoreMetadata, RoundTripValidator.Result)] = []

        let scores = library.scores(for: category)
        XCTAssertFalse(scores.isEmpty, "No scores found for category: \(category)")

        for metadata in scores {
            do {
                let data = try library.loadScore(metadata)
                let result = try roundTripValidator.validate(data: data)
                results.append((metadata, result))

                if !result.passed && !continueOnFailure {
                    XCTFail("Round-trip failed for '\(metadata.title)':\n\(result.diff.report())")
                    break
                }
            } catch {
                XCTFail("Error processing '\(metadata.filename)': \(error)")
                if !continueOnFailure { break }
            }
        }

        return results
    }

    /// Summarizes validation results.
    func summarizeResults(_ results: [(TestScoreLibrary.ScoreMetadata, RoundTripValidator.Result)]) -> String {
        let passed = results.filter { $0.1.passed }.count
        let failed = results.count - passed

        var lines: [String] = []
        lines.append("Validation Summary: \(passed)/\(results.count) passed")

        if failed > 0 {
            lines.append("\nFailed scores:")
            for (metadata, result) in results where !result.passed {
                lines.append("  - \(metadata.title)")
                for diff in result.diff.differences.prefix(3) {
                    lines.append("    • \(diff)")
                }
                if result.diff.differences.count > 3 {
                    lines.append("    ... and \(result.diff.differences.count - 3) more")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Feature Test Helpers

    /// Validates all scores with a specific feature.
    func validateFeature(
        _ feature: TestScoreLibrary.MusicXMLFeature
    ) throws -> [(TestScoreLibrary.ScoreMetadata, RoundTripValidator.Result)] {
        var results: [(TestScoreLibrary.ScoreMetadata, RoundTripValidator.Result)] = []

        let scores = library.scores(withFeature: feature)
        for metadata in scores {
            do {
                let data = try library.loadScore(metadata)
                let result = try roundTripValidator.validate(data: data)
                results.append((metadata, result))
            } catch {
                // Skip scores that fail to load
                continue
            }
        }

        return results
    }
}

// MARK: - Test Data Loading Extensions

extension MusicXMLValidationTestCase {
    /// Loads embedded test data from the main import test resources.
    func loadEmbeddedTestResource(_ name: String, extension ext: String = "musicxml") throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources") else {
            throw TestDataError.resourceNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    enum TestDataError: Error, LocalizedError {
        case resourceNotFound(String)

        var errorDescription: String? {
            switch self {
            case .resourceNotFound(let name):
                return "Test resource not found: \(name)"
            }
        }
    }
}
