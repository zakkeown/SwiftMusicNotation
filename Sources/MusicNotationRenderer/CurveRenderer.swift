import Foundation
import CoreGraphics

// MARK: - Curve Renderer

/// Renders slurs, ties, and other curved lines in music notation.
///
/// `CurveRenderer` handles the rendering of curved elements that connect notes or indicate
/// phrasing. It supports both ties (same pitch connection) and slurs (phrase groupings),
/// each with distinct visual characteristics.
///
/// ## Ties vs. Slurs
///
/// - **Ties**: Uniform thickness, relatively flat curves, connect notes of the same pitch
/// - **Slurs**: Variable thickness (thin at ends, thick in middle), more pronounced curves
///
/// ## Bezier Curve Implementation
///
/// Curves are rendered using quadratic or cubic Bezier curves:
/// - Quadratic: Used for shorter ties with a single control point
/// - Cubic: Used for longer slurs with two control points for finer shape control
///
/// ## Variable Thickness
///
/// Slurs use a variable thickness technique where the curve is rendered as a filled shape
/// rather than a stroked path. The shape is built by sampling points along the curve and
/// creating offset outer/inner edges.
///
/// ## Usage
///
/// ```swift
/// let renderer = CurveRenderer()
///
/// // Render a tie
/// renderer.renderTie(
///     from: CGPoint(x: 100, y: 100),
///     to: CGPoint(x: 150, y: 100),
///     direction: .above,
///     color: CGColor.black,
///     in: context
/// )
///
/// // Render a slur
/// renderer.renderSlur(
///     from: CGPoint(x: 100, y: 100),
///     to: CGPoint(x: 300, y: 120),
///     direction: .above,
///     color: CGColor.black,
///     in: context
/// )
/// ```
///
/// - SeeAlso: ``CurveRenderConfiguration`` for customization options
/// - SeeAlso: ``NoteRenderer`` for related note rendering
public final class CurveRenderer {
    /// Configuration for curve rendering.
    public var config: CurveRenderConfiguration

    public init(config: CurveRenderConfiguration = CurveRenderConfiguration()) {
        self.config = config
    }

    // MARK: - Tie Rendering

    /// Renders a tie between two notes.
    public func renderTie(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        direction: CurveDirectionType,
        color: CGColor,
        in context: CGContext
    ) {
        let controlHeight = calculateTieHeight(distance: endPoint.x - startPoint.x)
        renderCurve(
            from: startPoint,
            to: endPoint,
            height: controlHeight,
            direction: direction,
            thickness: config.tieThickness,
            color: color,
            in: context
        )
    }

    /// Renders a tie with custom height.
    public func renderTie(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        height: CGFloat,
        direction: CurveDirectionType,
        color: CGColor,
        in context: CGContext
    ) {
        renderCurve(
            from: startPoint,
            to: endPoint,
            height: height,
            direction: direction,
            thickness: config.tieThickness,
            color: color,
            in: context
        )
    }

    // MARK: - Slur Rendering

    /// Renders a slur.
    public func renderSlur(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        direction: CurveDirectionType,
        color: CGColor,
        in context: CGContext
    ) {
        let controlHeight = calculateSlurHeight(distance: endPoint.x - startPoint.x)
        renderVariableThicknessCurve(
            from: startPoint,
            to: endPoint,
            height: controlHeight,
            direction: direction,
            startThickness: config.slurEndThickness,
            midThickness: config.slurMidThickness,
            endThickness: config.slurEndThickness,
            color: color,
            in: context
        )
    }

    /// Renders a slur with control points.
    public func renderSlur(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        controlPoint1: CGPoint,
        controlPoint2: CGPoint,
        direction: CurveDirectionType,
        color: CGColor,
        in context: CGContext
    ) {
        renderCubicCurve(
            from: startPoint,
            to: endPoint,
            control1: controlPoint1,
            control2: controlPoint2,
            direction: direction,
            startThickness: config.slurEndThickness,
            midThickness: config.slurMidThickness,
            endThickness: config.slurEndThickness,
            color: color,
            in: context
        )
    }

