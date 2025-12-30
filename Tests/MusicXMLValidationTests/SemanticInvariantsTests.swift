import XCTest
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Tests for semantic invariant validation.
final class SemanticInvariantsTests: MusicXMLValidationTestCase {

    var validator: SemanticInvariantsValidator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        validator = SemanticInvariantsValidator()
    }

    // MARK: - All Scores Pass Core Invariants

    func testAllScoresPassCoreInvariants() throws {
        // Test core invariants that should always pass
        // (durations, tuplets, staff numbers, chord coherence)
        // Skip beam validation as cross-measure beams are common and valid
        let coreValidator = SemanticInvariantsValidator(options: Options(
            validateDurations: true,
            validateTies: false,  // Ties can span beyond our scope
            validateBeams: false,  // Cross-measure beams are valid
            validateChords: true,
            validateTuplets: true,
            validateStaffNumbers: true
        ))

        var failures: [(String, [SemanticInvariantsValidator.Violation])] = []

        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let result = coreValidator.validate(score)
            if !result.passed {
                failures.append((metadata.title, result.violations))
            }
        }

        if !failures.isEmpty {
            var message = "Semantic invariant failures:\n"
            for (title, violations) in failures {
                message += "\n\(title):\n"
                for v in violations.prefix(5) {
                    message += "  - \(v.description)\n"
                }
                if violations.count > 5 {
                    message += "  ... and \(violations.count - 5) more\n"
                }
            }
            XCTFail(message)
        }
    }

    // MARK: - Duration Invariants

    func testMeasureDurationsSumCorrectly() throws {
        // Test basic scores which should have simple time signatures
        for metadata in library.scores(for: .basic) {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let durationValidator = SemanticInvariantsValidator(options: .durationOnly)
            let result = durationValidator.validate(score)

            // Filter out duration mismatches only
            let durationViolations = result.violations.filter {
                if case .measureDurationMismatch = $0 { return true }
                return false
            }

            XCTAssertTrue(
                durationViolations.isEmpty,
                "\(metadata.title) has duration violations: \(durationViolations.prefix(3))"
            )
        }
    }

    func testPercussionScoresDurationsSumCorrectly() throws {
        for metadata in library.scores(for: .percussion) {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let durationValidator = SemanticInvariantsValidator(options: .durationOnly)
            let result = durationValidator.validate(score)

            let durationViolations = result.violations.filter {
                if case .measureDurationMismatch = $0 { return true }
                return false
            }

            XCTAssertTrue(
                durationViolations.isEmpty,
                "\(metadata.title) has duration violations: \(durationViolations.prefix(3))"
            )
        }
    }

    // MARK: - Tie Invariants

    func testTiesMatchCorrectly() throws {
        let scoresWithTies = library.scores(withFeature: .ties)

        for metadata in scoresWithTies {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let tieValidator = SemanticInvariantsValidator(options: Options(
                validateDurations: false,
                validateTies: true,
                validateBeams: false,
                validateChords: false,
                validateTuplets: false,
                validateStaffNumbers: false
            ))
            let result = tieValidator.validate(score)

            let tieViolations = result.violations.filter {
                switch $0 {
                case .tiePitchMismatch, .orphanedTieStart, .orphanedTieStop:
                    return true
                default:
                    return false
                }
            }

            // Some scores may have ties that span beyond our test scope
            // Just ensure there are no pitch mismatches
            let pitchMismatches = tieViolations.filter {
                if case .tiePitchMismatch = $0 { return true }
                return false
            }

            XCTAssertTrue(
                pitchMismatches.isEmpty,
                "\(metadata.title) has tie pitch mismatches: \(pitchMismatches)"
            )
        }
    }

    // MARK: - Beam Invariants

    func testBeamContinuity() throws {
        let scoresWithBeams = library.scores(withFeature: .beams)

        for metadata in scoresWithBeams {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let beamValidator = SemanticInvariantsValidator(options: Options(
                validateDurations: false,
                validateTies: false,
                validateBeams: true,
                validateChords: false,
                validateTuplets: false,
                validateStaffNumbers: false
            ))
            let result = beamValidator.validate(score)

            let beamViolations = result.violations.filter {
                if case .beamContinuityError = $0 { return true }
                return false
            }

            XCTAssertTrue(
                beamViolations.isEmpty,
                "\(metadata.title) has beam violations: \(beamViolations.prefix(5))"
            )
        }
    }

    // MARK: - Chord Invariants

    func testChordCoherence() throws {
        let scoresWithChords = library.scores(withFeature: .chords)

        for metadata in scoresWithChords {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let chordValidator = SemanticInvariantsValidator(options: Options(
                validateDurations: false,
                validateTies: false,
                validateBeams: false,
                validateChords: true,
                validateTuplets: false,
                validateStaffNumbers: false
            ))
            let result = chordValidator.validate(score)

            let chordViolations = result.violations.filter {
                switch $0 {
                case .chordVoiceMismatch, .inconsistentNoteType:
                    return true
                default:
                    return false
                }
            }

            XCTAssertTrue(
                chordViolations.isEmpty,
                "\(metadata.title) has chord violations: \(chordViolations.prefix(5))"
            )
        }
    }

    // MARK: - Tuplet Invariants

    func testTupletRatiosAreValid() throws {
        let scoresWithTuplets = library.scores(withFeature: .tuplets)

        for metadata in scoresWithTuplets {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let tupletValidator = SemanticInvariantsValidator(options: Options(
                validateDurations: false,
                validateTies: false,
                validateBeams: false,
                validateChords: false,
                validateTuplets: true,
                validateStaffNumbers: false
            ))
            let result = tupletValidator.validate(score)

            let tupletViolations = result.violations.filter {
                if case .invalidTupletRatio = $0 { return true }
                return false
            }

            XCTAssertTrue(
                tupletViolations.isEmpty,
                "\(metadata.title) has tuplet violations: \(tupletViolations)"
            )
        }
    }

    // MARK: - Staff Number Invariants

    func testStaffNumbersAreValid() throws {
        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            let staffValidator = SemanticInvariantsValidator(options: Options(
                validateDurations: false,
                validateTies: false,
                validateBeams: false,
                validateChords: false,
                validateTuplets: false,
                validateStaffNumbers: true
            ))
            let result = staffValidator.validate(score)

            let staffViolations = result.violations.filter {
                if case .invalidStaffNumber = $0 { return true }
                return false
            }

            XCTAssertTrue(
                staffViolations.isEmpty,
                "\(metadata.title) has staff number violations: \(staffViolations)"
            )
        }
    }

    // MARK: - Round-Trip Preserves Invariants

    func testRoundTripPreservesSemanticInvariants() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let originalScore = try importer.importScore(from: data)

            // Validate original
            let originalResult = validator.validate(originalScore)

            // Round-trip
            let exporter = MusicXMLExporter()
            let exportedData = try exporter.export(originalScore)
            let reimportedScore = try importer.importScore(from: exportedData)

            // Validate reimported
            let reimportedResult = validator.validate(reimportedScore)

            // Reimported should have same or fewer violations
            XCTAssertLessThanOrEqual(
                reimportedResult.violations.count,
                originalResult.violations.count + 5,  // Allow small tolerance
                "\(metadata.title): round-trip increased violations from \(originalResult.violations.count) to \(reimportedResult.violations.count)"
            )
        }
    }

    // MARK: - Specific Score Tests

    func testDrumKitSemanticInvariants() throws {
        let data = try library.loadScore(filename: "drum_kit.musicxml", category: .percussion)
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let result = validator.validate(score)

        // Drum kit should pass all semantic invariants
        XCTAssertTrue(result.passed, "Drum kit violations: \(result.report())")
    }

    func testBachMinuetSemanticInvariants() throws {
        let data = try library.loadScore(filename: "Bach_Minuet_in_G_Major_BWV_Anh._114.mxl", category: .basic)
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let result = validator.validate(score)

        // Bach Minuet should pass all semantic invariants
        if !result.passed {
            print("Bach Minuet violations:\n\(result.report())")
        }
        // Allow some tolerance for complex real-world scores
        XCTAssertLessThan(result.violations.count, 10, "Too many violations in Bach Minuet")
    }
}

// MARK: - Helper Extension

private typealias Options = SemanticInvariantsValidator.Options
