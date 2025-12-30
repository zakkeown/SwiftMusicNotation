import Foundation
import CoreGraphics

// MARK: - Staff Spaces

/// A measurement in staff spaces (the SMuFL standard unit).
/// One staff space equals the distance between two adjacent staff lines.
public struct StaffSpaces: Hashable, Sendable {
    /// The value in staff spaces.
    public var value: Double

    public init(_ value: Double) {
        self.value = value
    }

    /// Zero staff spaces.
    public static let zero = StaffSpaces(0)

    /// One staff space.
    public static let one = StaffSpaces(1)

    /// Converts to points given a staff height in points.
    /// Staff height is the distance from the bottom line to the top line (4 staff spaces).
    public func toPoints(staffHeight: CGFloat) -> CGFloat {
        CGFloat(value) * (staffHeight / 4.0)
    }

    /// Creates from points given a staff height.
    public static func fromPoints(_ points: CGFloat, staffHeight: CGFloat) -> StaffSpaces {
        StaffSpaces(Double(points / (staffHeight / 4.0)))
    }
}

// MARK: - StaffSpaces Arithmetic

extension StaffSpaces {
    public static func + (lhs: StaffSpaces, rhs: StaffSpaces) -> StaffSpaces {
        StaffSpaces(lhs.value + rhs.value)
    }

    public static func - (lhs: StaffSpaces, rhs: StaffSpaces) -> StaffSpaces {
        StaffSpaces(lhs.value - rhs.value)
    }

    public static func * (lhs: StaffSpaces, rhs: Double) -> StaffSpaces {
        StaffSpaces(lhs.value * rhs)
    }

    public static func * (lhs: Double, rhs: StaffSpaces) -> StaffSpaces {
        StaffSpaces(lhs * rhs.value)
    }

    public static func / (lhs: StaffSpaces, rhs: Double) -> StaffSpaces {
        StaffSpaces(lhs.value / rhs)
    }

    public static prefix func - (value: StaffSpaces) -> StaffSpaces {
        StaffSpaces(-value.value)
    }
}

extension StaffSpaces: Comparable {
    public static func < (lhs: StaffSpaces, rhs: StaffSpaces) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Tenths

/// A measurement in tenths (MusicXML internal units).
/// Tenths are defined relative to the staff interline space via the scaling element.
public struct Tenths: Hashable, Sendable {
    /// The value in tenths.
    public var value: Double

    public init(_ value: Double) {
        self.value = value
    }

    /// Zero tenths.
    public static let zero = Tenths(0)

    /// Converts to staff spaces.
    /// By default, 40 tenths = 1 staff space (MusicXML convention).
    public func toStaffSpaces(tenthsPerStaffSpace: Double = 40) -> StaffSpaces {
        StaffSpaces(value / tenthsPerStaffSpace)
    }

    /// Creates from staff spaces.
    public static func fromStaffSpaces(_ staffSpaces: StaffSpaces, tenthsPerStaffSpace: Double = 40) -> Tenths {
        Tenths(staffSpaces.value * tenthsPerStaffSpace)
    }

    /// Converts to points given millimeters per tenths from MusicXML scaling.
    public func toPoints(millimeters: Double, tenths: Double) -> CGFloat {
        // mm/tenths * value * points/mm (72 points/inch, 25.4 mm/inch)
        let mmPerTenth = millimeters / tenths
        let pointsPerMm = 72.0 / 25.4
        return CGFloat(value * mmPerTenth * pointsPerMm)
    }
}

// MARK: - Tenths Arithmetic

extension Tenths {
    public static func + (lhs: Tenths, rhs: Tenths) -> Tenths {
        Tenths(lhs.value + rhs.value)
    }

    public static func - (lhs: Tenths, rhs: Tenths) -> Tenths {
        Tenths(lhs.value - rhs.value)
    }

    public static func * (lhs: Tenths, rhs: Double) -> Tenths {
        Tenths(lhs.value * rhs)
    }

    public static func / (lhs: Tenths, rhs: Double) -> Tenths {
        Tenths(lhs.value / rhs)
    }
}

extension Tenths: Comparable {
    public static func < (lhs: Tenths, rhs: Tenths) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Position Types

/// A position in staff space coordinates.
public struct StaffPosition: Hashable, Sendable {
    /// X coordinate in staff spaces from the left edge of the staff.
    public var x: StaffSpaces

    /// Y coordinate in staff spaces from the center line of the staff.
    /// Positive is up, negative is down.
    public var y: StaffSpaces

    public init(x: StaffSpaces, y: StaffSpaces) {
        self.x = x
        self.y = y
    }

    public static let zero = StaffPosition(x: .zero, y: .zero)

    /// Converts to CGPoint given staff height.
    public func toPoint(staffHeight: CGFloat) -> CGPoint {
        CGPoint(
            x: x.toPoints(staffHeight: staffHeight),
            y: y.toPoints(staffHeight: staffHeight)
        )
    }
}

/// A size in staff space coordinates.
public struct StaffSize: Hashable, Sendable {
    /// Width in staff spaces.
    public var width: StaffSpaces

