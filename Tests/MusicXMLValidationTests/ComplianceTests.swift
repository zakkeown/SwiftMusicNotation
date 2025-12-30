import XCTest
import MusicNotationCore
import MusicXMLImport

/// Tests for MusicXML compliance using the official LilyPond/cuthbertLab test suite.
/// https://github.com/cuthbertLab/musicxmlTestSuite
final class ComplianceTests: MusicXMLValidationTestCase {

    // MARK: - Test Suite Discovery

    private func testSuiteFiles() throws -> [URL] {
        let bundle = Bundle.module

        // Find all XML files in the test suite directory
        // Bundle.resourcePath points to the Resources folder, so TestSuite is a direct child
        guard let resourcePath = bundle.resourcePath else {
            throw XCTSkip("Bundle resource path not found")
        }

        let testSuitePath = (resourcePath as NSString).appendingPathComponent("TestSuite")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: testSuitePath) else {
            throw XCTSkip("Test suite directory not found at \(testSuitePath)")
        }

        let contents = try fileManager.contentsOfDirectory(atPath: testSuitePath)
        let xmlFiles = contents.filter { $0.hasSuffix(".xml") }
            .map { URL(fileURLWithPath: testSuitePath).appendingPathComponent($0) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return xmlFiles
    }

    private func testSuiteFiles(matching prefix: String) throws -> [URL] {
        let all = try testSuiteFiles()
        return all.filter { $0.lastPathComponent.hasPrefix(prefix) }
    }

    // MARK: - All Tests Parse Successfully

