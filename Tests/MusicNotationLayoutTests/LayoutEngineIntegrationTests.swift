import XCTest
import CoreGraphics
@testable import MusicNotationLayout
@testable import MusicNotationCore

final class LayoutEngineIntegrationTests: XCTestCase {

    // MARK: - Helper Methods

    func createSimpleScore(measureCount: Int = 4) -> Score {
        var measures: [Measure] = []

        for i in 0..<measureCount {
            let measure = Measure(number: "\(i + 1)")
            measures.append(measure)
        }

        let part = Part(id: "P1", name: "Piano", measures: measures)
        return Score(parts: [part])
    }

    func createScoreWithNotes(noteCount: Int = 4) -> Score {
        var measures: [Measure] = []
        var elements: [MeasureElement] = []

        // Add attributes for first measure
        let attrs = MeasureAttributes(
            divisions: 4,
            timeSignatures: [TimeSignature(beats: "4", beatType: "4")],
            clefs: [Clef(sign: .g, line: 2)]
        )
        elements.append(.attributes(attrs))

        // Add notes
        for i in 0..<noteCount {
            let pitch = Pitch(step: PitchStep(rawValue: ["C", "D", "E", "F", "G", "A", "B"][i % 7])!, octave: 4)
            let note = Note(noteType: .pitched(pitch), durationDivisions: 4, type: .quarter)
            elements.append(.note(note))
        }

        let measure = Measure(number: "1", elements: elements)
        measures.append(measure)

        let part = Part(id: "P1", name: "Piano", measures: measures)
        return Score(parts: [part])
    }

    // MARK: - Basic Layout Tests

    func testLayoutEngineInitialization() {
        let engine = LayoutEngine()

        XCTAssertNotNil(engine.config)
        XCTAssertEqual(engine.config.clefWidth, 20)
        XCTAssertEqual(engine.config.keySignatureWidth, 30)
        XCTAssertEqual(engine.config.timeSignatureWidth, 20)
    }

    func testLayoutEngineWithCustomConfig() {
        var config = LayoutConfiguration()
        config.clefWidth = 25
        config.firstPageTopOffset = 100

        let engine = LayoutEngine(config: config)

        XCTAssertEqual(engine.config.clefWidth, 25)
        XCTAssertEqual(engine.config.firstPageTopOffset, 100)
    }

    func testLayoutSimpleScore() {
        let score = createSimpleScore(measureCount: 4)
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        XCTAssertEqual(engravedScore.pageCount, 1)
        XCTAssertFalse(engravedScore.pages.isEmpty)

        let firstPage = engravedScore.pages[0]
        XCTAssertEqual(firstPage.pageNumber, 1)
        XCTAssertFalse(firstPage.systems.isEmpty)
    }

    func testLayoutProducesCorrectPageSize() {
        let score = createSimpleScore()
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        let firstPage = engravedScore.pages[0]
        XCTAssertEqual(firstPage.frame.width, 612, accuracy: 0.1) // US Letter width
        XCTAssertEqual(firstPage.frame.height, 792, accuracy: 0.1) // US Letter height
    }

    func testLayoutWithA4Context() {
        let score = createSimpleScore()
        let engine = LayoutEngine()
        let context = LayoutContext.a4Size(staffHeight: 35)

        let engravedScore = engine.layout(score: score, context: context)

        let firstPage = engravedScore.pages[0]
        XCTAssertEqual(firstPage.frame.width, 595, accuracy: 0.1) // A4 width
        XCTAssertEqual(firstPage.frame.height, 842, accuracy: 0.1) // A4 height
    }

    // MARK: - System Tests

    func testSystemsContainMeasures() {
        let score = createSimpleScore(measureCount: 4)
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        let firstPage = engravedScore.pages[0]
        XCTAssertFalse(firstPage.systems.isEmpty)

        let firstSystem = firstPage.systems[0]
        XCTAssertFalse(firstSystem.measures.isEmpty)
    }

    func testMeasureRangeIsCorrect() {
        let score = createSimpleScore(measureCount: 4)
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        var totalMeasures = 0
        for page in engravedScore.pages {
            for system in page.systems {
                let measuresInSystem = system.measureRange.upperBound - system.measureRange.lowerBound + 1
                totalMeasures += measuresInSystem
            }
        }

        XCTAssertEqual(totalMeasures, 4)
    }

