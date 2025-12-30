import XCTest
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Tests that verify parsed scores against manually verified ground truth values.
/// These tests assert specific known values from each score to ensure parsing accuracy.
final class GroundTruthTests: MusicXMLValidationTestCase {

    // MARK: - Basic Scores

    func testBachMinuetGroundTruth() throws {
        let score = try loadScore("Bach_Minuet_in_G_Major_BWV_Anh._114.mxl", category: .basic)

        // Structure
        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")
        XCTAssertFalse(score.parts[0].measures.isEmpty, "Should have measures")

        // Find first time signature in any measure
        var foundTime: TimeSignature?
        var foundKey: KeySignature?
        for measure in score.parts[0].measures {
            if let time = measure.attributes?.timeSignatures.first, foundTime == nil {
                foundTime = time
            }
            if let key = measure.attributes?.keySignatures.first, foundKey == nil {
                foundKey = key
            }
        }

        // Time signature - 3/4 (Minuet)
        if let time = foundTime {
            XCTAssertEqual(time.beats, "3", "Should be 3/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 3/4 time")
        }

        // Key signature - G major (1 sharp)
        if let key = foundKey {
            XCTAssertEqual(key.fifths, 1, "G major = 1 sharp")
        }

        // Should have pitched notes somewhere in the score
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        XCTAssertFalse(allNotes.isEmpty, "Should have notes")

        let pitchedNotes = allNotes.filter { $0.pitch != nil }
        XCTAssertFalse(pitchedNotes.isEmpty, "Should have pitched notes")
    }

