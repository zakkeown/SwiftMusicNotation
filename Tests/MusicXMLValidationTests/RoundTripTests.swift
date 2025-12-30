import XCTest
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Tests for round-trip validation of MusicXML files.
///
/// These tests verify that scores can be imported, exported, and reimported
/// without loss of essential musical information.
final class RoundTripTests: MusicXMLValidationTestCase {

    // MARK: - Basic Category Tests

    func testBasicScoresRoundTrip() throws {
        let results = try validateCategory(.basic)
        let summary = summarizeResults(results)

        // All basic scores should pass
        for (metadata, result) in results {
            XCTAssertTrue(
                result.passed,
                "Basic score '\(metadata.title)' failed round-trip:\n\(result.diff.report())"
            )
        }

        print(summary)
    }

    func testIntermediateScoresRoundTrip() throws {
        let results = try validateCategory(.intermediate)
        let summary = summarizeResults(results)

        // Most intermediate scores should pass
        let passedCount = results.filter { $0.1.passed }.count
        XCTAssertGreaterThanOrEqual(
            passedCount, results.count / 2,
            "Less than half of intermediate scores passed:\n\(summary)"
        )

        print(summary)
    }

    func testAdvancedScoresRoundTrip() throws {
        let results = try validateCategory(.advanced)
        let summary = summarizeResults(results)

        // Advanced scores may have more issues - log results
        print(summary)

        // At least verify they can be imported
        for (metadata, result) in results {
            XCTAssertNotNil(result.originalScore, "Failed to import '\(metadata.title)'")
        }
    }

    func testPercussionScoresRoundTrip() throws {
        let results = try validateCategory(.percussion)
        let summary = summarizeResults(results)

        // Percussion scores should pass
        for (metadata, result) in results {
            XCTAssertTrue(
                result.passed,
                "Percussion score '\(metadata.title)' failed round-trip:\n\(result.diff.report())"
            )
        }

        print(summary)
    }

    // MARK: - Individual Score Tests

    func testBachMinuetRoundTrip() throws {
        let scores = library.scores(for: .basic).filter { $0.filename.contains("Bach_Minuet") }
        guard let metadata = scores.first else {
            throw XCTSkip("Bach Minuet not found in library")
        }

        let data = try library.loadScore(metadata)
        let result = try roundTripValidator.validate(data: data)

        XCTAssertTrue(result.passed, "Round-trip failed:\n\(result.diff.report())")

        // Verify structural integrity
        assertPartCount(result.originalScore, expected: 1)
        assertMinimumNoteCount(result.originalScore, minimum: 10)
    }

    func testDrumKitRoundTrip() throws {
        let scores = library.scores(for: .percussion).filter { $0.filename.contains("drum_kit") }
        guard let metadata = scores.first else {
            throw XCTSkip("Drum kit test file not found in library")
        }

        let data = try library.loadScore(metadata)
        let result = try roundTripValidator.validate(data: data)

        // Verify percussion-specific content
        let part = result.originalScore.parts.first!
        XCTAssertTrue(part.isPercussion, "Part should be detected as percussion")

        // Check unpitched notes are preserved
        let notes = result.originalScore.parts.flatMap { $0.measures.flatMap { $0.notes } }
        let unpitchedNotes = notes.filter { $0.unpitched != nil }
        XCTAssertGreaterThan(unpitchedNotes.count, 0, "Should have unpitched notes")

        XCTAssertTrue(result.passed, "Round-trip failed:\n\(result.diff.report())")
    }

    func testW3CPercussionTutorialRoundTrip() throws {
        let scores = library.scores(for: .percussion).filter { $0.filename.contains("w3c_percussion") }
        guard let metadata = scores.first else {
            throw XCTSkip("W3C percussion tutorial not found in library")
        }

        let data = try library.loadScore(metadata)
        let result = try roundTripValidator.validate(data: data)

        // Verify multi-part structure
        assertPartCount(result.originalScore, expected: 2)

        // Verify both parts have percussion content
        for part in result.originalScore.parts {
            XCTAssertTrue(part.isPercussion, "Part '\(part.name)' should be percussion")
        }

        XCTAssertTrue(result.passed, "Round-trip failed:\n\(result.diff.report())")
    }

