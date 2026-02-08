import XCTest
import CoreGraphics
@testable import MusicNotationRenderer
@testable import MusicNotationLayout
@testable import MusicNotationCore
@testable import SMuFLKit

/// Smoke tests for the complete ExportEngine rendering pipeline.
/// These tests verify that all element types render without crashing
/// and that the rendering pipeline produces non-empty output.
final class ExportEngineRenderingTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a minimal Score for use in EngravedScore.
    private func makeScore() -> Score {
        Score()
    }

    /// Creates a test EngravedScore with the specified elements in a single measure.
    private func makeEngravedScore(
        elements: [EngravedElement] = [],
        beamGroups: [EngravedBeamGroup] = [],
        systemBarlines: [EngravedSystemBarline] = [],
        groupings: [EngravedStaffGrouping] = [],
        credits: [EngravedCredit] = [],
        staveCount: Int = 1
    ) -> EngravedScore {
        let measure = EngravedMeasure(
            measureNumber: 1,
            frame: CGRect(x: 50, y: 0, width: 200, height: 40),
            leftBarlineX: 50,
            rightBarlineX: 250,
            elementsByStaff: [1: elements],
            beamGroups: beamGroups
        )

        var staves: [EngravedStaff] = []
        for i in 0..<staveCount {
            staves.append(EngravedStaff(
                partIndex: 0,
                staffNumber: i + 1,
                frame: CGRect(x: 0, y: CGFloat(i) * 60, width: 300, height: 40),
                centerLineY: CGFloat(i) * 60 + 20,
                lineCount: 5,
                staffHeight: 40
            ))
        }

        let system = EngravedSystem(
            frame: CGRect(x: 20, y: 50, width: 300, height: CGFloat(staveCount) * 60),
            staves: staves,
            measures: [measure],
            systemBarlines: systemBarlines,
            groupings: groupings,
            measureRange: 1...1
        )

        let page = EngravedPage(
            pageNumber: 1,
            frame: CGRect(x: 0, y: 0, width: 400, height: 300),
            systems: [system],
            credits: credits
        )

        return EngravedScore(
            score: makeScore(),
            pages: [page],
            scaling: ScalingContext()
        )
    }

    /// Loads the bundled SMuFL font for rendering tests.
    private func loadTestFont() -> LoadedSMuFLFont? {
        let manager = SMuFLFontManager.shared
        // Try loading a bundled font
        if let font = try? manager.loadBundledFont(named: "Bravura") {
            return font
        }
        // Fallback: try any available bundled font
        if let font = try? manager.loadBundledFont(named: "Petaluma") {
            return font
        }
        return nil
    }

    // MARK: - Note Rendering Tests

    func testRenderNoteWithStem() throws {
        let note = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 100, y: 20),
            staffPosition: 0,
            noteheadGlyph: .noteheadBlack,
            stem: EngravedStem(
                start: CGPoint(x: 100, y: 20),
                end: CGPoint(x: 100, y: -15),
                direction: .up,
                thickness: 1.0
            ),
            boundingBox: CGRect(x: 95, y: -15, width: 15, height: 40)
        )

        let score = makeEngravedScore(elements: [.note(note)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0, "PNG data should be non-empty")
    }

    func testRenderNoteWithStemAndFlag() throws {
        let note = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 100, y: 20),
            staffPosition: 0,
            noteheadGlyph: .noteheadBlack,
            stem: EngravedStem(
                start: CGPoint(x: 100, y: 20),
                end: CGPoint(x: 100, y: -15),
                direction: .up,
                thickness: 1.0
            ),
            flagGlyph: .flag8thUp,
            boundingBox: CGRect(x: 95, y: -15, width: 20, height: 40)
        )

        let score = makeEngravedScore(elements: [.note(note)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderNoteWithAccidentalAndDots() throws {
        let note = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 100, y: 20),
            staffPosition: 0,
            noteheadGlyph: .noteheadBlack,
            accidentalGlyph: .accidentalSharp,
            accidentalOffset: -12,
            stem: EngravedStem(
                start: CGPoint(x: 100, y: 20),
                end: CGPoint(x: 100, y: -15),
                direction: .up,
                thickness: 1.0
            ),
            dots: [CGPoint(x: 115, y: 20)],
            boundingBox: CGRect(x: 85, y: -15, width: 35, height: 40)
        )

        let score = makeEngravedScore(elements: [.note(note)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Chord Rendering Tests

    func testRenderChord() throws {
        let chord = EngravedChord(
            notes: [
                EngravedNote(
                    noteId: UUID(),
                    position: CGPoint(x: 100, y: 20),
                    staffPosition: 0,
                    noteheadGlyph: .noteheadBlack
                ),
                EngravedNote(
                    noteId: UUID(),
                    position: CGPoint(x: 100, y: 10),
                    staffPosition: 4,
                    noteheadGlyph: .noteheadBlack
                )
            ],
            stem: EngravedStem(
                start: CGPoint(x: 110, y: 20),
                end: CGPoint(x: 110, y: -15),
                direction: .up,
                thickness: 1.0
            ),
            boundingBox: CGRect(x: 95, y: -15, width: 20, height: 40)
        )

        let score = makeEngravedScore(elements: [.chord(chord)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Rest Rendering Tests

    func testRenderRest() throws {
        let rest = EngravedRest(
            position: CGPoint(x: 100, y: 20),
            glyph: .restQuarter,
            boundingBox: CGRect(x: 95, y: 10, width: 10, height: 20)
        )

        let score = makeEngravedScore(elements: [.rest(rest)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Beam Group Rendering Tests

    func testRenderBeamGroup() throws {
        let note1 = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 80, y: 20),
            staffPosition: 0,
            noteheadGlyph: .noteheadBlack,
            stem: EngravedStem(
                start: CGPoint(x: 80, y: 20),
                end: CGPoint(x: 80, y: -10),
                direction: .up,
                thickness: 1.0
            ),
            boundingBox: CGRect(x: 75, y: -10, width: 15, height: 35)
        )

        let note2 = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 130, y: 15),
            staffPosition: 2,
            noteheadGlyph: .noteheadBlack,
            stem: EngravedStem(
                start: CGPoint(x: 130, y: 15),
                end: CGPoint(x: 130, y: -10),
                direction: .up,
                thickness: 1.0
            ),
            boundingBox: CGRect(x: 125, y: -10, width: 15, height: 30)
        )

        let beamGroup = EngravedBeamGroup(
            startPoint: CGPoint(x: 80, y: -10),
            endPoint: CGPoint(x: 130, y: -10),
            thickness: 4.0,
            slope: 0,
            stemDirection: .up
        )

        let score = makeEngravedScore(
            elements: [.note(note1), .note(note2)],
            beamGroups: [beamGroup]
        )

        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Direction Rendering Tests

    func testRenderDirectionText() throws {
        let direction = EngravedDirection(
            position: CGPoint(x: 100, y: 50),
            content: .text("dolce"),
            boundingBox: CGRect(x: 90, y: 45, width: 40, height: 15)
        )

        let score = makeEngravedScore(elements: [.direction(direction)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderDirectionDynamic() throws {
        let direction = EngravedDirection(
            position: CGPoint(x: 100, y: 50),
            content: .dynamic(.dynamicForte),
            boundingBox: CGRect(x: 95, y: 45, width: 15, height: 15)
        )

        let score = makeEngravedScore(elements: [.direction(direction)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderDirectionWedgeCrescendo() throws {
        let wedge = WedgeContent(
            isCresc: true,
            startX: 80,
            endX: 160,
            spreadStart: 0,
            spreadEnd: 10
        )
        let direction = EngravedDirection(
            position: CGPoint(x: 80, y: 50),
            content: .wedge(wedge),
            boundingBox: CGRect(x: 80, y: 45, width: 80, height: 10)
        )

        let score = makeEngravedScore(elements: [.direction(direction)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderDirectionWedgeDiminuendo() throws {
        let wedge = WedgeContent(
            isCresc: false,
            startX: 80,
            endX: 160,
            spreadStart: 10,
            spreadEnd: 0
        )
        let direction = EngravedDirection(
            position: CGPoint(x: 80, y: 50),
            content: .wedge(wedge),
            boundingBox: CGRect(x: 80, y: 45, width: 80, height: 10)
        )

        let score = makeEngravedScore(elements: [.direction(direction)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderDirectionMetronome() throws {
        let metronome = MetronomeContent(
            beatUnitGlyph: .noteheadBlack,
            bpm: 120,
            beatUnitDots: 0
        )
        let direction = EngravedDirection(
            position: CGPoint(x: 100, y: 10),
            content: .metronome(metronome),
            boundingBox: CGRect(x: 95, y: 5, width: 60, height: 15)
        )

        let score = makeEngravedScore(elements: [.direction(direction)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Barline Rendering Tests

    func testRenderStyledBarline() throws {
        let barline = EngravedBarline(
            style: .lightHeavy,
            frame: CGRect(x: 200, y: 0, width: 5, height: 40),
            isSystemBarline: false
        )

        let score = makeEngravedScore(elements: [.barline(barline)])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - System Barline Tests

    func testRenderSystemBarlines() throws {
        let systemBarline = EngravedSystemBarline(
            x: 20,
            topY: 0,
            bottomY: 100,
            style: .regular
        )

        let score = makeEngravedScore(
            systemBarlines: [systemBarline],
            staveCount: 2
        )

        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Staff Grouping Tests

    func testRenderBraceGrouping() throws {
        let grouping = EngravedStaffGrouping(
            symbol: .brace,
            x: 15,
            topStaffIndex: 0,
            bottomStaffIndex: 1
        )

        let score = makeEngravedScore(
            groupings: [grouping],
            staveCount: 2
        )

        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testRenderBracketGrouping() throws {
        let grouping = EngravedStaffGrouping(
            symbol: .bracket,
            x: 15,
            topStaffIndex: 0,
            bottomStaffIndex: 1
        )

        let score = makeEngravedScore(
            groupings: [grouping],
            staveCount: 2
        )

        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Credit Rendering Tests

    func testRenderCredits() throws {
        let credit = EngravedCredit(
            text: "Sonata No. 1",
            position: CGPoint(x: 200, y: 20),
            fontSize: 18,
            justification: .center
        )

        let score = makeEngravedScore(credits: [credit])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Combined Rendering Tests

    func testRenderCompleteScene() throws {
        // Build a scene with multiple element types
        let note = EngravedNote(
            noteId: UUID(),
            position: CGPoint(x: 100, y: 20),
            staffPosition: 0,
            noteheadGlyph: .noteheadBlack,
            accidentalGlyph: .accidentalSharp,
            accidentalOffset: -12,
            stem: EngravedStem(
                start: CGPoint(x: 100, y: 20),
                end: CGPoint(x: 100, y: -15),
                direction: .up,
                thickness: 1.0
            ),
            flagGlyph: .flag8thUp,
            dots: [CGPoint(x: 115, y: 20)],
            boundingBox: CGRect(x: 85, y: -15, width: 35, height: 40)
        )

        let rest = EngravedRest(
            position: CGPoint(x: 160, y: 20),
            glyph: .restQuarter,
            boundingBox: CGRect(x: 155, y: 10, width: 10, height: 20)
        )

        let dynamic = EngravedDirection(
            position: CGPoint(x: 100, y: 50),
            content: .dynamic(.dynamicPiano),
            boundingBox: CGRect(x: 95, y: 45, width: 15, height: 15)
        )

        let wedge = EngravedDirection(
            position: CGPoint(x: 130, y: 50),
            content: .wedge(WedgeContent(isCresc: true, startX: 130, endX: 190, spreadStart: 0, spreadEnd: 8)),
            boundingBox: CGRect(x: 130, y: 45, width: 60, height: 10)
        )

        let elements: [EngravedElement] = [
            .note(note),
            .rest(rest),
            .direction(dynamic),
            .direction(wedge)
        ]

        let systemBarline = EngravedSystemBarline(x: 20, topY: 0, bottomY: 100, style: .regular)
        let grouping = EngravedStaffGrouping(symbol: .brace, x: 15, topStaffIndex: 0, bottomStaffIndex: 1)
        let credit = EngravedCredit(text: "Test Score", position: CGPoint(x: 200, y: 15), fontSize: 16, justification: .center)

        let score = makeEngravedScore(
            elements: elements,
            systemBarlines: [systemBarline],
            groupings: [grouping],
            credits: [credit],
            staveCount: 2
        )

        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)

        // Test PNG export
        let pngData = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(pngData.count, 0, "PNG export should produce non-empty data")

        // Test PDF export
        let pdfData = try engine.exportPDF()
        XCTAssertGreaterThan(pdfData.count, 0, "PDF export should produce non-empty data")
    }

    // MARK: - Empty Score Tests

    func testRenderEmptyMeasure() throws {
        let score = makeEngravedScore(elements: [])
        guard let font = loadTestFont() else {
            throw XCTSkip("No bundled SMuFL font available")
        }

        let engine = ExportEngine(engravedScore: score, font: font)
        let data = try engine.exportPNG(pageIndex: 0, scale: 1.0)
        XCTAssertGreaterThan(data.count, 0, "Empty measure should still render staff lines")
    }
}