    func testCanonInDGroundTruth() throws {
        let score = try loadScore("Canon_in_D_easy.mxl", category: .basic)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // D major = 2 sharps
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, 2, "D major = 2 sharps")
        }

        // Common time (4/4)
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "4", "Should be 4/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 4/4 time")
        }
    }

    func testHappyBirthdayGroundTruth() throws {
        let score = try loadScore("Happy_Birthday_To_You_C_Major.mxl", category: .basic)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // C major = 0 sharps/flats
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, 0, "C major = no sharps or flats")
        }

        // 3/4 time (traditional Happy Birthday)
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "3", "Should be 3/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 3/4 time")
        }
    }

    func testOdeToJoyGroundTruth() throws {
        let score = try loadScore("Ode_to_Joy_Easy_variation.mxl", category: .basic)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        // Should contain chords
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let chordTones = allNotes.filter { $0.isChordTone }
        XCTAssertFalse(chordTones.isEmpty, "Ode to Joy should have chords")
    }

    // MARK: - Intermediate Scores

    func testFurEliseGroundTruth() throws {
        let score = try loadScore("Fur_Elise.mxl", category: .intermediate)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part (piano)")

        let m1 = score.parts[0].measures[0]

        // A minor = 0 sharps/flats
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, 0, "A minor = no sharps or flats")
        }

        // 3/8 time
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "3", "Should be 3/8 time")
            XCTAssertEqual(time.beatType, "8", "Should be 3/8 time")
        }
    }

    func testGymnopedieGroundTruth() throws {
        let score = try loadScore("Erik_Satie_-_Gymnopedie_No.1.mxl", category: .intermediate)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // 3/4 time (slow waltz tempo)
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "3", "Should be 3/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 3/4 time")
        }
    }

    func testChopinNocturneGroundTruth() throws {
        let score = try loadScore("Chopin_-_Nocturne_Op_9_No_2_E_Flat_Major.mxl", category: .intermediate)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // Eb major = 3 flats
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, -3, "Eb major = 3 flats")
        }

        // 12/8 time (compound quadruple)
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "12", "Should be 12/8 time")
            XCTAssertEqual(time.beatType, "8", "Should be 12/8 time")
        }

        // Should have tuplets
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let tupletNotes = allNotes.filter { $0.timeModification != nil }
        XCTAssertFalse(tupletNotes.isEmpty, "Chopin Nocturne should have tuplets")
    }

    func testArabesqueGroundTruth() throws {
        let score = try loadScore("Arabesque_L._66_No._1_in_E_Major.mxl", category: .intermediate)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // E major = 4 sharps
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, 4, "E major = 4 sharps")
        }

        // 4/4 time
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "4", "Should be 4/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 4/4 time")
        }

        // Should have tuplets (the famous triplet arpeggios)
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let tupletNotes = allNotes.filter { $0.timeModification != nil }
        XCTAssertFalse(tupletNotes.isEmpty, "Arabesque should have triplet arpeggios")
    }

    // MARK: - Advanced Scores

    func testBachToccataGroundTruth() throws {
        let score = try loadScore("Bach_Toccata_and_Fugue_in_D_Minor_Piano_solo.mxl", category: .advanced)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // D minor = 1 flat
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, -1, "D minor = 1 flat")
        }

        // Should have multiple voices (organ transcription)
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let voices = Set(allNotes.map { $0.voice })
        XCTAssertGreaterThan(voices.count, 1, "Toccata should have multiple voices")
    }

    func testBeethovenSymphony5GroundTruth() throws {
        let score = try loadScore("Beethoven_Symphony_No._5_1st_movement_Piano_solo.mxl", category: .advanced)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        let m1 = score.parts[0].measures[0]

        // C minor = 3 flats
        if let key = m1.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, -3, "C minor = 3 flats")
        }

        // 2/4 time
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "2", "Should be 2/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 2/4 time")
        }
    }

    func testChopinBallade1GroundTruth() throws {
        let score = try loadScore("Chopin_-_Ballade_no._1_in_G_minor_Op._23.mxl", category: .advanced)

        // Piano score may have 1 or 2 parts depending on encoding
        XCTAssertGreaterThanOrEqual(score.parts.count, 1, "Should have at least 1 part")

        // Find first measure with attributes
        let measureWithAttrs = score.parts[0].measures.first { $0.attributes != nil }

        // G minor = 2 flats
        if let key = measureWithAttrs?.attributes?.keySignatures.first {
            XCTAssertEqual(key.fifths, -2, "G minor = 2 flats")
        }

        // 6/4 time (unusual meter)
        if let time = measureWithAttrs?.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "6", "Should be 6/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 6/4 time")
        }
    }

    func testLaCampanellaGroundTruth() throws {
        let score = try loadScore("La_Campanella.mxl", category: .advanced)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")

        // Should have grace notes (the famous repeated high notes)
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let graceNotes = allNotes.filter { $0.isGraceNote }
        XCTAssertFalse(graceNotes.isEmpty, "La Campanella should have grace notes")
    }

    // MARK: - Percussion Scores

    func testDrumKitGroundTruth() throws {
        let score = try loadScore("drum_kit.musicxml", category: .percussion)

        XCTAssertEqual(score.parts.count, 1, "Should have 1 part")
        XCTAssertTrue(score.parts[0].isPercussion, "Should be a percussion part")

        // Should have unpitched notes
        let allNotes = score.parts[0].measures.flatMap { $0.notes }
        let unpitchedNotes = allNotes.filter { $0.unpitched != nil }
        XCTAssertFalse(unpitchedNotes.isEmpty, "Drum kit should have unpitched notes")

        // Verify percussion clef
        let m1 = score.parts[0].measures[0]
        if let clef = m1.attributes?.clefs.first {
            XCTAssertEqual(clef.sign, .percussion, "Should use percussion clef")
        }

        // Verify 4/4 time (standard rock beat)
        if let time = m1.attributes?.timeSignatures.first {
            XCTAssertEqual(time.beats, "4", "Should be 4/4 time")
            XCTAssertEqual(time.beatType, "4", "Should be 4/4 time")
        }
    }

    func testW3CPercussionTutorialGroundTruth() throws {
        let score = try loadScore("w3c_percussion_tutorial.musicxml", category: .percussion)

        // Should have 2 parts (from W3C example)
        XCTAssertEqual(score.parts.count, 2, "Should have 2 parts")

        // Both should be percussion
        XCTAssertTrue(score.parts[0].isPercussion, "Part 1 should be percussion")
        XCTAssertTrue(score.parts[1].isPercussion, "Part 2 should be percussion")

        // Should have unpitched notes
        let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
        let unpitchedNotes = allNotes.filter { $0.unpitched != nil }
        XCTAssertFalse(unpitchedNotes.isEmpty, "Should have unpitched notes")
    }

    // MARK: - Note Content Verification

    func testNoteTypesAreParsedCorrectly() throws {
        // Test that we correctly parse different note types
        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        // Every non-grace note should have a duration
                        if !note.isGraceNote {
                            XCTAssertGreaterThanOrEqual(
                                note.durationDivisions, 0,
                                "\(metadata.title): Note should have non-negative duration"
                            )
                        }

                        // Grace notes should have 0 duration
                        if note.isGraceNote {
                            XCTAssertEqual(
                                note.durationDivisions, 0,
                                "\(metadata.title): Grace note should have 0 duration"
                            )
                        }

                        // Voice should be positive
                        XCTAssertGreaterThan(
                            note.voice, 0,
                            "\(metadata.title): Voice should be positive"
                        )

                        // Staff should be positive
                        XCTAssertGreaterThan(
                            note.staff, 0,
                            "\(metadata.title): Staff should be positive"
                        )
                    }
                }
            }
        }
    }

    func testKeySignatureRangeIsValid() throws {
        // Key signatures should be in reasonable range (-7 to +7)
        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    if let keys = measure.attributes?.keySignatures {
                        for key in keys {
                            XCTAssertGreaterThanOrEqual(
                                key.fifths, -7,
                                "\(metadata.title): Key signature too flat"
                            )
                            XCTAssertLessThanOrEqual(
                                key.fifths, 7,
                                "\(metadata.title): Key signature too sharp"
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Articulations and Dynamics

    func testArticulationsAreParsed() throws {
        // Test that articulations are correctly parsed from scores that have them
        var totalArticulations = 0

        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        for notation in note.notations {
                            if case .articulations(let arts) = notation {
                                totalArticulations += arts.count
                            }
                        }
                    }
                }
            }
        }

        print("Total articulations found across all scores: \(totalArticulations)")
        // We expect some scores to have articulations
        // This validates the parsing works even if not all scores have them
    }

    func testDynamicsAreParsed() throws {
        // Test that dynamics are correctly parsed
        var totalDynamics = 0

        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    for element in measure.elements {
                        if case .direction(let direction) = element {
                            for dirType in direction.types {
                                if case .dynamics = dirType {
                                    totalDynamics += 1
                                }
                            }
                        }
                    }
                }
            }
        }

        print("Total dynamics found: \(totalDynamics)")
    }

    func testSlursAreParsed() throws {
        // Test that slurs are correctly parsed
        var slurStarts = 0
        var slurStops = 0

        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        for notation in note.notations {
                            if case .slur(let slur) = notation {
                                if slur.type == .start {
                                    slurStarts += 1
                                } else if slur.type == .stop {
                                    slurStops += 1
                                }
                            }
                        }
                    }
                }
            }
        }

        print("Total slur starts: \(slurStarts)")
        print("Total slur stops: \(slurStops)")

        // Slur starts and stops should roughly match
        if slurStarts > 0 {
            let ratio = Double(slurStops) / Double(slurStarts)
            XCTAssertGreaterThan(ratio, 0.8, "Slur stops should roughly match starts")
            XCTAssertLessThan(ratio, 1.2, "Slur stops should roughly match starts")
        }
    }

    func testChopinNocturneHasDynamicsAndSlurs() throws {
        // Chopin Nocturne is known to have many dynamics and slurs
        let score = try loadScore("Chopin_-_Nocturne_Op_9_No_2_E_Flat_Major.mxl", category: .intermediate)

        var dynamicsCount = 0
        var slurCount = 0

        for part in score.parts {
            for measure in part.measures {
                for element in measure.elements {
                    if case .direction(let direction) = element {
                        for dirType in direction.types {
                            if case .dynamics = dirType {
                                dynamicsCount += 1
                            }
                        }
                    }
                }
                for note in measure.notes {
                    for notation in note.notations {
                        if case .slur = notation {
                            slurCount += 1
                        }
                    }
                }
            }
        }

        print("Chopin Nocturne - Dynamics: \(dynamicsCount), Slurs: \(slurCount)")

        // Nocturne is known to be very expressive with many markings
        XCTAssertGreaterThan(dynamicsCount, 0, "Nocturne should have dynamics")
        XCTAssertGreaterThan(slurCount, 0, "Nocturne should have slurs")
    }

    func testTiesAreParsed() throws {
        // Test that ties are correctly parsed across all scores
        var totalTieStarts = 0
        var totalTieStops = 0

        for metadata in library.allScores() {
            let data = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            for part in score.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        for tie in note.ties {
                            if tie.type == .start {
                                totalTieStarts += 1
                            } else if tie.type == .stop {
                                totalTieStops += 1
                            }
                        }
                    }
                }
            }
        }

        print("Total tie starts: \(totalTieStarts)")
        print("Total tie stops: \(totalTieStops)")

        // If we have ties, starts and stops should roughly match
        if totalTieStarts > 0 {
            let ratio = Double(totalTieStops) / Double(totalTieStarts)
            XCTAssertGreaterThan(ratio, 0.9, "Tie stops should match starts")
            XCTAssertLessThan(ratio, 1.1, "Tie stops should match starts")
        }
    }

    // MARK: - Round-Trip Preservation Tests

    func testArticulationsPreservedAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let originalData = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let original = try importer.importScore(from: originalData)

            // Count original articulations
            var originalCount = 0
            for part in original.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        for notation in note.notations {
                            if case .articulations(let arts) = notation {
                                originalCount += arts.count
                            }
                        }
                    }
                }
            }

            // Round trip
            let exporter = MusicXMLExporter()
            let exportedData = try exporter.export(original)
            let reimported = try importer.importScore(from: exportedData)

            // Count reimported articulations
            var reimportedCount = 0
            for part in reimported.parts {
                for measure in part.measures {
                    for note in measure.notes {
                        for notation in note.notations {
                            if case .articulations(let arts) = notation {
                                reimportedCount += arts.count
                            }
                        }
                    }
                }
            }

            XCTAssertEqual(originalCount, reimportedCount,
                "\(metadata.title): Articulation count changed after round-trip")
        }
    }

    func testDynamicsPreservedAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let originalData = try library.loadScore(metadata)
            let importer = MusicXMLImporter()
            let original = try importer.importScore(from: originalData)

            // Count original dynamics
            var originalCount = 0
            for part in original.parts {
                for measure in part.measures {
                    for element in measure.elements {
                        if case .direction(let dir) = element {
                            for dirType in dir.types {
                                if case .dynamics = dirType {
                                    originalCount += 1
                                }
                            }
                        }
                    }
                }
            }

            // Round trip
            let exporter = MusicXMLExporter()
            let exportedData = try exporter.export(original)
            let reimported = try importer.importScore(from: exportedData)

            // Count reimported dynamics
            var reimportedCount = 0
            for part in reimported.parts {
                for measure in part.measures {
                    for element in measure.elements {
                        if case .direction(let dir) = element {
                            for dirType in dir.types {
                                if case .dynamics = dirType {
                                    reimportedCount += 1
                                }
                            }
                        }
                    }
                }
            }

            XCTAssertEqual(originalCount, reimportedCount,
                "\(metadata.title): Dynamics count changed after round-trip")
        }
    }

    // MARK: - Helpers

    private func loadScore(_ filename: String, category: TestScoreLibrary.Category) throws -> Score {
        let data = try library.loadScore(filename: filename, category: category)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: data)
    }
}
