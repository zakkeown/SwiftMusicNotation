import Foundation

/// A rational number represented as a fraction of two integers.
///
/// Used for precise duration arithmetic in music notation, avoiding
/// floating-point precision issues. Always stored in lowest terms.
public struct Rational: Hashable, Codable, Comparable, Sendable {
    /// The numerator of the fraction.
    public let numerator: Int

    /// The denominator of the fraction (always positive and non-zero).
    public let denominator: Int

    /// Creates a rational number, automatically reducing to lowest terms.
    public init(_ numerator: Int, _ denominator: Int) {
        precondition(denominator != 0, "Denominator cannot be zero")

        // Normalize sign (negative in numerator only)
        let sign = denominator < 0 ? -1 : 1
        let num = numerator * sign
        let den = abs(denominator)

        // Reduce to lowest terms
        let divisor = Self.gcd(abs(num), den)
        self.numerator = num / divisor
        self.denominator = den / divisor
    }

    /// Creates a rational from an integer.
    public init(_ value: Int) {
        self.numerator = value
        self.denominator = 1
    }

    /// The rational number zero.
    public static let zero = Rational(0, 1)

    /// The rational number one.
    public static let one = Rational(1, 1)

    // MARK: - Properties

    /// The value as a Double.
    public var doubleValue: Double {
        Double(numerator) / Double(denominator)
    }

    /// Whether this rational is zero.
    public var isZero: Bool {
        numerator == 0
    }

    /// Whether this rational is positive.
    public var isPositive: Bool {
        numerator > 0
    }

    /// Whether this rational is negative.
    public var isNegative: Bool {
        numerator < 0
    }

    /// Whether this rational represents an integer value.
    public var isInteger: Bool {
        denominator == 1
    }

    /// The absolute value.
    public var magnitude: Rational {
        Rational(abs(numerator), denominator)
    }

    /// The reciprocal (1/x).
    public var reciprocal: Rational {
        precondition(numerator != 0, "Cannot take reciprocal of zero")
        return Rational(denominator, numerator)
    }

    // MARK: - Arithmetic Operations

    public static func + (lhs: Rational, rhs: Rational) -> Rational {
        let num = lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator
        let den = lhs.denominator * rhs.denominator
        return Rational(num, den)
    }

    public static func - (lhs: Rational, rhs: Rational) -> Rational {
        let num = lhs.numerator * rhs.denominator - rhs.numerator * lhs.denominator
        let den = lhs.denominator * rhs.denominator
        return Rational(num, den)
    }

    public static func * (lhs: Rational, rhs: Rational) -> Rational {
        Rational(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
    }

    public static func / (lhs: Rational, rhs: Rational) -> Rational {
        precondition(!rhs.isZero, "Division by zero")
        return Rational(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator)
    }

    public static prefix func - (value: Rational) -> Rational {
        Rational(-value.numerator, value.denominator)
    }

    // MARK: - Compound Assignment

    public static func += (lhs: inout Rational, rhs: Rational) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Rational, rhs: Rational) {
        lhs = lhs - rhs
    }

    public static func *= (lhs: inout Rational, rhs: Rational) {
        lhs = lhs * rhs
    }

    public static func /= (lhs: inout Rational, rhs: Rational) {
        lhs = lhs / rhs
    }

    // MARK: - Integer Operations

    public static func * (lhs: Rational, rhs: Int) -> Rational {
        Rational(lhs.numerator * rhs, lhs.denominator)
    }

    public static func * (lhs: Int, rhs: Rational) -> Rational {
        rhs * lhs
    }

    public static func / (lhs: Rational, rhs: Int) -> Rational {
        precondition(rhs != 0, "Division by zero")
        return Rational(lhs.numerator, lhs.denominator * rhs)
    }

    // MARK: - Comparable

    public static func < (lhs: Rational, rhs: Rational) -> Bool {
        lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }

    // MARK: - Private Helpers

    /// Greatest common divisor using Euclidean algorithm.
    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }

    /// Least common multiple.
    private static func lcm(_ a: Int, _ b: Int) -> Int {
        (a / gcd(a, b)) * b
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Rational: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

// MARK: - CustomStringConvertible

extension Rational: CustomStringConvertible {
    public var description: String {
        if denominator == 1 {
            return "\(numerator)"
        }
        return "\(numerator)/\(denominator)"
    }
}

// MARK: - AdditiveArithmetic

extension Rational: AdditiveArithmetic {
    // Already conforms through + and - operators and zero property
}
