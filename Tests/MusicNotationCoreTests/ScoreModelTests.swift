import XCTest
@testable import MusicNotationCore

final class ScoreTests: XCTestCase {

    func testInitWithDefaults() {
        let score = Score()

        XCTAssertNotNil(score.id)
        XCTAssertTrue(score.parts.isEmpty)
        XCTAssertTrue(score.credits.isEmpty)
        XCTAssertNil(score.defaults)
        XCTAssertNil(score.metadata.workTitle)
    }

    func testInitWithMetadataAndParts() {
        let metadata = ScoreMetadata(workTitle: "Test Symphony")
        let part = Part(id: "P1", name: "Violin", measures: [])
        let score = Score(metadata: metadata, parts: [part])

        XCTAssertEqual(score.metadata.workTitle, "Test Symphony")
        XCTAssertEqual(score.parts.count, 1)
        XCTAssertEqual(score.parts[0].name, "Violin")
    }

    func testMeasureCount() {
        let measure1 = Measure(number: "1", elements: [])
        let measure2 = Measure(number: "2", elements: [])
        let part = Part(id: "P1", name: "Test", measures: [measure1, measure2])
        let score = Score(parts: [part])

        XCTAssertEqual(score.measureCount, 2)
    }

    func testMeasureCountEmptyScore() {
        let score = Score()
        XCTAssertEqual(score.measureCount, 0)
    }

    func testPartWithID() {
        let part1 = Part(id: "P1", name: "Violin", measures: [])
        let part2 = Part(id: "P2", name: "Viola", measures: [])
        let score = Score(parts: [part1, part2])

        let found = score.part(withID: "P2")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Viola")

        let notFound = score.part(withID: "P3")
        XCTAssertNil(notFound)
    }
}

// MARK: - ScoreMetadata Tests

final class ScoreMetadataTests: XCTestCase {

    func testEmptyInit() {
        let metadata = ScoreMetadata()

        XCTAssertNil(metadata.workTitle)
        XCTAssertNil(metadata.workNumber)
        XCTAssertNil(metadata.movementTitle)
        XCTAssertNil(metadata.movementNumber)
        XCTAssertTrue(metadata.creators.isEmpty)
        XCTAssertTrue(metadata.rights.isEmpty)
        XCTAssertNil(metadata.encoding)
        XCTAssertNil(metadata.source)
    }

    func testFullInit() {
        let creator = Creator(type: "composer", name: "J.S. Bach")
        let encoding = EncodingInfo(software: ["MuseScore"], encodingDate: "2024-01-01")

        let metadata = ScoreMetadata(
            workTitle: "Brandenburg Concerto",
            workNumber: "BWV 1046",
            movementTitle: "Allegro",
            movementNumber: "I",
            creators: [creator],
            rights: ["Public Domain"],
            encoding: encoding,
            source: "Manuscript"
        )

        XCTAssertEqual(metadata.workTitle, "Brandenburg Concerto")
        XCTAssertEqual(metadata.workNumber, "BWV 1046")
        XCTAssertEqual(metadata.movementTitle, "Allegro")
        XCTAssertEqual(metadata.movementNumber, "I")
        XCTAssertEqual(metadata.creators.count, 1)
        XCTAssertEqual(metadata.rights.first, "Public Domain")
        XCTAssertEqual(metadata.encoding?.encodingDate, "2024-01-01")
        XCTAssertEqual(metadata.source, "Manuscript")
    }
}

// MARK: - Creator Tests

final class CreatorTests: XCTestCase {

    func testCreatorWithType() {
        let creator = Creator(type: "composer", name: "Beethoven")
        XCTAssertEqual(creator.type, "composer")
        XCTAssertEqual(creator.name, "Beethoven")
    }

    func testCreatorWithoutType() {
        let creator = Creator(name: "Unknown")
        XCTAssertNil(creator.type)
        XCTAssertEqual(creator.name, "Unknown")
    }
}

// MARK: - EncodingInfo Tests

final class EncodingInfoTests: XCTestCase {

    func testEmptyInit() {
        let info = EncodingInfo()
        XCTAssertTrue(info.software.isEmpty)
        XCTAssertNil(info.encodingDate)
        XCTAssertNil(info.encoder)
        XCTAssertNil(info.encodingDescription)
    }

    func testFullInit() {
        let info = EncodingInfo(
            software: ["Finale", "Dolet"],
            encodingDate: "2024-01-15",
            encoder: "John Doe",
            encodingDescription: "Transcribed from manuscript"
        )

        XCTAssertEqual(info.software.count, 2)
        XCTAssertEqual(info.encodingDate, "2024-01-15")
        XCTAssertEqual(info.encoder, "John Doe")
        XCTAssertEqual(info.encodingDescription, "Transcribed from manuscript")
    }
}

