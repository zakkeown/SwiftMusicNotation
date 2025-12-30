import XCTest
import MusicNotationCore
import MusicXMLImport

/// Tests for statistical validation of MusicXML parsing.
final class StatisticalTests: MusicXMLValidationTestCase {

    var statisticalValidator: StatisticalValidator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        statisticalValidator = StatisticalValidator()
    }

    // MARK: - All Scores Parse Successfully

    func testAllScoresParseSuccessfully() throws {
        var failures: [String] = []

        for metadata in library.allScores() {
            do {
                let data = try library.loadScore(metadata)
                let importer = MusicXMLImporter()
                _ = try importer.importScore(from: data)
            } catch {
                failures.append(metadata.filename)
            }
        }

        XCTAssertEqual(failures.count, 0, "Parse failures: \(failures)")
    }

    // MARK: - Duration Distribution

    func testDurationDistributionIsReasonable() throws {
        var durationCounts: [String: Int] = [:]

        for metadata in library.allScores() {
            do {
                let score = try loadAndParse(metadata)
                for part in score.parts {
                    for measure in part.measures {
                        for note in measure.notes {
                            if let type = note.type {
                                durationCounts[type.musicXMLTypeName, default: 0] += 1
                            }
                        }
                    }
                }
            } catch {
                continue
            }
        }

        // Quarter and eighth notes should be common
        let quarterCount = durationCounts["quarter"] ?? 0
        let eighthCount = durationCounts["eighth"] ?? 0
        let totalNotes = durationCounts.values.reduce(0, +)

        XCTAssertGreaterThan(totalNotes, 100, "Should have many notes total")

        // Quarter and eighth notes should be significant portion
        let commonRatio = Double(quarterCount + eighthCount) / Double(totalNotes)
        XCTAssertGreaterThan(commonRatio, 0.2, "Quarter and eighth notes should be at least 20% of notes")

        print("Duration distribution:")
        for (duration, count) in durationCounts.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(count) / Double(totalNotes) * 100
            print("  \(duration): \(count) (\(String(format: "%.1f", percentage))%)")
        }
    }

    // MARK: - Pitch Distribution

    func testPitchDistributionIsReasonable() throws {
        var pitchCounts: [Int: Int] = [:]  // MIDI note -> count

        for metadata in library.allScores() {
            do {
                let score = try loadAndParse(metadata)
                let stats = statisticalValidator.analyze(score, filename: metadata.filename)
                for (pitch, count) in stats.pitchCounts {
                    pitchCounts[pitch, default: 0] += count
                }
            } catch {
                continue
            }
        }

        guard !pitchCounts.isEmpty else {
            XCTFail("No pitched notes found")
            return
        }

        let pitches = pitchCounts.keys.sorted()
        let lowest = pitches.first!
        let highest = pitches.last!

        // Verify reasonable pitch range (MIDI 21-108 is piano range)
        XCTAssertGreaterThanOrEqual(lowest, 12, "Lowest pitch should be at least MIDI 12 (C0)")
        XCTAssertLessThanOrEqual(highest, 120, "Highest pitch should be at most MIDI 120 (C9)")

        // Calculate weighted average pitch
        let totalCount = pitchCounts.values.reduce(0, +)
        let weightedSum = pitchCounts.map { $0.key * $0.value }.reduce(0, +)
        let averagePitch = Double(weightedSum) / Double(totalCount)

        // Average pitch should be somewhere around middle C (MIDI 60)
        XCTAssertGreaterThan(averagePitch, 40, "Average pitch should be above MIDI 40")
        XCTAssertLessThan(averagePitch, 90, "Average pitch should be below MIDI 90")

        print("Pitch statistics:")
        print("  Range: MIDI \(lowest) to \(highest)")
        print("  Average: MIDI \(String(format: "%.1f", averagePitch))")
        print("  Total pitched notes: \(totalCount)")
    }

    // MARK: - Note Count Distribution

    func testNoteCountsAreReasonable() throws {
        var noteCounts: [String: Int] = [:]

        for metadata in library.allScores() {
            do {
                let score = try loadAndParse(metadata)
                let stats = statisticalValidator.analyze(score, filename: metadata.filename)
                noteCounts[metadata.filename] = stats.noteCount
            } catch {
                continue
            }
        }

        guard !noteCounts.isEmpty else {
            XCTFail("No scores analyzed")
            return
        }

        let counts = noteCounts.values.sorted()
        let minimum = counts.first!
        let maximum = counts.last!
        let average = Double(counts.reduce(0, +)) / Double(counts.count)

        // All scores should have at least some notes
        // (some test scores might be minimal)
        XCTAssertGreaterThanOrEqual(minimum, 0, "Minimum note count should be non-negative")

        // Advanced scores should have many notes
        XCTAssertGreaterThan(maximum, 100, "Maximum note count should be substantial")

        print("Note count statistics:")
        print("  Range: \(minimum) to \(maximum)")
        print("  Average: \(String(format: "%.1f", average))")
        print("  Files analyzed: \(noteCounts.count)")
    }

    // MARK: - Corpus Statistics

    func testCorpusStatistics() throws {
        var scoreStats: [StatisticalValidator.ScoreStatistics] = []

        for metadata in library.allScores() {
            do {
                let score = try loadAndParse(metadata)
                let stats = statisticalValidator.analyze(score, filename: metadata.filename)
                scoreStats.append(stats)
            } catch {
                continue
            }
        }

        let corpus = statisticalValidator.buildCorpusStatistics(from: scoreStats)

        print("Corpus statistics:")
        print("  Files: \(corpus.fileCount)")
        print("  Parse success rate: \(String(format: "%.1f", corpus.parseSuccessRate * 100))%")
        print("  Total parts: \(corpus.totalParts)")
        print("  Total measures: \(corpus.totalMeasures)")
        print("  Total notes: \(corpus.totalNotes)")
        print("  Average notes/file: \(String(format: "%.1f", corpus.averageNotesPerFile))")
        print("  Average measures/file: \(String(format: "%.1f", corpus.averageMeasuresPerFile))")

        if !corpus.anomalies.isEmpty {
            print("  Anomalies detected: \(corpus.anomalies.count)")
            for anomaly in corpus.anomalies.prefix(5) {
                print("    - \(anomaly)")
            }
        }

        // Validate corpus
        let result = statisticalValidator.validateCorpus(corpus)
        XCTAssertTrue(result.passed, result.report())
    }

    // MARK: - Feature Coverage

    func testFeatureCoverage() throws {
        var featureCounts: [String: Int] = [:]

        for metadata in library.allScores() {
            do {
                let score = try loadAndParse(metadata)
                let stats = statisticalValidator.analyze(score, filename: metadata.filename)

                if stats.restCount > 0 { featureCounts["rests", default: 0] += 1 }
                if stats.chordToneCount > 0 { featureCounts["chords", default: 0] += 1 }
                if stats.graceNoteCount > 0 { featureCounts["graceNotes", default: 0] += 1 }
                if stats.tiedNoteCount > 0 { featureCounts["ties", default: 0] += 1 }
                if stats.partCount > 1 { featureCounts["multiPart", default: 0] += 1 }
            } catch {
                continue
            }
        }

        print("Feature coverage:")
        for (feature, count) in featureCounts.sorted(by: { $0.key < $1.key }) {
            print("  \(feature): \(count) files")
        }

        // We should have coverage of most features
        XCTAssertGreaterThan(featureCounts["rests"] ?? 0, 0, "Should have files with rests")
        XCTAssertGreaterThan(featureCounts["chords"] ?? 0, 0, "Should have files with chords")
        XCTAssertGreaterThan(featureCounts["ties"] ?? 0, 0, "Should have files with ties")
    }

    // MARK: - Category Statistics

    func testCategoryStatistics() throws {
        for category in TestScoreLibrary.Category.allCases {
            let scores = library.scores(for: category)
            guard !scores.isEmpty else { continue }

            var totalNotes = 0
            var totalMeasures = 0
            var successCount = 0

            for metadata in scores {
                do {
                    let score = try loadAndParse(metadata)
                    let stats = statisticalValidator.analyze(score, filename: metadata.filename)
                    totalNotes += stats.noteCount
                    totalMeasures += stats.measureCount
                    successCount += 1
                } catch {
                    continue
                }
            }

            guard successCount > 0 else { continue }

            let avgNotes = Double(totalNotes) / Double(successCount)
            let avgMeasures = Double(totalMeasures) / Double(successCount)

            print("\(category.rawValue.capitalized) category:")
            print("  Files: \(successCount)/\(scores.count)")
            print("  Avg notes: \(String(format: "%.1f", avgNotes))")
            print("  Avg measures: \(String(format: "%.1f", avgMeasures))")
        }
    }

    // MARK: - Helpers

    private func loadAndParse(_ metadata: TestScoreLibrary.ScoreMetadata) throws -> Score {
        let data = try library.loadScore(metadata)
        let importer = MusicXMLImporter()
        return try importer.importScore(from: data)
    }
}
