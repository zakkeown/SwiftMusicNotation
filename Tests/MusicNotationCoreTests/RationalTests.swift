import XCTest
@testable import MusicNotationCore

final class RationalTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBasicInitialization() {
        let half = Rational(1, 2)
        XCTAssertEqual(half.numerator, 1)
        XCTAssertEqual(half.denominator, 2)
    }

    func testAutoReduction() {
        let reduced = Rational(4, 8)
        XCTAssertEqual(reduced.numerator, 1)
        XCTAssertEqual(reduced.denominator, 2)
    }

    func testZeroNumerator() {
        let zero = Rational(0, 5)
        XCTAssertEqual(zero.numerator, 0)
        XCTAssertEqual(zero.denominator, 1) // Should reduce to 0/1
    }

    func testNegativeHandling() {
        let negNum = Rational(-3, 4)
        XCTAssertEqual(negNum.numerator, -3)
        XCTAssertEqual(negNum.denominator, 4)

        let negDen = Rational(3, -4)
        XCTAssertEqual(negDen.numerator, -3)
        XCTAssertEqual(negDen.denominator, 4)

        let bothNeg = Rational(-3, -4)
        XCTAssertEqual(bothNeg.numerator, 3)
        XCTAssertEqual(bothNeg.denominator, 4)
    }

    func testIntegerInitialization() {
        let whole = Rational(5)
        XCTAssertEqual(whole.numerator, 5)
        XCTAssertEqual(whole.denominator, 1)
    }

    // MARK: - Arithmetic Tests

    func testAddition() {
        let a = Rational(1, 4)
        let b = Rational(1, 4)
        let result = a + b
        XCTAssertEqual(result, Rational(1, 2))
    }

    func testAdditionWithDifferentDenominators() {
        let a = Rational(1, 3)
        let b = Rational(1, 6)
        let result = a + b
        XCTAssertEqual(result, Rational(1, 2))
    }

    func testSubtraction() {
        let a = Rational(3, 4)
        let b = Rational(1, 4)
        let result = a - b
        XCTAssertEqual(result, Rational(1, 2))
    }

    func testSubtractionResultingInNegative() {
        let a = Rational(1, 4)
        let b = Rational(3, 4)
        let result = a - b
        XCTAssertEqual(result, Rational(-1, 2))
    }

    func testMultiplication() {
        let a = Rational(2, 3)
        let b = Rational(3, 4)
        let result = a * b
        XCTAssertEqual(result, Rational(1, 2))
    }

    func testDivision() {
        let a = Rational(1, 2)
        let b = Rational(1, 4)
        let result = a / b
        XCTAssertEqual(result, Rational(2, 1))
    }

    func testDivisionByWhole() {
        let a = Rational(3, 4)
        let result = a / Rational(3)
        XCTAssertEqual(result, Rational(1, 4))
    }

    // MARK: - Comparison Tests

    func testEquality() {
        let a = Rational(2, 4)
        let b = Rational(1, 2)
        XCTAssertEqual(a, b)
    }

    func testLessThan() {
        let a = Rational(1, 4)
        let b = Rational(1, 2)
        XCTAssertTrue(a < b)
        XCTAssertFalse(b < a)
    }

    func testGreaterThan() {
        let a = Rational(3, 4)
        let b = Rational(1, 2)
        XCTAssertTrue(a > b)
        XCTAssertFalse(b > a)
    }

    func testLessThanOrEqual() {
        let a = Rational(1, 2)
        let b = Rational(2, 4)
        let c = Rational(3, 4)
        XCTAssertTrue(a <= b) // Equal
        XCTAssertTrue(a <= c) // Less than
    }

    func testNegativeComparison() {
        let neg = Rational(-1, 2)
        let pos = Rational(1, 2)
        XCTAssertTrue(neg < pos)
    }

    // MARK: - Conversion Tests

    func testDoubleValue() {
        let half = Rational(1, 2)
        XCTAssertEqual(half.doubleValue, 0.5, accuracy: 0.0001)

        let third = Rational(1, 3)
        XCTAssertEqual(third.doubleValue, 0.333333, accuracy: 0.0001)

        let threeFourths = Rational(3, 4)
        XCTAssertEqual(threeFourths.doubleValue, 0.75, accuracy: 0.0001)
    }

    // MARK: - Static Constants Tests

    func testZeroConstant() {
        XCTAssertEqual(Rational.zero.numerator, 0)
        XCTAssertEqual(Rational.zero.denominator, 1)
    }

    func testOneConstant() {
        XCTAssertEqual(Rational.one.numerator, 1)
        XCTAssertEqual(Rational.one.denominator, 1)
    }

    // MARK: - Musical Duration Tests

    func testMusicalDurations() {
        // Test common musical duration ratios
        let whole = Rational(1, 1)
        let half = Rational(1, 2)
        let quarter = Rational(1, 4)
        let eighth = Rational(1, 8)
        let sixteenth = Rational(1, 16)

        // Half + half = whole
        XCTAssertEqual(half + half, whole)

        // Two quarters = half
        XCTAssertEqual(quarter + quarter, half)

        // Four sixteenths = quarter
        XCTAssertEqual(sixteenth + sixteenth + sixteenth + sixteenth, quarter)

        // Dotted quarter = quarter + eighth
        let dottedQuarter = quarter + eighth
        XCTAssertEqual(dottedQuarter, Rational(3, 8))
    }

    func testTupletRatios() {
        // Triplet: 3 in the time of 2
        let tripletRatio = Rational(2, 3)
        let tripletEighth = Rational(1, 8) * tripletRatio
        XCTAssertEqual(tripletEighth, Rational(1, 12))

        // Three triplet eighths = one quarter
        let threeTripletsEighths = tripletEighth + tripletEighth + tripletEighth
        XCTAssertEqual(threeTripletsEighths, Rational(1, 4))
    }

    // MARK: - Edge Cases

    func testLargeNumbers() {
        let large = Rational(1000000, 2000000)
        XCTAssertEqual(large, Rational(1, 2))
    }

    func testComplexReduction() {
        let complex = Rational(144, 168)
        // GCD of 144 and 168 is 24
        XCTAssertEqual(complex.numerator, 6)
        XCTAssertEqual(complex.denominator, 7)
    }

    func testZeroOperations() {
        let zero = Rational.zero
        let half = Rational(1, 2)

        XCTAssertEqual(zero + half, half)
        XCTAssertEqual(half + zero, half)
        XCTAssertEqual(zero * half, zero)
        XCTAssertEqual(half - half, zero)
    }

    // MARK: - Codable Tests

    func testRationalCodable() throws {
        let rational = Rational(3, 7)
        let encoder = JSONEncoder()
        let data = try encoder.encode(rational)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Rational.self, from: data)
        XCTAssertEqual(rational, decoded)
    }

    // MARK: - Description Tests

    func testDescription() {
        let half = Rational(1, 2)
        XCTAssertEqual(half.description, "1/2")

        let whole = Rational(5, 1)
        XCTAssertEqual(whole.description, "5")

        let neg = Rational(-3, 4)
        XCTAssertEqual(neg.description, "-3/4")
    }
}