    // MARK: - Generic Curve Rendering

    /// Renders a simple curve (uniform thickness).
    public func renderCurve(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        height: CGFloat,
        direction: CurveDirectionType,
        thickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let controlPoint = calculateControlPoint(
            start: startPoint,
            end: endPoint,
            height: height,
            direction: direction
        )

        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(thickness)
        context.setLineCap(.round)

        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)

        context.addPath(path)
        context.strokePath()

        context.restoreGState()
    }

    /// Renders a curve with variable thickness (for slurs).
    public func renderVariableThicknessCurve(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        height: CGFloat,
        direction: CurveDirectionType,
        startThickness: CGFloat,
        midThickness: CGFloat,
        endThickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let controlPoint = calculateControlPoint(
            start: startPoint,
            end: endPoint,
            height: height,
            direction: direction
        )

        // Create a filled shape for variable thickness
        context.saveGState()
        context.setFillColor(color)

        let path = createVariableThicknessCurvePath(
            start: startPoint,
            end: endPoint,
            control: controlPoint,
            direction: direction,
            startThickness: startThickness,
            midThickness: midThickness,
            endThickness: endThickness
        )

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    /// Renders a cubic bezier curve with variable thickness.
    public func renderCubicCurve(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        direction: CurveDirectionType,
        startThickness: CGFloat,
        midThickness: CGFloat,
        endThickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        let path = createVariableThicknessCubicPath(
            start: startPoint,
            end: endPoint,
            control1: control1,
            control2: control2,
            direction: direction,
            startThickness: startThickness,
            midThickness: midThickness,
            endThickness: endThickness
        )

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    // MARK: - Phrase Marks and Long Slurs

    /// Renders a long slur with multiple control points for better shape.
    public func renderLongSlur(
        points: [CGPoint],
        direction: CurveDirectionType,
        color: CGColor,
        in context: CGContext
    ) {
        guard points.count >= 2 else { return }

        context.saveGState()
        context.setFillColor(color)

        // Use Catmull-Rom spline or similar for smooth curve through points
        let path = createSmoothCurvePath(
            through: points,
            direction: direction,
            thickness: config.slurMidThickness
        )

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    // MARK: - Laissez Vibrer Ties

    /// Renders a laissez vibrer tie (open-ended).
    public func renderLaissezVibrerTie(
        from startPoint: CGPoint,
        direction: CurveDirectionType,
        length: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let endPoint = CGPoint(x: startPoint.x + length, y: startPoint.y)
        let height = config.lvTieHeight

        let controlPoint = calculateControlPoint(
            start: startPoint,
            end: endPoint,
            height: height,
            direction: direction
        )

        context.saveGState()
        context.setFillColor(color)

        // Create tapered curve that fades to nothing
        let path = createTaperedCurvePath(
            start: startPoint,
            end: endPoint,
            control: controlPoint,
            direction: direction,
            startThickness: config.tieThickness,
            endThickness: 0
        )

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    // MARK: - Helper Methods

    /// Calculates the control point for a quadratic bezier curve.
    private func calculateControlPoint(
        start: CGPoint,
        end: CGPoint,
        height: CGFloat,
        direction: CurveDirectionType
    ) -> CGPoint {
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2

        let directionMultiplier: CGFloat = direction == .above ? -1 : 1

        return CGPoint(
            x: midX,
            y: midY + height * directionMultiplier
        )
    }

    /// Calculates tie height based on distance.
    private func calculateTieHeight(distance: CGFloat) -> CGFloat {
        // Ties have relatively flat curves
        let baseHeight = config.minTieHeight
        let additionalHeight = min(distance * config.tieHeightRatio, config.maxTieHeight - baseHeight)
        return baseHeight + additionalHeight
    }

    /// Calculates slur height based on distance.
    private func calculateSlurHeight(distance: CGFloat) -> CGFloat {
        // Slurs have more pronounced curves
        let baseHeight = config.minSlurHeight
        let additionalHeight = min(distance * config.slurHeightRatio, config.maxSlurHeight - baseHeight)
        return baseHeight + additionalHeight
    }

    /// Creates a path for a variable thickness quadratic curve.
    private func createVariableThicknessCurvePath(
        start: CGPoint,
        end: CGPoint,
        control: CGPoint,
        direction: CurveDirectionType,
        startThickness: CGFloat,
        midThickness: CGFloat,
        endThickness: CGFloat
    ) -> CGPath {
        let directionMultiplier: CGFloat = direction == .above ? -1 : 1
        let segments = 20

        let path = CGMutablePath()

        // Generate points along the outer edge
        var outerPoints: [CGPoint] = []
        var innerPoints: [CGPoint] = []

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = quadraticBezierPoint(start: start, control: control, end: end, t: t)

            // Calculate thickness at this point (interpolate)
            let thickness: CGFloat
            if t < 0.5 {
                thickness = startThickness + (midThickness - startThickness) * (t * 2)
            } else {
                thickness = midThickness + (endThickness - midThickness) * ((t - 0.5) * 2)
            }

            let halfThickness = thickness / 2

            outerPoints.append(CGPoint(
                x: point.x,
                y: point.y + halfThickness * directionMultiplier
            ))
            innerPoints.append(CGPoint(
                x: point.x,
                y: point.y - halfThickness * directionMultiplier
            ))
        }

        // Build path: outer edge forward, inner edge backward
        path.move(to: outerPoints[0])
        for point in outerPoints.dropFirst() {
            path.addLine(to: point)
        }
        for point in innerPoints.reversed() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path
    }

    /// Creates a path for a variable thickness cubic curve.
    private func createVariableThicknessCubicPath(
        start: CGPoint,
        end: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        direction: CurveDirectionType,
        startThickness: CGFloat,
        midThickness: CGFloat,
        endThickness: CGFloat
    ) -> CGPath {
        let directionMultiplier: CGFloat = direction == .above ? -1 : 1
        let segments = 30

        let path = CGMutablePath()

        var outerPoints: [CGPoint] = []
        var innerPoints: [CGPoint] = []

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = cubicBezierPoint(start: start, control1: control1, control2: control2, end: end, t: t)

            let thickness: CGFloat
            if t < 0.5 {
                thickness = startThickness + (midThickness - startThickness) * (t * 2)
            } else {
                thickness = midThickness + (endThickness - midThickness) * ((t - 0.5) * 2)
            }

            let halfThickness = thickness / 2

            outerPoints.append(CGPoint(
                x: point.x,
                y: point.y + halfThickness * directionMultiplier
            ))
            innerPoints.append(CGPoint(
                x: point.x,
                y: point.y - halfThickness * directionMultiplier
            ))
        }

        path.move(to: outerPoints[0])
        for point in outerPoints.dropFirst() {
            path.addLine(to: point)
        }
        for point in innerPoints.reversed() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path
    }

    /// Creates a tapered curve path.
    private func createTaperedCurvePath(
        start: CGPoint,
        end: CGPoint,
        control: CGPoint,
        direction: CurveDirectionType,
        startThickness: CGFloat,
        endThickness: CGFloat
    ) -> CGPath {
        let directionMultiplier: CGFloat = direction == .above ? -1 : 1
        let segments = 15

        let path = CGMutablePath()

        var outerPoints: [CGPoint] = []
        var innerPoints: [CGPoint] = []

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = quadraticBezierPoint(start: start, control: control, end: end, t: t)
            let thickness = startThickness + (endThickness - startThickness) * t
            let halfThickness = thickness / 2

            outerPoints.append(CGPoint(
                x: point.x,
                y: point.y + halfThickness * directionMultiplier
            ))
            innerPoints.append(CGPoint(
                x: point.x,
                y: point.y - halfThickness * directionMultiplier
            ))
        }

        path.move(to: outerPoints[0])
        for point in outerPoints.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: end) // Taper to point
        for point in innerPoints.reversed().dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path
    }

    /// Creates a smooth curve path through multiple points.
    private func createSmoothCurvePath(
        through points: [CGPoint],
        direction: CurveDirectionType,
        thickness: CGFloat
    ) -> CGPath {
        guard points.count >= 2 else { return CGMutablePath() }

        let path = CGMutablePath()
        let directionMultiplier: CGFloat = direction == .above ? -1 : 1
        let halfThickness = thickness / 2

        // Simple implementation: connect with line segments offset for thickness
        let outerPoints: [CGPoint] = points.map {
            CGPoint(x: $0.x, y: $0.y + halfThickness * directionMultiplier)
        }
        let innerPoints: [CGPoint] = points.map {
            CGPoint(x: $0.x, y: $0.y - halfThickness * directionMultiplier)
        }

        path.move(to: outerPoints[0])
        for point in outerPoints.dropFirst() {
            path.addLine(to: point)
        }
        for point in innerPoints.reversed() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path
    }

    /// Calculates a point on a quadratic bezier curve.
    private func quadraticBezierPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }

    /// Calculates a point on a cubic bezier curve.
    private func cubicBezierPoint(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let oneMinusT2 = oneMinusT * oneMinusT
        let oneMinusT3 = oneMinusT2 * oneMinusT
        let t2 = t * t
        let t3 = t2 * t

        let x = oneMinusT3 * start.x + 3 * oneMinusT2 * t * control1.x + 3 * oneMinusT * t2 * control2.x + t3 * end.x
        let y = oneMinusT3 * start.y + 3 * oneMinusT2 * t * control1.y + 3 * oneMinusT * t2 * control2.y + t3 * end.y

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Curve Render Configuration

/// Configuration for curve rendering.
public struct CurveRenderConfiguration: Sendable {
    /// Tie thickness.
    public var tieThickness: CGFloat = 0.16

    /// Minimum tie height.
    public var minTieHeight: CGFloat = 0.5

    /// Maximum tie height.
    public var maxTieHeight: CGFloat = 2.0

    /// Tie height ratio (height per unit distance).
    public var tieHeightRatio: CGFloat = 0.1

    /// Slur thickness at ends.
    public var slurEndThickness: CGFloat = 0.1

    /// Slur thickness at middle.
    public var slurMidThickness: CGFloat = 0.25

    /// Minimum slur height.
    public var minSlurHeight: CGFloat = 1.0

    /// Maximum slur height.
    public var maxSlurHeight: CGFloat = 4.0

    /// Slur height ratio.
    public var slurHeightRatio: CGFloat = 0.15

    /// Laissez vibrer tie height.
    public var lvTieHeight: CGFloat = 1.0

    public init() {}
}

// MARK: - Curve Direction Type

/// Direction for curve placement.
public enum CurveDirectionType: String, Sendable {
    case above
    case below

    /// Inverts the direction.
    public var inverted: CurveDirectionType {
        self == .above ? .below : .above
    }
}

// MARK: - Curve Render Info

/// Information for rendering a curve.
public struct CurveRenderInfo: Sendable {
    /// Start point.
    public var startPoint: CGPoint

    /// End point.
    public var endPoint: CGPoint

    /// Direction.
    public var direction: CurveDirectionType

    /// Control point 1 (for cubic curves).
    public var controlPoint1: CGPoint?

    /// Control point 2 (for cubic curves).
    public var controlPoint2: CGPoint?

    /// Whether this is a tie (vs slur).
    public var isTie: Bool

    public init(
        startPoint: CGPoint,
        endPoint: CGPoint,
        direction: CurveDirectionType,
        controlPoint1: CGPoint? = nil,
        controlPoint2: CGPoint? = nil,
        isTie: Bool = false
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.direction = direction
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
        self.isTie = isTie
    }
}
