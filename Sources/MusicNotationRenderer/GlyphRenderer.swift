import Foundation
import CoreGraphics
import CoreText
import SMuFLKit

// MARK: - Glyph Renderer

/// Renders SMuFL glyphs using Core Text.
public final class GlyphRenderer {
    /// The loaded SMuFL font.
    public var font: LoadedSMuFLFont

    /// Cache for glyph IDs.
    private var glyphCache: [SMuFLGlyphName: CGGlyph] = [:]

    /// Cache for glyph bounding boxes.
    private var boundsCache: [SMuFLGlyphName: CGRect] = [:]

    public init(font: LoadedSMuFLFont) {
        self.font = font
    }

    // MARK: - Basic Glyph Rendering

    /// Renders a single glyph at the specified position.
    public func renderGlyph(
        _ glyphName: SMuFLGlyphName,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        guard let glyph = getGlyph(for: glyphName), glyph != 0 else { return }

        context.saveGState()
        context.setFillColor(color)

        var glyphPosition = position
        var glyphId = glyph
        CTFontDrawGlyphs(font.ctFont, &glyphId, &glyphPosition, 1, context)

        context.restoreGState()
    }

    /// Renders a glyph with anchor alignment.
    public func renderGlyphAligned(
        _ glyphName: SMuFLGlyphName,
        at position: CGPoint,
        anchor: GlyphAnchor,
        color: CGColor,
        in context: CGContext
    ) {
        let offset = getAnchorOffset(for: glyphName, anchor: anchor)
        let alignedPosition = CGPoint(
            x: position.x - offset.x,
            y: position.y - offset.y
        )
        renderGlyph(glyphName, at: alignedPosition, color: color, in: context)
    }

    /// Renders multiple glyphs at once (more efficient for sequences).
    public func renderGlyphs(
        _ glyphs: [(name: SMuFLGlyphName, position: CGPoint)],
        color: CGColor,
        in context: CGContext
    ) {
        guard !glyphs.isEmpty else { return }

        context.saveGState()
        context.setFillColor(color)

        var glyphIds: [CGGlyph] = []
        var positions: [CGPoint] = []

        for (name, position) in glyphs {
            if let glyph = getGlyph(for: name), glyph != 0 {
                glyphIds.append(glyph)
                positions.append(position)
            }
        }

        if !glyphIds.isEmpty {
            CTFontDrawGlyphs(font.ctFont, &glyphIds, &positions, glyphIds.count, context)
        }

        context.restoreGState()
    }

    // MARK: - Styled Glyph Rendering

    /// Renders a glyph with scaling.
    public func renderGlyphScaled(
        _ glyphName: SMuFLGlyphName,
        at position: CGPoint,
        scale: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        guard scale != 1.0 else {
            renderGlyph(glyphName, at: position, color: color, in: context)
            return
        }

        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.scaleBy(x: scale, y: scale)

        renderGlyph(glyphName, at: .zero, color: color, in: context)

        context.restoreGState()
    }

    /// Renders a glyph with rotation.
    public func renderGlyphRotated(
        _ glyphName: SMuFLGlyphName,
        at position: CGPoint,
        angle: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.rotate(by: angle)

        renderGlyph(glyphName, at: .zero, color: color, in: context)

        context.restoreGState()
    }

    /// Renders a glyph with a transformation matrix.
    public func renderGlyphTransformed(
        _ glyphName: SMuFLGlyphName,
        at position: CGPoint,
        transform: CGAffineTransform,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.concatenate(transform)

        renderGlyph(glyphName, at: .zero, color: color, in: context)

        context.restoreGState()
    }

    // MARK: - Special Glyph Rendering

    /// Renders a brace (which needs vertical stretching).
    public func renderBrace(
        at x: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let height = bottomY - topY

        // Get the brace glyph bounds
        let braceBounds = getBounds(for: .brace)
        guard braceBounds.height > 0 else { return }

        let scaleY = height / braceBounds.height

        context.saveGState()
        context.translateBy(x: x, y: topY)
        context.scaleBy(x: 1.0, y: scaleY)

        // Adjust position based on brace origin
        let adjustedY = -braceBounds.minY
        renderGlyph(.brace, at: CGPoint(x: 0, y: adjustedY), color: color, in: context)

        context.restoreGState()
    }

