import XCTest
import MusicNotationCore
import MusicXMLImport
import MusicXMLExport

/// Tests for MIDI event validation.
final class MIDIValidationTests: MusicXMLValidationTestCase {

    var midiComparator: MIDIComparator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        midiComparator = MIDIComparator()
    }

    // MARK: - Event Extraction

    func testEventExtraction() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let score = try loadAndParse(metadata)
            let events = try midiComparator.extractEvents(from: score)

            // Should have note events
            let noteOnEvents = events.filter { $0.type == .noteOn }
            let noteOffEvents = events.filter { $0.type == .noteOff }

            XCTAssertGreaterThan(noteOnEvents.count, 0,
                "\(metadata.title) should have note-on events")
            XCTAssertEqual(noteOnEvents.count, noteOffEvents.count,
                "\(metadata.title) should have balanced note-on/off events")
        }
    }

    func testEventTiming() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let score = try loadAndParse(metadata)
            let events = try midiComparator.extractEvents(from: score)

            // Events should be in chronological order
            var lastTime: Double = 0
            for event in events {
                XCTAssertGreaterThanOrEqual(event.time, lastTime,
                    "\(metadata.title): Events should be in order")
                lastTime = event.time
            }

            // Duration should be positive
            if let firstNote = events.first(where: { $0.type == .noteOn }),
               let duration = findDuration(for: firstNote, in: events) {
                XCTAssertGreaterThan(duration, 0, "\(metadata.title): Note duration should be positive")
            }
        }
    }

    // MARK: - Round-Trip Comparison

    func testMIDIEventsPreservedAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let original = try loadAndParse(metadata)
            let reimported = try roundTrip(original)

            let originalEvents = try midiComparator.extractEvents(from: original)
            let reimportedEvents = try midiComparator.extractEvents(from: reimported)

            // Use wider tolerance for round-trip comparison
            var comparator = MIDIComparator(timeTolerance: 0.01)
            let result = comparator.compare(originalEvents, reimportedEvents)

            // Allow some tolerance for complex scores
            XCTAssertGreaterThan(result.similarity, 0.9,
                "\(metadata.title) MIDI similarity too low:\n\(result.report())")
        }
    }

    // MARK: - Note Count Comparison

    func testNoteCountsMatchAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let original = try loadAndParse(metadata)
            let reimported = try roundTrip(original)

            let originalEvents = try midiComparator.extractEvents(from: original)
            let reimportedEvents = try midiComparator.extractEvents(from: reimported)

            let originalNoteOns = originalEvents.filter { $0.type == .noteOn }.count
            let reimportedNoteOns = reimportedEvents.filter { $0.type == .noteOn }.count

            XCTAssertEqual(originalNoteOns, reimportedNoteOns,
                "\(metadata.title) note count mismatch: \(originalNoteOns) vs \(reimportedNoteOns)")
        }
    }

    // MARK: - Pitch Accuracy

    func testPitchAccuracyAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let original = try loadAndParse(metadata)
            let reimported = try roundTrip(original)

            let originalPitches = extractPitches(from: original)
            let reimportedPitches = extractPitches(from: reimported)

            XCTAssertEqual(originalPitches.count, reimportedPitches.count,
                "\(metadata.title) pitch count mismatch")

            // Compare pitch sets
            let originalSet = Set(originalPitches)
            let reimportedSet = Set(reimportedPitches)

            XCTAssertEqual(originalSet, reimportedSet,
                "\(metadata.title) pitch sets differ")
        }
    }

    // MARK: - Duration Accuracy

    func testDurationAccuracyAfterRoundTrip() throws {
        for metadata in library.scores(maxComplexity: .moderate) {
            let original = try loadAndParse(metadata)
            let reimported = try roundTrip(original)

            let originalDurations = extractDurations(from: original)
            let reimportedDurations = extractDurations(from: reimported)

            XCTAssertEqual(originalDurations.count, reimportedDurations.count,
                "\(metadata.title) duration count mismatch")

            // Check duration distribution is similar
            let originalSum = originalDurations.reduce(0, +)
            let reimportedSum = reimportedDurations.reduce(0, +)

            // Allow 1% tolerance
            let tolerance = max(1, originalSum / 100)
            XCTAssertEqual(originalSum, reimportedSum, accuracy: tolerance,
                "\(metadata.title) total duration mismatch")
        }
    }

    // MARK: - Specific Score Tests

    func testBachMinuetMIDI() throws {
        let score = try loadScore("Bach_Minuet_in_G_Major_BWV_Anh._114.mxl", category: .basic)
        let events = try midiComparator.extractEvents(from: score)

        let noteOns = events.filter { $0.type == .noteOn }
        XCTAssertGreaterThan(noteOns.count, 50, "Bach Minuet should have many notes")

        // Check timing makes sense for 3/4 time
        // First three beats should complete in time
        let firstMeasureEvents = events.filter { $0.time < 2.0 }  // Assuming ~120 BPM
        XCTAssertGreaterThan(firstMeasureEvents.count, 0, "Should have events in first measure")
    }

    func testDrumKitMIDI() throws {
        let score = try loadScore("drum_kit.musicxml", category: .percussion)
        let events = try midiComparator.extractEvents(from: score)

        // Should have note events
        let noteOnEvents = events.filter { $0.type == .noteOn }
        XCTAssertGreaterThan(noteOnEvents.count, 0, "Drum kit should have note events")

        // Verify score is detected as percussion
        XCTAssertTrue(score.parts[0].isPercussion, "Drum kit should be detected as percussion")
    }

    // MARK: - Helpers

    private func loadAndParse(_ metadata: TestScoreLibrary.ScoreMetadata) throws -> Score {
        let data = try library.loadScore(metadata)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: data)
    }

    private func loadScore(_ filename: String, category: TestScoreLibrary.Category) throws -> Score {
        let data = try library.loadScore(filename: filename, category: category)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: data)
    }

    private func roundTrip(_ score: Score) throws -> Score {
        let exporter = MusicXMLExporter()
        let exportedData = try exporter.export(score)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: exportedData)
    }

    private func findDuration(for noteOn: MIDIComparator.MIDIEvent, in events: [MIDIComparator.MIDIEvent]) -> Double? {
        guard noteOn.type == .noteOn, let pitch = noteOn.pitch else { return nil }

        // Find matching note-off
        for event in events {
            if event.type == .noteOff && event.pitch == pitch && event.time > noteOn.time {
                return event.time - noteOn.time
            }
        }
        return nil
    }

    private func extractPitches(from score: Score) -> [UInt8] {
        var pitches: [UInt8] = []
        for part in score.parts {
            for measure in part.measures {
                for note in measure.notes where note.pitch != nil {
                    let pitch = note.pitch!
                    let midi = pitchToMIDI(pitch)
                    pitches.append(midi)
                }
            }
        }
        return pitches
    }

    private func extractDurations(from score: Score) -> [Int] {
        var durations: [Int] = []
        for part in score.parts {
            for measure in part.measures {
                for note in measure.notes where !note.isRest {
                    durations.append(note.durationDivisions)
                }
            }
        }
        return durations
    }

    private func pitchToMIDI(_ pitch: Pitch) -> UInt8 {
        let stepValue: Int
        switch pitch.step {
        case .c: stepValue = 0
        case .d: stepValue = 2
        case .e: stepValue = 4
        case .f: stepValue = 5
        case .g: stepValue = 7
        case .a: stepValue = 9
        case .b: stepValue = 11
        }
        let midi = (pitch.octave + 1) * 12 + stepValue + Int(pitch.alter)
        return UInt8(clamping: midi)
    }
}