    // MARK: - Staff Tests

    func testStavesCreated() {
        let score = createSimpleScore()
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        let firstSystem = engravedScore.pages[0].systems[0]
        XCTAssertFalse(firstSystem.staves.isEmpty)

        let firstStaff = firstSystem.staves[0]
        XCTAssertEqual(firstStaff.lineCount, 5)
        XCTAssertEqual(firstStaff.staffHeight, 40)
    }

    func testMultiPartScore() {
        var measures: [Measure] = []
        let measure = Measure(number: "1")
        measures.append(measure)

        let part1 = Part(id: "P1", name: "Violin", measures: measures)
        let part2 = Part(id: "P2", name: "Cello", measures: measures)

        let score = Score(parts: [part1, part2])
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        let firstSystem = engravedScore.pages[0].systems[0]
        XCTAssertEqual(firstSystem.staves.count, 2)
    }

    // MARK: - Credits Tests

    func testCreditsOnFirstPage() {
        var score = createSimpleScore()
        score.metadata.workTitle = "Test Symphony"

        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        let firstPage = engravedScore.pages[0]
        XCTAssertFalse(firstPage.credits.isEmpty)

        let titleCredit = firstPage.credits.first { $0.text == "Test Symphony" }
        XCTAssertNotNil(titleCredit)
    }

    // MARK: - Scaling Context Tests

    func testScalingContextCreated() {
        let score = createSimpleScore()
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)

        let engravedScore = engine.layout(score: score, context: context)

        XCTAssertEqual(engravedScore.scaling.staffHeightPoints, 40)
    }

    // MARK: - Context Tests

    func testLayoutContextLetterSize() {
        let context = LayoutContext.letterSize(staffHeight: 40)

        XCTAssertEqual(context.pageSize.width, 612)
        XCTAssertEqual(context.pageSize.height, 792)
        XCTAssertEqual(context.staffHeight, 40)
        XCTAssertEqual(context.margins.top, 72)
        XCTAssertEqual(context.margins.left, 72)
        XCTAssertEqual(context.fontName, "Bravura")
    }

    func testLayoutContextA4Size() {
        let context = LayoutContext.a4Size(staffHeight: 35)

        XCTAssertEqual(context.pageSize.width, 595)
        XCTAssertEqual(context.pageSize.height, 842)
        XCTAssertEqual(context.staffHeight, 35)
    }

    func testLayoutContextCustom() {
        let context = LayoutContext(
            pageSize: CGSize(width: 800, height: 1000),
            margins: EdgeInsets(top: 50, left: 60, bottom: 50, right: 60),
            staffHeight: 45,
            fontName: "Petaluma"
        )

        XCTAssertEqual(context.pageSize.width, 800)
        XCTAssertEqual(context.pageSize.height, 1000)
        XCTAssertEqual(context.margins.top, 50)
        XCTAssertEqual(context.margins.left, 60)
        XCTAssertEqual(context.staffHeight, 45)
        XCTAssertEqual(context.fontName, "Petaluma")
    }

    // MARK: - Edge Insets Tests

    func testEdgeInsetsAll() {
        let insets = EdgeInsets(all: 50)

        XCTAssertEqual(insets.top, 50)
        XCTAssertEqual(insets.left, 50)
        XCTAssertEqual(insets.bottom, 50)
        XCTAssertEqual(insets.right, 50)
    }

    func testEdgeInsetsZero() {
        let insets = EdgeInsets.zero

        XCTAssertEqual(insets.top, 0)
        XCTAssertEqual(insets.left, 0)
        XCTAssertEqual(insets.bottom, 0)
        XCTAssertEqual(insets.right, 0)
    }

    // MARK: - Configuration Tests

    func testLayoutConfigurationDefaults() {
        let config = LayoutConfiguration()

        XCTAssertEqual(config.firstPageTopOffset, 60)
        XCTAssertEqual(config.clefWidth, 20)
        XCTAssertEqual(config.keySignatureWidth, 30)
        XCTAssertEqual(config.timeSignatureWidth, 20)
    }
}