// MARK: - Scaling Tests

final class ScalingTests: XCTestCase {

    func testToMillimeters() {
        // Standard: 40 tenths = 7.05mm
        let scaling = Scaling(millimeters: 7.05, tenths: 40)

        let result = scaling.toMillimeters(40)
        XCTAssertEqual(result, 7.05, accuracy: 0.01)

        let result2 = scaling.toMillimeters(80)
        XCTAssertEqual(result2, 14.1, accuracy: 0.01)
    }

    func testToTenths() {
        let scaling = Scaling(millimeters: 7.05, tenths: 40)

        let result = scaling.toTenths(7.05)
        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testToPoints() {
        let scaling = Scaling(millimeters: 7.05, tenths: 40)

        // 7.05mm * (72/25.4) = about 19.97 points
        let result = scaling.toPoints(40)
        XCTAssertEqual(result, 19.97, accuracy: 0.1)
    }
}

// MARK: - ScoreDefaults Tests

final class ScoreDefaultsTests: XCTestCase {

    func testEmptyInit() {
        let defaults = ScoreDefaults()

        XCTAssertNil(defaults.scaling)
        XCTAssertFalse(defaults.concertScore)
        XCTAssertNil(defaults.pageSettings)
        XCTAssertNil(defaults.systemLayout)
        XCTAssertTrue(defaults.staffLayouts.isEmpty)
        XCTAssertNil(defaults.appearance)
        XCTAssertNil(defaults.musicFont)
        XCTAssertNil(defaults.wordFont)
    }

    func testWithScalingAndConcertScore() {
        let scaling = Scaling(millimeters: 7.05, tenths: 40)
        let defaults = ScoreDefaults(scaling: scaling, concertScore: true)

        XCTAssertNotNil(defaults.scaling)
        XCTAssertTrue(defaults.concertScore)
    }
}

// MARK: - PageSettings Tests

final class PageSettingsTests: XCTestCase {

    func testEmptyInit() {
        let settings = PageSettings()

        XCTAssertNil(settings.pageHeight)
        XCTAssertNil(settings.pageWidth)
        XCTAssertNil(settings.leftMargin)
        XCTAssertNil(settings.rightMargin)
        XCTAssertNil(settings.topMargin)
        XCTAssertNil(settings.bottomMargin)
    }

    func testFullInit() {
        let settings = PageSettings(
            pageHeight: 1683,
            pageWidth: 1190,
            leftMargin: 70,
            rightMargin: 70,
            topMargin: 88,
            bottomMargin: 88
        )

        XCTAssertEqual(settings.pageHeight, 1683)
        XCTAssertEqual(settings.pageWidth, 1190)
        XCTAssertEqual(settings.leftMargin, 70)
        XCTAssertEqual(settings.rightMargin, 70)
        XCTAssertEqual(settings.topMargin, 88)
        XCTAssertEqual(settings.bottomMargin, 88)
    }
}

// MARK: - SystemLayout Tests

final class SystemLayoutTests: XCTestCase {

    func testEmptyInit() {
        let layout = SystemLayout()

        XCTAssertNil(layout.systemLeftMargin)
        XCTAssertNil(layout.systemRightMargin)
        XCTAssertNil(layout.systemDistance)
        XCTAssertNil(layout.topSystemDistance)
    }

    func testFullInit() {
        let layout = SystemLayout(
            systemLeftMargin: 21,
            systemRightMargin: 0,
            systemDistance: 121,
            topSystemDistance: 170
        )

        XCTAssertEqual(layout.systemLeftMargin, 21)
        XCTAssertEqual(layout.systemRightMargin, 0)
        XCTAssertEqual(layout.systemDistance, 121)
        XCTAssertEqual(layout.topSystemDistance, 170)
    }
}

// MARK: - StaffLayout Tests

final class StaffLayoutTests: XCTestCase {

    func testEmptyInit() {
        let layout = StaffLayout()
        XCTAssertNil(layout.staffNumber)
        XCTAssertNil(layout.staffDistance)
    }

    func testWithValues() {
        let layout = StaffLayout(staffNumber: 2, staffDistance: 65)
        XCTAssertEqual(layout.staffNumber, 2)
        XCTAssertEqual(layout.staffDistance, 65)
    }
}

// MARK: - Appearance Tests

final class AppearanceTests: XCTestCase {