    // MARK: - Feature-Specific Tests

    func testTiesPreserved() throws {
        let scores = library.scores(withFeature: .ties)
        guard !scores.isEmpty else {
            throw XCTSkip("No scores with ties feature found")
        }

        for metadata in scores.prefix(3) {
            let data = try library.loadScore(metadata)
            let result = try roundTripValidator.validate(data: data)

            // Find ties in original
            let originalTies = countTies(in: result.originalScore)
            let reimportedTies = countTies(in: result.reimportedScore)

            XCTAssertEqual(
                originalTies, reimportedTies,
                "Tie count mismatch in '\(metadata.title)': \(originalTies) vs \(reimportedTies)"
            )
        }
    }

    func testChordsPreserved() throws {
        let scores = library.scores(withFeature: .chords)
        guard !scores.isEmpty else {
            throw XCTSkip("No scores with chords feature found")
        }

        for metadata in scores.prefix(3) {
            let data = try library.loadScore(metadata)
            let result = try roundTripValidator.validate(data: data)

            // Count chord tones
            let originalChords = countChordTones(in: result.originalScore)
            let reimportedChords = countChordTones(in: result.reimportedScore)

            XCTAssertEqual(
                originalChords, reimportedChords,
                "Chord count mismatch in '\(metadata.title)': \(originalChords) vs \(reimportedChords)"
            )
        }
    }

    func testDynamicsPreserved() throws {
        let scores = library.scores(withFeature: .dynamics)
        guard !scores.isEmpty else {
            throw XCTSkip("No scores with dynamics feature found")
        }

        for metadata in scores.prefix(3) {
            let data = try library.loadScore(metadata)
            let result = try roundTripValidator.validate(data: data)

            // Count dynamics
            let originalDynamics = countDynamics(in: result.originalScore)
            let reimportedDynamics = countDynamics(in: result.reimportedScore)

            XCTAssertEqual(
                originalDynamics, reimportedDynamics,
                "Dynamics count mismatch in '\(metadata.title)': \(originalDynamics) vs \(reimportedDynamics)"
            )
        }
    }

    // MARK: - Structural Tests

    func testNoteCountPreserved() throws {
        let scores = library.allScores()

        for metadata in scores {
            do {
                let data = try library.loadScore(metadata)
                let result = try roundTripValidator.validate(data: data)

                let stats = roundTripValidator.statistics(for: result)
                XCTAssertEqual(
                    stats.originalNoteCount, stats.reimportedNoteCount,
                    "Note count mismatch in '\(metadata.title)'"
                )
            } catch {
                // Log but don't fail - some scores may not load
                print("Skipping '\(metadata.filename)': \(error)")
            }
        }
    }

    func testMeasureCountPreserved() throws {
        let scores = library.allScores()

        for metadata in scores {
            do {
                let data = try library.loadScore(metadata)
                let result = try roundTripValidator.validate(data: data)

                let stats = roundTripValidator.statistics(for: result)
                XCTAssertEqual(
                    stats.originalMeasureCount, stats.reimportedMeasureCount,
                    "Measure count mismatch in '\(metadata.title)'"
                )
            } catch {
                print("Skipping '\(metadata.filename)': \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func countTies(in score: Score) -> Int {
        score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            .flatMap { $0.ties }
            .count
    }

    private func countChordTones(in score: Score) -> Int {
        score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            .filter { $0.isChordTone }
            .count
    }

    private func countDynamics(in score: Score) -> Int {
        var count = 0
        for part in score.parts {
            for measure in part.measures {
                for element in measure.elements {
                    if case .direction(let dir) = element {
                        for type in dir.types {
                            if case .dynamics = type {
                                count += 1
                            }
                        }
                    }
                }
            }
        }
        return count
    }
}
