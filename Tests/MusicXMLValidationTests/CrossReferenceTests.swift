import XCTest
import MusicNotationCore
import MusicXMLImport

/// Tests that cross-reference Swift parsing against music21.
/// These tests require Python and music21 to be installed.
final class CrossReferenceTests: MusicXMLValidationTestCase {

    var music21Comparator: Music21Comparator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        music21Comparator = Music21Comparator()
    }

    // MARK: - Availability Check

    func testMusic21IsAvailable() throws {
        // This test checks if music21 is available
        // It's expected to be skipped in most CI environments
        if !Music21Comparator.isAvailable {
            throw XCTSkip("music21 not installed - skipping cross-reference tests")
        }
    }

    // MARK: - Part Count Comparison

    func testPartCountMatches() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        for metadata in library.scores(maxComplexity: .moderate) {
            guard let url = library.url(for: metadata) else { continue }

            do {
                let swiftScore = try loadAndParse(metadata)
                let music21Result = try music21Comparator.parseWithMusic21(path: url)

                // Part counts may differ slightly due to how grand staff is handled
                // Allow difference of up to 1
                let partDiff = abs(swiftScore.parts.count - (music21Result.partCount ?? 0))
                XCTAssertLessThanOrEqual(
                    partDiff, 1,
                    "Part count differs too much for \(metadata.title): Swift=\(swiftScore.parts.count), music21=\(music21Result.partCount ?? 0)"
                )
            } catch Music21Error.notAvailable {
                throw XCTSkip("music21 not installed")
            } catch {
                XCTFail("Error comparing \(metadata.title): \(error)")
            }
        }
    }

    // MARK: - Note Count Comparison

    func testNoteCountMatches() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        // Only test pitched scores (percussion is handled differently by parsers)
        let pitchedScores = library.scores(maxComplexity: .moderate).filter { metadata in
            !metadata.expectedFeatures.contains(.unpitchedNotes)
        }

        for metadata in pitchedScores {
            guard let url = library.url(for: metadata) else { continue }

            do {
                let swiftScore = try loadAndParse(metadata)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

                // Allow 15% tolerance for counting differences (grace notes, rests, etc.)
                let tolerance = max(10, result.music21NoteCount / 7)
                XCTAssertEqual(
                    result.swiftNoteCount, result.music21NoteCount, accuracy: tolerance,
                    "\(metadata.title): Note count differs significantly (Swift: \(result.swiftNoteCount), music21: \(result.music21NoteCount))"
                )
            } catch Music21Error.notAvailable {
                throw XCTSkip("music21 not installed")
            } catch {
                XCTFail("Error comparing \(metadata.title): \(error)")
            }
        }
    }

    // MARK: - Pitch Comparison

    func testPitchSimilarity() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        // Only test pitched scores (percussion doesn't have MIDI pitches in the same way)
        let pitchedScores = library.scores(maxComplexity: .simple).filter { metadata in
            !metadata.expectedFeatures.contains(.unpitchedNotes)
        }

        for metadata in pitchedScores {
            guard let url = library.url(for: metadata) else { continue }

            do {
                let swiftScore = try loadAndParse(metadata)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

                // At least 80% of pitches should match
                XCTAssertGreaterThan(
                    result.similarity, 0.8,
                    "\(metadata.title): Pitch similarity too low (\(String(format: "%.1f", result.similarity * 100))%)"
                )
            } catch Music21Error.notAvailable {
                throw XCTSkip("music21 not installed")
            } catch {
                XCTFail("Error comparing \(metadata.title): \(error)")
            }
        }
    }

    // MARK: - Individual Score Tests

    func testBachMinuetCrossReference() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        let scores = library.scores(for: .basic).filter { $0.filename.contains("Bach_Minuet") }
        guard let metadata = scores.first else {
            throw XCTSkip("Bach Minuet not found")
        }

        guard let url = library.url(for: metadata) else {
            throw XCTSkip("Bach Minuet file not found")
        }

        let swiftScore = try loadAndParse(metadata)
        let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

        // This is a simple score, should have high similarity
        XCTAssertGreaterThan(result.similarity, 0.9,
            "Bach Minuet should have high pitch similarity")

        // Print comparison details
        print("Bach Minuet cross-reference:")
        print("  Swift notes: \(result.swiftNoteCount)")
        print("  music21 notes: \(result.music21NoteCount)")
        print("  Pitch matches: \(result.pitchMatches)")
        print("  Similarity: \(String(format: "%.1f", result.similarity * 100))%")
    }

    func testDrumKitCrossReference() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        let scores = library.scores(for: .percussion).filter { $0.filename.contains("drum_kit") }
        guard let metadata = scores.first else {
            throw XCTSkip("Drum kit not found")
        }

        guard let url = library.url(for: metadata) else {
            throw XCTSkip("Drum kit file not found")
        }

        let swiftScore = try loadAndParse(metadata)

        do {
            let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

            print("Drum kit cross-reference:")
            print("  Swift notes: \(result.swiftNoteCount)")
            print("  music21 notes: \(result.music21NoteCount)")
            print("  Discrepancies: \(result.discrepancies.count)")
        } catch Music21Error.parseError(let message) {
            // Some MusicXML files may not be fully supported by music21
            print("Note: music21 parse error for drum kit: \(message)")
        }
    }

    // MARK: - Test Suite Cross-Reference

    func testMusicXMLTestSuiteCrossReference() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        // Get test suite files
        let testSuitePath = "/tmp/musicxmlTestSuite/xmlFiles"
        let fm = FileManager.default
        guard fm.fileExists(atPath: testSuitePath) else {
            throw XCTSkip("Test suite not found at \(testSuitePath)")
        }

        let files = try fm.contentsOfDirectory(atPath: testSuitePath)
            .filter { $0.hasSuffix(".xml") }
            .sorted()

        var totalSwiftPitched = 0
        var totalMusic21Pitched = 0
        var totalPitchMatches = 0
        var totalBothMatches = 0
        var parsedCount = 0
        var lowAccuracyFiles: [(String, Double)] = []

        for file in files {
            let url = URL(fileURLWithPath: testSuitePath).appendingPathComponent(file)
            do {
                let data = try Data(contentsOf: url)
                let importer = MusicXMLImporter()
                let score = try importer.importScore(from: data)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: score)

                totalSwiftPitched += result.swiftPitchedCount
                totalMusic21Pitched += result.music21PitchedCount
                totalPitchMatches += result.pitchMatches
                totalBothMatches += result.pitchAndDurationMatches
                parsedCount += 1

                // Track files with low accuracy
                if result.pitchSimilarity < 0.95 && result.swiftPitchedCount > 0 {
                    lowAccuracyFiles.append((file, result.pitchSimilarity))
                }
            } catch {
                // Skip files that can't be parsed by either parser
                continue
            }
        }

        let pitchAccuracy = totalSwiftPitched > 0 ? Double(totalPitchMatches) / Double(min(totalSwiftPitched, totalMusic21Pitched)) : 1.0
        let bothAccuracy = totalSwiftPitched > 0 ? Double(totalBothMatches) / Double(min(totalSwiftPitched, totalMusic21Pitched)) : 1.0

        print("\nMusicXML Test Suite Cross-Reference:")
        print("  Files parsed: \(parsedCount)/\(files.count)")
        print("  Swift pitched notes: \(totalSwiftPitched)")
        print("  music21 pitched notes: \(totalMusic21Pitched)")
        print("  Pitch matches: \(totalPitchMatches) (\(String(format: "%.1f", pitchAccuracy * 100))%)")
        print("  Pitch+Duration matches: \(totalBothMatches) (\(String(format: "%.1f", bothAccuracy * 100))%)")

        if !lowAccuracyFiles.isEmpty {
            print("  Low accuracy files:")
            for (file, accuracy) in lowAccuracyFiles.sorted(by: { $0.1 < $1.1 }).prefix(5) {
                print("    \(file): \(String(format: "%.1f", accuracy * 100))%")
            }
        }

        // Assertions
        XCTAssertGreaterThan(parsedCount, files.count * 9 / 10, "Should parse 90%+ of test suite files")
        XCTAssertGreaterThan(pitchAccuracy, 0.95, "Pitch accuracy should be at least 95%")
        XCTAssertGreaterThan(bothAccuracy, 0.90, "Pitch+Duration accuracy should be at least 90%")
    }

    // MARK: - Notations Accuracy

    func testNotationsAccuracy() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        var totalSwiftArticulations = 0
        var totalMusic21Articulations = 0
        var totalSwiftDynamics = 0
        var totalMusic21Dynamics = 0
        var totalSwiftSlurs = 0
        var totalMusic21Slurs = 0
        var totalSwiftExpressions = 0
        var totalMusic21Expressions = 0
        var successCount = 0

        var perFileDetails: [(String, Int, Int, Int, Int)] = []  // (title, swiftArt, m21Art, swiftExpr, m21Expr)

        for metadata in library.allScores() {
            guard let url = library.url(for: metadata) else { continue }

            do {
                let swiftScore = try loadAndParse(metadata)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

                totalSwiftArticulations += result.swiftArticulationCount
                totalMusic21Articulations += result.music21ArticulationCount
                totalSwiftDynamics += result.swiftDynamicsCount
                totalMusic21Dynamics += result.music21DynamicsCount
                totalSwiftSlurs += result.swiftSlurCount
                totalMusic21Slurs += result.music21SlurCount
                totalSwiftExpressions += result.swiftExpressionCount
                totalMusic21Expressions += result.music21ExpressionCount
                successCount += 1

                perFileDetails.append((
                    metadata.title,
                    result.swiftArticulationCount,
                    result.music21ArticulationCount,
                    result.swiftExpressionCount,
                    result.music21ExpressionCount
                ))
            } catch {
                continue
            }
        }

        guard successCount > 0 else {
            throw XCTSkip("No files could be compared")
        }

        // Print per-file breakdown for articulations (sorted by gap)
        print("\nPer-file articulation breakdown (sorted by gap):")
        for (title, swiftArt, m21Art, swiftExpr, m21Expr) in perFileDetails.sorted(by: { abs($0.2 - $0.1) > abs($1.2 - $1.1) }) {
            let gap = m21Art - swiftArt
            let exprGap = m21Expr - swiftExpr
            if gap != 0 || exprGap != 0 {
                print("  \(title): art=\(swiftArt)/\(m21Art) (gap=\(gap)), expr=\(swiftExpr)/\(m21Expr) (gap=\(exprGap))")
            }
        }

        print("\nNotations Cross-Reference (Core Library):")
        print("  Files compared: \(successCount)")
        print("  Articulations: Swift=\(totalSwiftArticulations), music21=\(totalMusic21Articulations)")
        print("  Dynamics: Swift=\(totalSwiftDynamics), music21=\(totalMusic21Dynamics)")
        print("  Slurs: Swift=\(totalSwiftSlurs), music21=\(totalMusic21Slurs)")
        print("  Expressions/Ornaments: Swift=\(totalSwiftExpressions), music21=\(totalMusic21Expressions)")

        // Calculate similarity for each notation type
        let artSim = similarityRatio(totalSwiftArticulations, totalMusic21Articulations)
        let dynSim = similarityRatio(totalSwiftDynamics, totalMusic21Dynamics)
        let slurSim = similarityRatio(totalSwiftSlurs, totalMusic21Slurs)

        print("  Articulation similarity: \(String(format: "%.1f", artSim * 100))%")
        print("  Dynamics similarity: \(String(format: "%.1f", dynSim * 100))%")
        print("  Slur similarity: \(String(format: "%.1f", slurSim * 100))%")
    }

    func testNotationsAccuracyTestSuite() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        // Get test suite files
        let testSuitePath = "/tmp/musicxmlTestSuite/xmlFiles"
        let fm = FileManager.default
        guard fm.fileExists(atPath: testSuitePath) else {
            throw XCTSkip("Test suite not found at \(testSuitePath)")
        }

        let files = try fm.contentsOfDirectory(atPath: testSuitePath)
            .filter { $0.hasSuffix(".xml") }
            .sorted()

        var totalSwiftArticulations = 0
        var totalMusic21Articulations = 0
        var totalSwiftDynamics = 0
        var totalMusic21Dynamics = 0
        var totalSwiftSlurs = 0
        var totalMusic21Slurs = 0
        var totalSwiftExpressions = 0
        var totalMusic21Expressions = 0
        var parsedCount = 0

        for file in files {
            let url = URL(fileURLWithPath: testSuitePath).appendingPathComponent(file)
            do {
                let data = try Data(contentsOf: url)
                let importer = MusicXMLImporter()
                let score = try importer.importScore(from: data)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: score)

                totalSwiftArticulations += result.swiftArticulationCount
                totalMusic21Articulations += result.music21ArticulationCount
                totalSwiftDynamics += result.swiftDynamicsCount
                totalMusic21Dynamics += result.music21DynamicsCount
                totalSwiftSlurs += result.swiftSlurCount
                totalMusic21Slurs += result.music21SlurCount
                totalSwiftExpressions += result.swiftExpressionCount
                totalMusic21Expressions += result.music21ExpressionCount
                parsedCount += 1
            } catch {
                continue
            }
        }

        let artSim = similarityRatio(totalSwiftArticulations, totalMusic21Articulations)
        let dynSim = similarityRatio(totalSwiftDynamics, totalMusic21Dynamics)
        let slurSim = similarityRatio(totalSwiftSlurs, totalMusic21Slurs)

        print("\nNotations Cross-Reference (Test Suite):")
        print("  Files parsed: \(parsedCount)/\(files.count)")
        print("  Articulations: Swift=\(totalSwiftArticulations), music21=\(totalMusic21Articulations) (\(String(format: "%.1f", artSim * 100))%)")
        print("  Dynamics: Swift=\(totalSwiftDynamics), music21=\(totalMusic21Dynamics) (\(String(format: "%.1f", dynSim * 100))%)")
        print("  Slurs: Swift=\(totalSwiftSlurs), music21=\(totalMusic21Slurs) (\(String(format: "%.1f", slurSim * 100))%)")
        print("  Expressions/Ornaments: Swift=\(totalSwiftExpressions), music21=\(totalMusic21Expressions)")

        // Report on notation parsing - these are informational for now
        // as we establish baseline metrics
        XCTAssertGreaterThan(parsedCount, files.count * 9 / 10, "Should parse 90%+ of test suite files")
    }

    private func similarityRatio(_ a: Int, _ b: Int) -> Double {
        let maxVal = max(a, b)
        guard maxVal > 0 else { return 1.0 }
        let minVal = min(a, b)
        return Double(minVal) / Double(maxVal)
    }

    // MARK: - Summary Statistics

    func testCrossReferenceSummary() throws {
        guard Music21Comparator.isAvailable else {
            throw XCTSkip("music21 not installed")
        }

        var totalSwiftPitched = 0
        var totalMusic21Pitched = 0
        var totalPitchMatches = 0
        var totalDurationMatches = 0
        var totalBothMatches = 0
        var successCount = 0
        var perFileResults: [(String, Int, Int, Int, Int, Double, Double)] = []

        for metadata in library.allScores() {
            guard let url = library.url(for: metadata) else { continue }

            do {
                let swiftScore = try loadAndParse(metadata)
                let result = try music21Comparator.compare(musicxmlPath: url, swiftScore: swiftScore)

                totalSwiftPitched += result.swiftPitchedCount
                totalMusic21Pitched += result.music21PitchedCount
                totalPitchMatches += result.pitchMatches
                totalDurationMatches += result.durationMatches
                totalBothMatches += result.pitchAndDurationMatches
                successCount += 1

                perFileResults.append((
                    metadata.title,
                    result.swiftPitchedCount,
                    result.music21PitchedCount,
                    result.pitchMatches,
                    result.pitchAndDurationMatches,
                    result.pitchSimilarity,
                    result.durationSimilarity
                ))
            } catch {
                // Skip files that fail
                continue
            }
        }

        // Print per-file breakdown sorted by combined similarity
        print("\nPer-file comparison (sorted by pitch+duration similarity):")
        for (title, swiftPitched, _, _, bothMatches, pitchSim, durSim) in perFileResults.sorted(by: { $0.6 < $1.6 }) {
            print("  pitch=\(String(format: "%5.1f", pitchSim * 100))% dur=\(String(format: "%5.1f", durSim * 100))% | \(title): \(bothMatches)/\(swiftPitched) exact matches")
        }

        guard successCount > 0 else {
            throw XCTSkip("No files could be compared")
        }

        let minPitched = min(totalSwiftPitched, totalMusic21Pitched)
        let overallPitchSimilarity = Double(totalPitchMatches) / Double(max(1, minPitched))
        let overallDurationSimilarity = Double(totalDurationMatches) / Double(max(1, minPitched))
        let overallBothSimilarity = Double(totalBothMatches) / Double(max(1, minPitched))

        print("\nCross-reference summary:")
        print("  Files compared: \(successCount)")
        print("  Total Swift pitched notes: \(totalSwiftPitched)")
        print("  Total music21 pitched notes: \(totalMusic21Pitched)")
        print("  Pitch matches: \(totalPitchMatches) (\(String(format: "%.1f", overallPitchSimilarity * 100))%)")
        print("  Duration matches: \(totalDurationMatches) (\(String(format: "%.1f", overallDurationSimilarity * 100))%)")
        print("  Pitch+Duration matches: \(totalBothMatches) (\(String(format: "%.1f", overallBothSimilarity * 100))%)")

        // Overall similarity should be at least 95% for pitched notes
        XCTAssertGreaterThan(overallPitchSimilarity, 0.95,
            "Overall pitch similarity should be at least 95%")
        XCTAssertGreaterThan(overallDurationSimilarity, 0.90,
            "Overall duration similarity should be at least 90%")
    }

    // MARK: - Helpers

    private func loadAndParse(_ metadata: TestScoreLibrary.ScoreMetadata) throws -> Score {
        let data = try library.loadScore(metadata)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: data)
    }
}