    func testEmptyInit() {
        let appearance = Appearance()
        XCTAssertTrue(appearance.lineWidths.isEmpty)
        XCTAssertTrue(appearance.noteSizes.isEmpty)
    }

    func testWithLineWidthsAndNoteSizes() {
        let lineWidth = LineWidth(type: "stem", value: 0.8333)
        let noteSize = NoteSize(type: "cue", value: 75)

        let appearance = Appearance(lineWidths: [lineWidth], noteSizes: [noteSize])

        XCTAssertEqual(appearance.lineWidths.count, 1)
        XCTAssertEqual(appearance.lineWidths[0].type, "stem")
        XCTAssertEqual(appearance.noteSizes.count, 1)
        XCTAssertEqual(appearance.noteSizes[0].type, "cue")
    }
}

// MARK: - LineWidth Tests

final class LineWidthTests: XCTestCase {

    func testInit() {
        let lineWidth = LineWidth(type: "beam", value: 5.0)
        XCTAssertEqual(lineWidth.type, "beam")
        XCTAssertEqual(lineWidth.value, 5.0)
    }
}

// MARK: - NoteSize Tests

final class NoteSizeTests: XCTestCase {

    func testInit() {
        let noteSize = NoteSize(type: "grace", value: 60)
        XCTAssertEqual(noteSize.type, "grace")
        XCTAssertEqual(noteSize.value, 60)
    }
}

// MARK: - FontSpecification Tests

final class FontSpecificationTests: XCTestCase {

    func testMinimalInit() {
        let font = FontSpecification(fontFamily: ["Bravura"])
        XCTAssertEqual(font.fontFamily.first, "Bravura")
        XCTAssertNil(font.fontStyle)
        XCTAssertNil(font.fontSize)
        XCTAssertNil(font.fontWeight)
    }

    func testFullInit() {
        let font = FontSpecification(
            fontFamily: ["Times New Roman", "serif"],
            fontStyle: .italic,
            fontSize: 12.0,
            fontWeight: .bold
        )

        XCTAssertEqual(font.fontFamily.count, 2)
        XCTAssertEqual(font.fontStyle, .italic)
        XCTAssertEqual(font.fontSize, 12.0)
        XCTAssertEqual(font.fontWeight, .bold)
    }
}

// MARK: - Credit Tests

final class CreditTests: XCTestCase {

    func testEmptyInit() {
        let credit = Credit()
        XCTAssertNil(credit.page)
        XCTAssertNil(credit.creditType)
        XCTAssertTrue(credit.creditWords.isEmpty)
    }

    func testWithValues() {
        let words = CreditWords(text: "Symphony No. 5", defaultX: 595, defaultY: 1560)
        let credit = Credit(page: 1, creditType: "title", creditWords: [words])

        XCTAssertEqual(credit.page, 1)
        XCTAssertEqual(credit.creditType, "title")
        XCTAssertEqual(credit.creditWords.count, 1)
        XCTAssertEqual(credit.creditWords[0].text, "Symphony No. 5")
    }
}

// MARK: - CreditWords Tests

final class CreditWordsTests: XCTestCase {

    func testMinimalInit() {
        let words = CreditWords(text: "Composer Name")
        XCTAssertEqual(words.text, "Composer Name")
        XCTAssertNil(words.defaultX)
        XCTAssertNil(words.defaultY)
        XCTAssertNil(words.font)
        XCTAssertNil(words.justify)
    }

    func testFullInit() {
        let font = FontSpecification(fontFamily: ["Arial"])
        let words = CreditWords(
            text: "Ludwig van Beethoven",
            defaultX: 595,
            defaultY: 1460,
            font: font,
            justify: .center
        )

        XCTAssertEqual(words.text, "Ludwig van Beethoven")
        XCTAssertEqual(words.defaultX, 595)
        XCTAssertEqual(words.defaultY, 1460)
        XCTAssertNotNil(words.font)
        XCTAssertEqual(words.justify, .center)
    }
}

// MARK: - Justification Tests

final class JustificationTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(Justification.left.rawValue, "left")
        XCTAssertEqual(Justification.center.rawValue, "center")
        XCTAssertEqual(Justification.right.rawValue, "right")
    }
}

// MARK: - FontStyle Tests

final class FontStyleTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(FontStyle.normal.rawValue, "normal")
        XCTAssertEqual(FontStyle.italic.rawValue, "italic")
    }
}

// MARK: - FontWeight Tests

final class FontWeightTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(FontWeight.normal.rawValue, "normal")
        XCTAssertEqual(FontWeight.bold.rawValue, "bold")
    }
}