    /// Height in staff spaces.
    public var height: StaffSpaces

    public init(width: StaffSpaces, height: StaffSpaces) {
        self.width = width
        self.height = height
    }

    public static let zero = StaffSize(width: .zero, height: .zero)

    /// Converts to CGSize given staff height.
    public func toSize(staffHeight: CGFloat) -> CGSize {
        CGSize(
            width: width.toPoints(staffHeight: staffHeight),
            height: height.toPoints(staffHeight: staffHeight)
        )
    }
}

/// A rectangle in staff space coordinates.
public struct StaffRect: Hashable, Sendable {
    /// Origin position.
    public var origin: StaffPosition

    /// Size.
    public var size: StaffSize

    public init(origin: StaffPosition, size: StaffSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: StaffSpaces, y: StaffSpaces, width: StaffSpaces, height: StaffSpaces) {
        self.origin = StaffPosition(x: x, y: y)
        self.size = StaffSize(width: width, height: height)
    }

    public static let zero = StaffRect(origin: .zero, size: .zero)

    public var minX: StaffSpaces { origin.x }
    public var maxX: StaffSpaces { origin.x + size.width }
    public var minY: StaffSpaces { origin.y }
    public var maxY: StaffSpaces { origin.y + size.height }

    public var midX: StaffSpaces { origin.x + size.width / 2 }
    public var midY: StaffSpaces { origin.y + size.height / 2 }

    /// Converts to CGRect given staff height.
    public func toRect(staffHeight: CGFloat) -> CGRect {
        CGRect(
            origin: origin.toPoint(staffHeight: staffHeight),
            size: size.toSize(staffHeight: staffHeight)
        )
    }

    /// Tests if this rectangle intersects another.
    public func intersects(_ other: StaffRect) -> Bool {
        !(maxX < other.minX || other.maxX < minX ||
          maxY < other.minY || other.maxY < minY)
    }

    /// Returns the union of this rectangle with another.
    public func union(_ other: StaffRect) -> StaffRect {
        let minX = Swift.min(self.minX.value, other.minX.value)
        let minY = Swift.min(self.minY.value, other.minY.value)
        let maxX = Swift.max(self.maxX.value, other.maxX.value)
        let maxY = Swift.max(self.maxY.value, other.maxY.value)

        return StaffRect(
            x: StaffSpaces(minX),
            y: StaffSpaces(minY),
            width: StaffSpaces(maxX - minX),
            height: StaffSpaces(maxY - minY)
        )
    }

    /// Expands the rectangle by the given insets.
    public func inset(by insets: StaffSpaces) -> StaffRect {
        StaffRect(
            x: origin.x - insets,
            y: origin.y - insets,
            width: size.width + insets * 2,
            height: size.height + insets * 2
        )
    }
}

// MARK: - Scaling Context

/// Context for converting between MusicXML tenths and points.
public struct ScalingContext: Sendable {
    /// Millimeters per staff space (from MusicXML scaling).
    public var millimetersPerStaffSpace: Double

    /// Tenths per staff space (typically 40 in MusicXML).
    public var tenthsPerStaffSpace: Double

    /// Staff height in points.
    public var staffHeightPoints: CGFloat

    public init(
        millimetersPerStaffSpace: Double = 7.2143,  // Typical music engraving default
        tenthsPerStaffSpace: Double = 40,
        staffHeightPoints: CGFloat = 40  // Typical screen display height
    ) {
        self.millimetersPerStaffSpace = millimetersPerStaffSpace
        self.tenthsPerStaffSpace = tenthsPerStaffSpace
        self.staffHeightPoints = staffHeightPoints
    }

    /// Creates from MusicXML scaling element values.
    public init(millimeters: Double, tenths: Double, staffHeightPoints: CGFloat) {
        // scaling: millimeters = size of 'tenths' tenths in mm
        // So mm/tenths gives us mm per tenth
        // We want mm per staff space = mm/tenths * tenths/staffSpace
        self.millimetersPerStaffSpace = (millimeters / tenths) * 40
        self.tenthsPerStaffSpace = 40
        self.staffHeightPoints = staffHeightPoints
    }

    /// Points per staff space.
    public var pointsPerStaffSpace: CGFloat {
        staffHeightPoints / 4.0
    }

    /// Converts tenths to points.
    public func tenthsToPoints(_ tenths: Tenths) -> CGFloat {
        let staffSpaces = tenths.toStaffSpaces(tenthsPerStaffSpace: tenthsPerStaffSpace)
        return staffSpaces.toPoints(staffHeight: staffHeightPoints)
    }

    /// Converts staff spaces to points.
    public func staffSpacesToPoints(_ staffSpaces: StaffSpaces) -> CGFloat {
        staffSpaces.toPoints(staffHeight: staffHeightPoints)
    }
}
