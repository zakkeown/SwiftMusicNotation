import XCTest
import MusicNotationCore
@testable import MIDIImport

final class TickQuantizerTests: XCTestCase {

    // MARK: - Duration Grid

    func testQuarterNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        let result = q.quantizeDuration(480)
        XCTAssertEqual(result.base, .quarter)
        XCTAssertEqual(result.dots, 0)
    }

    func testHalfNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        let result = q.quantizeDuration(960)
        XCTAssertEqual(result.base, .half)
        XCTAssertEqual(result.dots, 0)
    }

    func testWholeNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        let result = q.quantizeDuration(1920)
        XCTAssertEqual(result.base, .whole)
        XCTAssertEqual(result.dots, 0)
    }

    func testEighthNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        let result = q.quantizeDuration(240)
        XCTAssertEqual(result.base, .eighth)
        XCTAssertEqual(result.dots, 0)
    }

    func testSixteenthNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        let result = q.quantizeDuration(120)
        XCTAssertEqual(result.base, .sixteenth)
        XCTAssertEqual(result.dots, 0)
    }

    func testDottedQuarterNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // Dotted quarter = 480 * 3/2 = 720
        let result = q.quantizeDuration(720)
        XCTAssertEqual(result.base, .quarter)
        XCTAssertEqual(result.dots, 1)
    }

    func testDottedHalfNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // Dotted half = 960 * 3/2 = 1440
        let result = q.quantizeDuration(1440)
        XCTAssertEqual(result.base, .half)
        XCTAssertEqual(result.dots, 1)
    }

    func testDottedEighthNoteTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // Dotted eighth = 240 * 3/2 = 360
        let result = q.quantizeDuration(360)
        XCTAssertEqual(result.base, .eighth)
        XCTAssertEqual(result.dots, 1)
    }

    func testDoubleDottedQuarterTicks() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // Double dotted quarter = 480 * 7/4 = 840
        let result = q.quantizeDuration(840)
        XCTAssertEqual(result.base, .quarter)
        XCTAssertEqual(result.dots, 2)
    }

    // MARK: - Position Snapping

    func testQuantizePositionExact() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // Sixteenth note grid at 480 tpq = 120 ticks
        XCTAssertEqual(q.quantizePosition(0), 0)
        XCTAssertEqual(q.quantizePosition(120), 120)
        XCTAssertEqual(q.quantizePosition(240), 240)
        XCTAssertEqual(q.quantizePosition(480), 480)
    }

    func testQuantizePositionSnapDown() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // 130 is closer to 120 than 240
        XCTAssertEqual(q.quantizePosition(130), 120)
        XCTAssertEqual(q.quantizePosition(50), 0)
    }

    func testQuantizePositionSnapUp() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // 100 is closer to 120 than 0
        XCTAssertEqual(q.quantizePosition(100), 120)
    }

    // MARK: - Tick Calculation

    func testTicksForDuration() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        XCTAssertEqual(q.ticksFor(base: .quarter, dots: 0), 480)
        XCTAssertEqual(q.ticksFor(base: .half, dots: 0), 960)
        XCTAssertEqual(q.ticksFor(base: .eighth, dots: 0), 240)
        XCTAssertEqual(q.ticksFor(base: .sixteenth, dots: 0), 120)
        XCTAssertEqual(q.ticksFor(base: .quarter, dots: 1), 720)
    }

    // MARK: - Different TPQ Values

    func testTPQ96() {
        let q = TickQuantizer(ticksPerQuarter: 96)
        XCTAssertEqual(q.quantizeDuration(96).base, .quarter)
        XCTAssertEqual(q.quantizeDuration(48).base, .eighth)
        XCTAssertEqual(q.quantizeDuration(24).base, .sixteenth)
    }

    func testTPQ960() {
        let q = TickQuantizer(ticksPerQuarter: 960)
        XCTAssertEqual(q.quantizeDuration(960).base, .quarter)
        XCTAssertEqual(q.quantizeDuration(480).base, .eighth)
        XCTAssertEqual(q.quantizeDuration(240).base, .sixteenth)
    }

    // MARK: - Approximate Values

    func testQuantizeDurationApproximate() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // 500 ticks is closest to 480 (quarter)
        let result = q.quantizeDuration(500)
        XCTAssertEqual(result.base, .quarter)
        XCTAssertEqual(result.dots, 0)
    }

    func testQuantizeDurationZero() {
        let q = TickQuantizer(ticksPerQuarter: 480)
        // 0 ticks should return a default
        let result = q.quantizeDuration(0)
        XCTAssertEqual(result.base, .quarter)
    }
}