    /// Renders a bracket with end caps.
    public func renderBracket(
        at x: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        thickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        // Main vertical line
        let lineRect = CGRect(
            x: x - thickness / 2,
            y: topY,
            width: thickness,
            height: bottomY - topY
        )
        context.fill(lineRect)

        // Top cap (horizontal hook)
        let capWidth: CGFloat = thickness * 3
        let topCap = CGRect(
            x: x - thickness / 2,
            y: topY - thickness / 2,
            width: capWidth,
            height: thickness
        )
        context.fill(topCap)

        // Bottom cap
        let bottomCap = CGRect(
            x: x - thickness / 2,
            y: bottomY - thickness / 2,
            width: capWidth,
            height: thickness
        )
        context.fill(bottomCap)

        context.restoreGState()
    }

    /// Renders a clef glyph.
    /// Note: For clefs with octave change, use the combined glyphs like gClef8va, gClef8vb, etc.
    public func renderClef(
        _ clefGlyph: SMuFLGlyphName,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        renderGlyph(clefGlyph, at: position, color: color, in: context)
    }

    // MARK: - Glyph Information

    /// Gets the glyph ID for a glyph name.
    public func getGlyph(for name: SMuFLGlyphName) -> CGGlyph? {
        if let cached = glyphCache[name] {
            return cached
        }

        let glyphNameString = name.rawValue as CFString
        let glyph = CTFontGetGlyphWithName(font.ctFont, glyphNameString)

        if glyph != 0 {
            glyphCache[name] = glyph
            return glyph
        }

        return nil
    }

    /// Gets the bounding box for a glyph.
    public func getBounds(for name: SMuFLGlyphName) -> CGRect {
        if let cached = boundsCache[name] {
            return cached
        }

        guard let glyph = getGlyph(for: name), glyph != 0 else {
            return .zero
        }

        var glyphId = glyph
        var bounds = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(font.ctFont, .default, &glyphId, &bounds, 1)

        boundsCache[name] = bounds
        return bounds
    }

    /// Gets the advance width for a glyph.
    public func getAdvance(for name: SMuFLGlyphName) -> CGFloat {
        guard let glyph = getGlyph(for: name), glyph != 0 else {
            return 0
        }

        var glyphId = glyph
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font.ctFont, .default, &glyphId, &advance, 1)

        return advance.width
    }

    /// Gets anchor offset for a glyph.
    public func getAnchorOffset(for name: SMuFLGlyphName, anchor: GlyphAnchor) -> CGPoint {
        // Check font metadata for anchor points
        if let glyphAnchors = font.anchors(for: name) {
            let anchorType: AnchorType?
            switch anchor {
            case .stemUpSE:
                anchorType = .stemUpSE
            case .stemDownNW:
                anchorType = .stemDownNW
            case .stemUpNW:
                anchorType = .stemUpNW
            case .stemDownSW:
                anchorType = .stemDownSW
            case .cutOutNE:
                anchorType = .cutOutNE
            case .cutOutNW:
                anchorType = .cutOutNW
            case .cutOutSE:
                anchorType = .cutOutSE
            case .cutOutSW:
                anchorType = .cutOutSW
            case .center, .origin:
                anchorType = nil
            }

            if let type = anchorType, let point = glyphAnchors.point(for: type) {
                return point
            }
        }

        // Fallback to geometric calculation
        let bounds = getBounds(for: name)
        switch anchor {
        case .stemUpSE:
            return CGPoint(x: bounds.maxX, y: bounds.minY)
        case .stemDownNW:
            return CGPoint(x: bounds.minX, y: bounds.maxY)
        case .stemUpNW:
            return CGPoint(x: bounds.minX, y: bounds.minY)
        case .stemDownSW:
            return CGPoint(x: bounds.minX, y: bounds.maxY)
        case .center:
            return CGPoint(x: bounds.midX, y: bounds.midY)
        case .origin, .cutOutNE, .cutOutNW, .cutOutSE, .cutOutSW:
            return .zero
        }
    }

    /// Clears the glyph cache.
    public func clearCache() {
        glyphCache.removeAll()
        boundsCache.removeAll()
    }
}