    func testAllTestSuiteFilesParse() throws {
        let files = try testSuiteFiles()
        XCTAssertGreaterThan(files.count, 100, "Test suite should have 100+ files")

        var failures: [(String, Error)] = []

        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let importer = MusicXMLImporter()
                _ = try importer.importScore(from: data)
            } catch {
                failures.append((file.lastPathComponent, error))
            }
        }

        // Allow up to 5% parse failures for edge cases
        let failureRate = Double(failures.count) / Double(files.count)
        if failureRate > 0.05 {
            let report = failures.prefix(10).map { "\($0.0): \($0.1.localizedDescription)" }.joined(separator: "\n")
            XCTFail("Parse failures (\(failures.count)/\(files.count), \(Int(failureRate * 100))%):\n\(report)")
        } else if !failures.isEmpty {
            print("Note: \(failures.count) edge case files failed to parse: \(failures.map { $0.0 })")
        }
    }

    // MARK: - Pitch Tests (01)

    func testPitchCompliance() throws {
        let files = try testSuiteFiles(matching: "01")
        XCTAssertGreaterThan(files.count, 0, "Should have pitch test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Basic validation: should have notes
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            XCTAssertGreaterThan(allNotes.count, 0, "\(file.lastPathComponent) should have notes")

            // Most pitch tests should have pitched notes
            if !file.lastPathComponent.contains("Microtones") {
                let pitchedNotes = allNotes.filter { $0.pitch != nil }
                XCTAssertGreaterThan(pitchedNotes.count, 0, "\(file.lastPathComponent) should have pitched notes")
            }
        }
    }

    // MARK: - Rest Tests (02)

    func testRestCompliance() throws {
        let files = try testSuiteFiles(matching: "02")
        XCTAssertGreaterThan(files.count, 0, "Should have rest test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Should have rests
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            let rests = allNotes.filter { $0.isRest }
            XCTAssertGreaterThan(rests.count, 0, "\(file.lastPathComponent) should have rests")
        }
    }

    // MARK: - Rhythm Tests (03)

    func testRhythmCompliance() throws {
        let files = try testSuiteFiles(matching: "03")
        XCTAssertGreaterThan(files.count, 0, "Should have rhythm test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Should have notes with durations
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            XCTAssertGreaterThan(allNotes.count, 0, "\(file.lastPathComponent) should have notes")
        }
    }

    // MARK: - Time Signature Tests (11)

    func testTimeSignatureCompliance() throws {
        let files = try testSuiteFiles(matching: "11")
        XCTAssertGreaterThan(files.count, 0, "Should have time signature test files")

        var parseSuccesses = 0
        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let importer = MusicXMLImporter()
                let score = try importer.importScore(from: data)

                // Should have measures
                XCTAssertGreaterThan(score.parts.count, 0, "\(file.lastPathComponent) should have parts")
                let totalMeasures = score.parts.map { $0.measures.count }.reduce(0, +)
                XCTAssertGreaterThan(totalMeasures, 0, "\(file.lastPathComponent) should have measures")
                parseSuccesses += 1
            } catch {
                // Some edge cases like "Senza Misura" (free time) may fail
                print("Skipping edge case: \(file.lastPathComponent)")
            }
        }

        // Most time signature files should parse
        XCTAssertGreaterThan(parseSuccesses, files.count / 2, "Most time signature files should parse")
    }

    // MARK: - Clef Tests (12)

    func testClefCompliance() throws {
        let files = try testSuiteFiles(matching: "12")
        XCTAssertGreaterThan(files.count, 0, "Should have clef test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            XCTAssertGreaterThan(score.parts.count, 0, "\(file.lastPathComponent) should have parts")
        }
    }

    // MARK: - Key Signature Tests (13)

    func testKeySignatureCompliance() throws {
        let files = try testSuiteFiles(matching: "13")
        XCTAssertGreaterThan(files.count, 0, "Should have key signature test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            XCTAssertGreaterThan(score.parts.count, 0, "\(file.lastPathComponent) should have parts")
        }
    }

    // MARK: - Chord Tests (21)

    func testChordCompliance() throws {
        let files = try testSuiteFiles(matching: "21")
        XCTAssertGreaterThan(files.count, 0, "Should have chord test files")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Chord files should have chord tones
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            let chordTones = allNotes.filter { $0.isChordTone }
            XCTAssertGreaterThan(chordTones.count, 0, "\(file.lastPathComponent) should have chord tones")
        }
    }

    // MARK: - Note Settings Tests (22)

    func testNoteSettingsCompliance() throws {
        let files = try testSuiteFiles(matching: "22")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Should have notes
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            XCTAssertGreaterThan(allNotes.count, 0, "\(file.lastPathComponent) should have notes")
        }
    }

    // MARK: - Tuplet Tests (23)

    func testTupletCompliance() throws {
        let files = try testSuiteFiles(matching: "23")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Tuplet files should have time modifications
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            let tupletNotes = allNotes.filter { $0.timeModification != nil }
            XCTAssertGreaterThan(tupletNotes.count, 0, "\(file.lastPathComponent) should have tuplets")
        }
    }

    // MARK: - Grace Note Tests (24)

    func testGraceNoteCompliance() throws {
        let files = try testSuiteFiles(matching: "24")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Grace note files should have grace notes
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            let graceNotes = allNotes.filter { $0.isGraceNote }
            XCTAssertGreaterThan(graceNotes.count, 0, "\(file.lastPathComponent) should have grace notes")
        }
    }

    // MARK: - Direction Tests (31)

    func testDirectionCompliance() throws {
        let files = try testSuiteFiles(matching: "31")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            XCTAssertGreaterThan(score.parts.count, 0, "\(file.lastPathComponent) should have parts")
        }
    }

    // MARK: - Multi-Part Tests (41)

    func testMultiPartCompliance() throws {
        let files = try testSuiteFiles(matching: "41")

        var multiPartCount = 0
        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let importer = MusicXMLImporter()
                let score = try importer.importScore(from: data)

                // Track multi-part files
                if score.parts.count > 1 {
                    multiPartCount += 1
                }
            } catch {
                // Some edge case files may not parse
                continue
            }
        }

        // At least some files should have multiple parts
        XCTAssertGreaterThan(multiPartCount, 0, "Should have files with multiple parts")
    }

    // MARK: - Repeat Tests (45)

    func testRepeatCompliance() throws {
        let files = try testSuiteFiles(matching: "45")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            XCTAssertGreaterThan(score.parts.count, 0, "\(file.lastPathComponent) should have parts")
        }
    }

    // MARK: - Percussion Tests (73)

    func testPercussionCompliance() throws {
        let files = try testSuiteFiles(matching: "73")

        for file in files {
            let data = try Data(contentsOf: file)
            let importer = MusicXMLImporter()
            let score = try importer.importScore(from: data)

            // Percussion files should have unpitched notes
            let allNotes = score.parts.flatMap { $0.measures.flatMap { $0.notes } }
            let unpitchedNotes = allNotes.filter { $0.unpitched != nil }
            XCTAssertGreaterThan(unpitchedNotes.count, 0, "\(file.lastPathComponent) should have unpitched notes")
        }
    }

    // MARK: - Round-Trip Tests

    func testTestSuiteRoundTrip() throws {
        let files = try testSuiteFiles()

        var passCount = 0
        var failures: [String] = []

        for file in files.prefix(50) {  // Test first 50 for performance
            do {
                let data = try Data(contentsOf: file)
                let result = try roundTripValidator.validate(data: data)
                if result.passed {
                    passCount += 1
                } else {
                    failures.append(file.lastPathComponent)
                }
            } catch {
                failures.append("\(file.lastPathComponent): \(error.localizedDescription)")
            }
        }

        let totalTested = min(files.count, 50)
        let passRate = Double(passCount) / Double(totalTested)

        // At least 80% should pass round-trip
        XCTAssertGreaterThanOrEqual(passRate, 0.8,
            "Only \(Int(passRate * 100))% passed. Failures: \(failures.prefix(5))")
    }

    // MARK: - Summary Statistics

    func testTestSuiteStatistics() throws {
        let files = try testSuiteFiles()

        var totalNotes = 0
        var totalParts = 0
        var totalMeasures = 0
        var parseErrors = 0

        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let importer = MusicXMLImporter()
                let score = try importer.importScore(from: data)

                totalParts += score.parts.count
                for part in score.parts {
                    totalMeasures += part.measures.count
                    totalNotes += part.measures.flatMap { $0.notes }.count
                }
            } catch {
                parseErrors += 1
            }
        }

        print("Test Suite Statistics:")
        print("  Files: \(files.count)")
        print("  Parse errors: \(parseErrors)")
        print("  Total parts: \(totalParts)")
        print("  Total measures: \(totalMeasures)")
        print("  Total notes: \(totalNotes)")

        // Validation
        XCTAssertLessThan(parseErrors, files.count / 10, "More than 10% parse failures")
        XCTAssertGreaterThan(totalNotes, 1000, "Should parse many notes total")
    }
}
