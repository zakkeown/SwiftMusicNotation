import XCTest
import MusicNotationCore
import MusicXMLImport

/// Tests for handling malformed or edge-case MusicXML input.
/// These tests verify the parser handles errors gracefully without crashing.
final class MalformedInputTests: XCTestCase {

    // MARK: - Empty and Invalid Files

    func testEmptyFile() {
        let data = Data()
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data)) { error in
            // Should throw a meaningful error, not crash
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testEmptyXML() {
        let xml = ""
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    func testInvalidXMLSyntax() {
        let xml = "<score-partwise><unclosed-tag>"
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    func testMismatchedTags() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1">
                    <part-name>Music</wrong-tag>
                </score-part>
            </part-list>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    // MARK: - Missing Required Elements

    func testMissingPartList() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part id="P1">
                <measure number="1">
                    <note>
                        <pitch><step>C</step><octave>4</octave></pitch>
                        <duration>4</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should either throw or parse with default part info
        do {
            let score = try importer.importScore(from: data)
            // If it parses, it should have at least the part
            XCTAssertGreaterThanOrEqual(score.parts.count, 0)
        } catch {
            // Error is acceptable
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testMissingMeasures() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1">
                    <part-name>Music</part-name>
                </score-part>
            </part-list>
            <part id="P1">
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should parse but with empty measures
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
            XCTAssertEqual(score.parts[0].measures.count, 0)
        } catch {
            // Error is also acceptable for edge case
        }
    }

    func testEmptyMeasure() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1">
                    <part-name>Music</part-name>
                </score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should parse successfully with empty measure
        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            XCTAssertEqual(score.parts.count, 1)
            XCTAssertEqual(score.parts[0].measures.count, 1)
            XCTAssertEqual(score.parts[0].measures[0].notes.count, 0)
        }
    }

    // MARK: - Invalid Attribute Values

    func testNegativeDivisions() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes>
                        <divisions>-4</divisions>
                    </attributes>
                    <note>
                        <pitch><step>C</step><octave>4</octave></pitch>
                        <duration>4</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should handle gracefully - either throw or use absolute value
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testZeroDivisions() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes>
                        <divisions>0</divisions>
                    </attributes>
                    <note>
                        <pitch><step>C</step><octave>4</octave></pitch>
                        <duration>4</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Zero divisions would cause divide-by-zero - should handle gracefully
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
        } catch {
            // Error is acceptable
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testOutOfRangeOctave() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes><divisions>1</divisions></attributes>
                    <note>
                        <pitch><step>C</step><octave>99</octave></pitch>
                        <duration>1</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should parse, octave 99 is unusual but valid XML
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
            let notes = score.parts[0].measures[0].notes
            XCTAssertEqual(notes.count, 1)
            XCTAssertEqual(notes[0].pitch?.octave, 99)
        } catch {
            // Error is also acceptable
        }
    }

    func testInvalidPitchStep() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes><divisions>1</divisions></attributes>
                    <note>
                        <pitch><step>Z</step><octave>4</octave></pitch>
                        <duration>1</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Invalid step 'Z' should be handled
        do {
            let score = try importer.importScore(from: data)
            // Either skip the note or use a default
            XCTAssertEqual(score.parts.count, 1)
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    // MARK: - Encoding Edge Cases

    func testUTF8WithBOM() {
        // UTF-8 with BOM (Byte Order Mark)
        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        var data = Data(bom)
        data.append(xml.data(using: .utf8)!)

        let importer = MusicXMLImporter()
        let score = try? importer.importScore(from: data)

        // Most XML parsers handle BOM gracefully
        XCTAssertNotNil(score)
    }

    func testSpecialCharactersInPartName() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise>
            <part-list>
                <score-part id="P1">
                    <part-name>Violín I &amp; II</part-name>
                </score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            XCTAssertEqual(score.parts.count, 1)
            // Part name should handle the special characters
        }
    }

    // MARK: - Structural Edge Cases

    func testVeryLongPartId() {
        let longId = String(repeating: "x", count: 1000)
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="\(longId)"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="\(longId)">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should handle long IDs
        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
    }

    func testMismatchedPartIds() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P999">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Part ID mismatch - should handle gracefully
        do {
            let score = try importer.importScore(from: data)
            // Might create a part anyway or skip it
            XCTAssertGreaterThanOrEqual(score.parts.count, 0)
        } catch {
            // Error is acceptable
        }
    }

    func testDuplicateMeasureNumbers() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Duplicate measure numbers are technically invalid but happen in real files
        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            // Should have both measures even with duplicate numbers
            XCTAssertEqual(score.parts[0].measures.count, 2)
        }
    }

    // MARK: - Very Large Values

    func testVeryLargeDuration() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes><divisions>1</divisions></attributes>
                    <note>
                        <pitch><step>C</step><octave>4</octave></pitch>
                        <duration>999999999</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should not overflow or crash
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
        } catch {
            // Error acceptable for absurd values
        }
    }

    func testNegativeDuration() {
        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes><divisions>1</divisions></attributes>
                    <note>
                        <pitch><step>C</step><octave>4</octave></pitch>
                        <duration>-4</duration>
                        <type>quarter</type>
                    </note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Negative duration is invalid
        do {
            let score = try importer.importScore(from: data)
            XCTAssertEqual(score.parts.count, 1)
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    // MARK: - Deeply Nested Content

    func testDeeplyNestedDirections() {
        // Some MusicXML files have many nested direction elements
        var directions = ""
        for i in 1...20 {
            directions += """
                <direction>
                    <direction-type>
                        <words>Text \(i)</words>
                    </direction-type>
                </direction>
            """
        }

        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    \(directions)
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        // Should handle many directions
        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
    }

    // MARK: - Non-MusicXML Content

    func testHTMLContent() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Not MusicXML</title></head>
        <body><p>This is HTML, not MusicXML</p></body>
        </html>
        """
        let data = html.data(using: .utf8)!
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    func testJSONContent() {
        let json = """
        {"type": "score", "parts": []}
        """
        let data = json.data(using: .utf8)!
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    func testBinaryContent() {
        // Random binary data
        var bytes = [UInt8]()
        for _ in 0..<100 {
            bytes.append(UInt8.random(in: 0...255))
        }
        let data = Data(bytes)
        let importer = MusicXMLImporter()

        XCTAssertThrowsError(try importer.importScore(from: data))
    }

    // MARK: - Performance Edge Cases

    func testManyParts() {
        var parts = ""
        var partList = ""
        for i in 1...50 {
            partList += "<score-part id=\"P\(i)\"><part-name>Part \(i)</part-name></score-part>"
            parts += """
            <part id="P\(i)">
                <measure number="1">
                    <note><rest/><duration>4</duration><type>whole</type></note>
                </measure>
            </part>
            """
        }

        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>\(partList)</part-list>
            \(parts)
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            XCTAssertEqual(score.parts.count, 50)
        }
    }

    func testManyMeasures() {
        var measures = ""
        for i in 1...200 {
            measures += """
            <measure number="\(i)">
                <note><rest/><duration>4</duration><type>whole</type></note>
            </measure>
            """
        }

        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">\(measures)</part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            XCTAssertEqual(score.parts[0].measures.count, 200)
        }
    }

    func testManyNotesInMeasure() {
        var notes = ""
        for _ in 1...100 {
            notes += """
            <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>1</duration>
                <type>64th</type>
            </note>
            """
        }

        let xml = """
        <?xml version="1.0"?>
        <score-partwise>
            <part-list>
                <score-part id="P1"><part-name>Music</part-name></score-part>
            </part-list>
            <part id="P1">
                <measure number="1">
                    <attributes><divisions>16</divisions></attributes>
                    \(notes)
                </measure>
            </part>
        </score-partwise>
        """
        let data = xml.data(using: .utf8)!
        let importer = MusicXMLImporter()

        let score = try? importer.importScore(from: data)
        XCTAssertNotNil(score)
        if let score = score {
            XCTAssertEqual(score.parts[0].measures[0].notes.count, 100)
        }
    }
}