// MARK: - Glyph Anchor

/// Anchor points for glyph alignment.
public enum GlyphAnchor: String, Sendable {
    /// Southeast anchor for stem-up noteheads.
    case stemUpSE

    /// Northwest anchor for stem-down noteheads.
    case stemDownNW

    /// Northwest anchor for stem-up noteheads.
    case stemUpNW

    /// Southwest anchor for stem-down noteheads.
    case stemDownSW

    /// Northeast cutout for accidental stacking.
    case cutOutNE

    /// Northwest cutout for accidental stacking.
    case cutOutNW

    /// Southeast cutout for accidental stacking.
    case cutOutSE

    /// Southwest cutout for accidental stacking.
    case cutOutSW

    /// Center of the glyph.
    case center

    /// Origin (0, 0) of the glyph.
    case origin
}

// MARK: - Glyph Run

/// A sequence of glyphs to render together.
public struct GlyphRun: Sendable {
    /// The glyphs in this run.
    public var glyphs: [(name: SMuFLGlyphName, position: CGPoint)]

    /// Color for the run.
    public var color: CGColor

    /// Optional transform.
    public var transform: CGAffineTransform?

    public init(
        glyphs: [(name: SMuFLGlyphName, position: CGPoint)],
        color: CGColor,
        transform: CGAffineTransform? = nil
    ) {
        self.glyphs = glyphs
        self.color = color
        self.transform = transform
    }

    /// Creates a run for a single glyph.
    public static func single(_ name: SMuFLGlyphName, at position: CGPoint, color: CGColor) -> GlyphRun {
        GlyphRun(glyphs: [(name, position)], color: color)
    }
}

// MARK: - Composite Glyph Rendering

extension GlyphRenderer {
    /// Renders time signature digits.
    public func renderTimeSignatureDigits(
        _ number: Int,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        let digits = String(number).compactMap { Int(String($0)) }
        var x = position.x

        for digit in digits {
            let glyph = timeSignatureGlyph(for: digit)
            renderGlyph(glyph, at: CGPoint(x: x, y: position.y), color: color, in: context)
            x += getAdvance(for: glyph)
        }
    }

    /// Gets the time signature glyph for a digit.
    private func timeSignatureGlyph(for digit: Int) -> SMuFLGlyphName {
        switch digit {
        case 0: return .timeSig0
        case 1: return .timeSig1
        case 2: return .timeSig2
        case 3: return .timeSig3
        case 4: return .timeSig4
        case 5: return .timeSig5
        case 6: return .timeSig6
        case 7: return .timeSig7
        case 8: return .timeSig8
        case 9: return .timeSig9
        default: return .timeSig0
        }
    }

    /// Renders a key signature.
    public func renderKeySignature(
        accidentals: [(glyph: SMuFLGlyphName, staffPosition: Int)],
        at startX: CGFloat,
        staffTop: CGFloat,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        var x = startX

        for (glyph, staffPosition) in accidentals {
            // Convert staff position to Y coordinate
            // Staff position 0 = middle line (line 3), each position = half staff space
            let y = staffTop + staffSpacing * 2 - CGFloat(staffPosition) * (staffSpacing / 2)

            renderGlyph(glyph, at: CGPoint(x: x, y: y), color: color, in: context)
            x += getAdvance(for: glyph) + 1 // Small gap between accidentals
        }
    }

    /// Total width of time signature digits.
    public func timeSignatureWidth(_ number: Int) -> CGFloat {
        let digits = String(number).compactMap { Int(String($0)) }
        return digits.reduce(0) { $0 + getAdvance(for: timeSignatureGlyph(for: $1)) }
    }
}
