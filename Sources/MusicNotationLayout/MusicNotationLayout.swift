// MusicNotationLayout Module
// Layout engine for computing music notation positions

import Foundation
import CoreGraphics
import MusicNotationCore
import SMuFLKit

// MARK: - Layout Engine

/// Computes precise positions for all elements in a music score.
///
/// `LayoutEngine` transforms a `Score` into an `EngravedScore` with computed
/// positions for every notation element. This is the second stage of the
/// rendering pipeline:
///
/// ```
/// MusicXML → Score → LayoutEngine → EngravedScore → Renderer
/// ```
///
/// ## Basic Usage
///
/// ```swift
/// let layoutEngine = LayoutEngine()
/// let context = LayoutContext.letterSize(staffHeight: 40)
///
/// let engravedScore = layoutEngine.layout(score: score, context: context)
///
/// // Access computed layout
/// for page in engravedScore.pages {
///     print("Page \(page.pageNumber): \(page.systems.count) systems")
/// }
/// ```
///
/// ## Layout Pipeline
///
/// The engine performs layout in several stages:
///
/// 1. **Horizontal Spacing**: Compute widths for each measure based on note
///    durations and element types
/// 2. **System Breaks**: Determine which measures fit on each line (system)
/// 3. **Vertical Spacing**: Position staves within each system
/// 4. **Page Breaks**: Distribute systems across pages
/// 5. **Element Positioning**: Compute final positions for all elements
///
/// ## Configuration
///
/// Customize layout behavior with ``LayoutConfiguration``:
///
/// ```swift
/// var config = LayoutConfiguration()
/// config.firstPageTopOffset = 80  // Extra space for title
/// config.clefWidth = 25
///
/// let engine = LayoutEngine(config: config)
/// ```
///
/// ## Layout Context
///
/// Use ``LayoutContext`` to specify page size and display settings:
///
/// ```swift
/// // US Letter with 1-inch margins
/// let context = LayoutContext.letterSize(staffHeight: 40)
///
/// // A4 paper
/// let context = LayoutContext.a4Size(staffHeight: 35)
///
/// // Custom size
/// let context = LayoutContext(
///     pageSize: CGSize(width: 800, height: 600),
///     margins: EdgeInsets(all: 50),
///     staffHeight: 40
/// )
/// ```
///
/// ## Output Structure
///
/// The resulting ``EngravedScore`` contains a hierarchy of positioned elements:
///
/// ```
/// EngravedScore
/// ├── pages: [EngravedPage]
/// │   ├── pageNumber
/// │   ├── frame
/// │   ├── credits (title, composer)
/// │   └── systems: [EngravedSystem]
/// │       ├── frame
/// │       ├── measureRange
/// │       ├── staves: [EngravedStaff]
/// │       └── measures: [EngravedMeasure]
/// └── scaling: ScalingContext
/// ```
///
/// ## Thread Safety
///
/// `LayoutEngine` is not thread-safe. Create separate instances for concurrent
/// layout operations, or synchronize access externally.
public final class LayoutEngine {
    /// Engine for computing horizontal spacing between elements.
    private let horizontalSpacing: HorizontalSpacingEngine

    /// Engine for computing vertical staff positions.
    private let verticalSpacing: VerticalSpacingEngine

    /// Engine for computing page breaks.
    private let pageLayout: PageLayoutEngine

    /// Engine for computing system (line) breaks.
    private let systemSpacing: SystemSpacingEngine

    /// Configuration options that control layout behavior.
    ///
    /// Modify this property before calling ``layout(score:context:)`` to
    /// customize spacing, widths, and other layout parameters.
    public var config: LayoutConfiguration

    /// Creates a new layout engine with the specified configuration.
    ///
    /// - Parameter config: Configuration options for layout computation.
    ///   Defaults to standard engraving settings.
    public init(config: LayoutConfiguration = LayoutConfiguration()) {
        self.config = config
        self.horizontalSpacing = HorizontalSpacingEngine(config: config.spacingConfig)
        self.verticalSpacing = VerticalSpacingEngine(config: config.verticalConfig)
        self.pageLayout = PageLayoutEngine(config: config.verticalConfig)
        self.systemSpacing = SystemSpacingEngine(config: config.spacingConfig)
    }

    /// Computes the complete layout for a score.
    ///
    /// This method transforms the abstract `Score` model into a fully positioned
    /// `EngravedScore` ready for rendering. All element positions are computed
    /// based on the layout context and configuration.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let engine = LayoutEngine()
    /// let context = LayoutContext.letterSize(staffHeight: 40)
    ///
    /// let engraved = engine.layout(score: score, context: context)
    ///
    /// // Render the first page
    /// renderer.render(score: engraved, pageIndex: 0, in: cgContext)
    /// ```
    ///
    /// - Parameters:
    ///   - score: The score to compute layout for.
    ///   - context: Page size, margins, and display settings.
    ///
    /// - Returns: An ``EngravedScore`` with computed positions for all elements.
    ///   Pass this to a renderer to display the score.
    public func layout(score: Score, context: LayoutContext) -> EngravedScore {
        // Create scaling context
        let scaling = createScalingContext(from: score, context: context)

        // Compute part staff info
        let partInfos = score.parts.map { part in
            PartStaffInfo(staffCount: part.staffCount)
        }

        // Compute measure widths
        let measureWidths = computeMeasureWidths(score: score, scaling: scaling)

        // Compute system breaks
        let systemWidth = context.pageSize.width - context.margins.left - context.margins.right
        let systemBreaks = systemSpacing.computeSystemBreaks(
            measureWidths: measureWidths,
            systemWidth: systemWidth
        )

        // Compute staff positions per system
        let staffPositions = verticalSpacing.computeStaffPositions(
            parts: partInfos,
            staffHeight: context.staffHeight
        )

        // Compute system heights
        let baseSystemHeight = computeBaseSystemHeight(staffPositions: staffPositions)
        let systemHeights = systemBreaks.map { _ in
            baseSystemHeight + config.verticalConfig.systemTopPadding + config.verticalConfig.systemBottomPadding
        }

        // Compute page breaks
        let pageBreaks = pageLayout.computePageBreaks(
            systemHeights: systemHeights,
            pageHeight: context.pageSize.height,
            topMargin: context.margins.top,
            bottomMargin: context.margins.bottom,
            firstPageTopMargin: context.margins.top + config.firstPageTopOffset
        )

        // Build engraved pages
        var pages: [EngravedPage] = []

        for (pageIndex, pageBreak) in pageBreaks.enumerated() {
            let page = buildPage(
                pageIndex: pageIndex,
                pageBreak: pageBreak,
                systemBreaks: systemBreaks,
                systemHeights: systemHeights,
                staffPositions: staffPositions,
                measureWidths: measureWidths,
                score: score,
                context: context,
                scaling: scaling
            )
            pages.append(page)
        }

        return EngravedScore(score: score, pages: pages, scaling: scaling)
    }

    // MARK: - Private Helpers

    private func createScalingContext(from score: Score, context: LayoutContext) -> ScalingContext {
        if let scaling = score.defaults?.scaling {
            return ScalingContext(
                millimeters: scaling.millimeters,
                tenths: scaling.tenths,
                staffHeightPoints: context.staffHeight
            )
        }
        return ScalingContext(staffHeightPoints: context.staffHeight)
    }

    private func computeMeasureWidths(score: Score, scaling: ScalingContext) -> [CGFloat] {
        guard let firstPart = score.parts.first else { return [] }

        return firstPart.measures.enumerated().map { index, measure in
            let elements = extractSpacingElements(from: measure)
            let divisions = measure.attributes?.divisions ?? 1
            let measureDuration = computeMeasureDuration(measure: measure, divisions: divisions)

            let result = horizontalSpacing.computeSpacing(
                elements: elements,
                divisions: divisions,
                measureDuration: measureDuration
            )

            // Add extra width for first measure (clef, key, time)
            let isFirstMeasure = index == 0
            var width = result.totalWidth

            if isFirstMeasure {
                width += config.clefWidth + config.keySignatureWidth + config.timeSignatureWidth
            }

            return width
        }
    }

    private func extractSpacingElements(from measure: Measure) -> [SpacingElement] {
        var elements: [SpacingElement] = []
        var currentPosition = 0

        for element in measure.elements {
            switch element {
            case .note(let note):
                elements.append(SpacingElement(
                    position: currentPosition,
                    voice: note.voice,
                    staff: note.staff,
                    type: note.isRest ? .rest : .note,
                    hasAccidental: note.accidental != nil,
                    dotCount: note.dots
                ))
                if !note.isChordTone {
                    currentPosition += note.durationDivisions
                }

            case .forward(let forward):
                currentPosition += forward.duration

            case .backup(let backup):
                currentPosition -= backup.duration

            case .attributes:
                // Attributes don't add spacing elements directly
                break

            case .direction, .barline, .print, .harmony, .sound:
                break
            }
        }

        return elements
    }

    private func computeMeasureDuration(measure: Measure, divisions: Int) -> Int {
        guard let timeSignature = measure.attributes?.timeSignatures.first,
              let beats = Int(timeSignature.beats),
              let beatType = Int(timeSignature.beatType) else {
            return divisions * 4  // Default to 4/4
        }
        return (beats * divisions * 4) / beatType
    }

    private func computeBaseSystemHeight(staffPositions: [StaffPositionInfo]) -> CGFloat {
        guard !staffPositions.isEmpty else { return 0 }
        let first = staffPositions.first!
        let last = staffPositions.last!
        return last.bottomY - first.topY
    }

    private func buildPage(
        pageIndex: Int,
        pageBreak: PageBreak,
        systemBreaks: [SystemBreak],
        systemHeights: [CGFloat],
        staffPositions: [StaffPositionInfo],
        measureWidths: [CGFloat],
        score: Score,
        context: LayoutContext,
        scaling: ScalingContext
    ) -> EngravedPage {
        let pageFrame = CGRect(origin: .zero, size: context.pageSize)

        // Get systems for this page
        let systemRange = pageBreak.startSystem...pageBreak.endSystem
        var systemY = context.margins.top
        if pageIndex == 0 {
            systemY += config.firstPageTopOffset
        }

        var systems: [EngravedSystem] = []

        for systemIndex in systemRange {
            let systemBreak = systemBreaks[systemIndex]
            let systemHeight = systemHeights[systemIndex]
            let systemWidth = context.pageSize.width - context.margins.left - context.margins.right

            let system = buildSystem(
                systemIndex: systemIndex,
                systemBreak: systemBreak,
                staffPositions: staffPositions,
                measureWidths: measureWidths,
                score: score,
                systemFrame: CGRect(
                    x: context.margins.left,
                    y: systemY,
                    width: systemWidth,
                    height: systemHeight
                ),
                scaling: scaling
            )

            systems.append(system)
            systemY += systemHeight + config.verticalConfig.systemDistance
        }

        // Build credits for first page
        var credits: [EngravedCredit] = []
        if pageIndex == 0 {
            credits = buildCredits(score: score, pageFrame: pageFrame, context: context)
        }

        return EngravedPage(
            pageNumber: pageIndex + 1,
            frame: pageFrame,
            systems: systems,
            credits: credits
        )
    }

    private func buildSystem(
        systemIndex: Int,
        systemBreak: SystemBreak,
        staffPositions: [StaffPositionInfo],
        measureWidths: [CGFloat],
        score: Score,
        systemFrame: CGRect,
        scaling: ScalingContext
    ) -> EngravedSystem {
        var staves: [EngravedStaff] = []

        for position in staffPositions {
            let staff = EngravedStaff(
                partIndex: position.partIndex,
                staffNumber: position.staffNumber,
                frame: CGRect(
                    x: 0,
                    y: position.topY,
                    width: systemFrame.width,
                    height: position.height
                ),
                centerLineY: position.centerLineY,
                lineCount: 5,
                staffHeight: position.height
            )
            staves.append(staff)
        }

        // Build measures
        var measures: [EngravedMeasure] = []
        var measureX: CGFloat = 0

        for measureIndex in systemBreak.startMeasure...systemBreak.endMeasure {
            let width = measureWidths[measureIndex]
            let measure = EngravedMeasure(
                measureNumber: measureIndex + 1,
                frame: CGRect(x: measureX, y: 0, width: width, height: systemFrame.height),
                leftBarlineX: measureX,
                rightBarlineX: measureX + width
            )
            measures.append(measure)
            measureX += width
        }

        return EngravedSystem(
            frame: systemFrame,
            staves: staves,
            measures: measures,
            measureRange: (systemBreak.startMeasure + 1)...(systemBreak.endMeasure + 1)
        )
    }

    private func buildCredits(
        score: Score,
        pageFrame: CGRect,
        context: LayoutContext
    ) -> [EngravedCredit] {
        var credits: [EngravedCredit] = []

        // Add title from metadata
        if let title = score.metadata.workTitle ?? score.metadata.movementTitle {
            let titleCredit = EngravedCredit(
                text: title,
                position: CGPoint(x: pageFrame.midX, y: context.margins.top / 2),
                fontSize: 24,
                justification: .center
            )
            credits.append(titleCredit)
        }

        // Add composer
        let composer = score.metadata.creators.first { $0.type == "composer" }
        if let composerName = composer?.name {
            let composerCredit = EngravedCredit(
                text: composerName,
                position: CGPoint(
                    x: pageFrame.width - context.margins.right,
                    y: context.margins.top * 0.75
                ),
                fontSize: 14,
                justification: .right
            )
            credits.append(composerCredit)
        }

        return credits
    }
}

// MARK: - Layout Configuration

/// Configuration options that control layout engine behavior.
///
/// Use `LayoutConfiguration` to customize how the layout engine computes
/// spacing, positions, and page layout.
///
/// ## Example
///
/// ```swift
/// var config = LayoutConfiguration()
///
/// // Increase space for title on first page
/// config.firstPageTopOffset = 100
///
/// // Adjust clef width for wider glyphs
/// config.clefWidth = 28
///
/// // Use custom spacing settings
/// config.spacingConfig.minimumNoteSpace = 12
///
/// let engine = LayoutEngine(config: config)
/// ```
public struct LayoutConfiguration: Sendable {
    /// Configuration for horizontal spacing between notes and other elements.
    ///
    /// Controls minimum spacing, duration-based spacing, and collision avoidance.
    public var spacingConfig: SpacingConfiguration

    /// Configuration for vertical spacing between staves and systems.
    ///
    /// Controls staff distance, system distance, and padding.
    public var verticalConfig: VerticalSpacingConfiguration

    /// Extra vertical offset from the top margin on the first page.
    ///
    /// This provides space for the title, composer, and other header content.
    /// On subsequent pages, content starts at the top margin.
    ///
    /// Default: 60 points
    public var firstPageTopOffset: CGFloat

    /// Width allocated for clef symbols at the start of each system.
    ///
    /// This should accommodate the widest clef used (typically F clef).
    ///
    /// Default: 20 points
    public var clefWidth: CGFloat

    /// Width allocated for key signatures at the start of each system.
    ///
    /// This should accommodate the maximum number of accidentals you expect.
    /// Seven sharps or flats requires more space than one.
    ///
    /// Default: 30 points
    public var keySignatureWidth: CGFloat

    /// Width allocated for time signatures at the start of measures.
    ///
    /// This should accommodate common and uncommon time signatures.
    ///
    /// Default: 20 points
    public var timeSignatureWidth: CGFloat

    /// Creates a layout configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - spacingConfig: Horizontal spacing settings. Defaults to standard values.
    ///   - verticalConfig: Vertical spacing settings. Defaults to standard values.
    ///   - firstPageTopOffset: Extra space at top of first page. Default: 60 points.
    ///   - clefWidth: Width for clef symbols. Default: 20 points.
    ///   - keySignatureWidth: Width for key signatures. Default: 30 points.
    ///   - timeSignatureWidth: Width for time signatures. Default: 20 points.
    public init(
        spacingConfig: SpacingConfiguration = SpacingConfiguration(),
        verticalConfig: VerticalSpacingConfiguration = VerticalSpacingConfiguration(),
        firstPageTopOffset: CGFloat = 60,
        clefWidth: CGFloat = 20,
        keySignatureWidth: CGFloat = 30,
        timeSignatureWidth: CGFloat = 20
    ) {
        self.spacingConfig = spacingConfig
        self.verticalConfig = verticalConfig
        self.firstPageTopOffset = firstPageTopOffset
        self.clefWidth = clefWidth
        self.keySignatureWidth = keySignatureWidth
        self.timeSignatureWidth = timeSignatureWidth
    }
}

// MARK: - Layout Context

/// Page size, margins, and display settings for layout computation.
///
/// `LayoutContext` defines the physical or virtual page where music will be
/// rendered. The layout engine uses these settings to compute system breaks,
/// page breaks, and element positions.
///
/// ## Preset Page Sizes
///
/// Use the factory methods for common paper sizes:
///
/// ```swift
/// // US Letter (8.5" x 11")
/// let letter = LayoutContext.letterSize(staffHeight: 40)
///
/// // A4 (210mm x 297mm)
/// let a4 = LayoutContext.a4Size(staffHeight: 40)
/// ```
///
/// ## Custom Configuration
///
/// Create custom contexts for non-standard sizes:
///
/// ```swift
/// let custom = LayoutContext(
///     pageSize: CGSize(width: 800, height: 1200),
///     margins: EdgeInsets(top: 50, left: 60, bottom: 50, right: 60),
///     staffHeight: 35,
///     fontName: "Bravura"
/// )
/// ```
///
/// ## Coordinate System
///
/// All dimensions are in points (1/72 inch). The origin (0, 0) is at the
/// top-left corner of the page.
public struct LayoutContext: Sendable {
    /// The page size in points.
    ///
    /// Standard sizes at 72 DPI:
    /// - US Letter: 612 x 792 points (8.5" x 11")
    /// - A4: 595 x 842 points (210mm x 297mm)
    public var pageSize: CGSize

    /// Margins around the page content.
    ///
    /// Music content is laid out within the area defined by these margins.
    /// Credits and page numbers may appear in the margin areas.
    public var margins: EdgeInsets

    /// The height of a standard 5-line staff in points.
    ///
    /// This is the distance from the bottom line to the top line of a staff.
    /// Larger values produce larger notation. Common values:
    /// - 35-40 points: Standard sheet music
    /// - 25-30 points: Smaller, denser scores
    /// - 45-50 points: Large print or educational music
    public var staffHeight: CGFloat

    /// The name of the SMuFL font to use for music symbols.
    ///
    /// The font must be loaded via `SMuFLFontManager` before rendering.
    /// Default: "Bravura"
    public var fontName: String

    /// Creates a layout context with custom settings.
    ///
    /// - Parameters:
    ///   - pageSize: The page dimensions in points.
    ///   - margins: The page margins.
    ///   - staffHeight: The staff height in points.
    ///   - fontName: The SMuFL font name. Default: "Bravura"
    public init(
        pageSize: CGSize,
        margins: EdgeInsets,
        staffHeight: CGFloat,
        fontName: String = "Bravura"
    ) {
        self.pageSize = pageSize
        self.margins = margins
        self.staffHeight = staffHeight
        self.fontName = fontName
    }

    /// Creates a context for US Letter size paper (8.5" x 11").
    ///
    /// Uses 1-inch margins on all sides.
    ///
    /// - Parameter staffHeight: The staff height in points. Default: 40
    /// - Returns: A layout context configured for US Letter paper.
    public static func letterSize(staffHeight: CGFloat = 40) -> LayoutContext {
        LayoutContext(
            pageSize: CGSize(width: 612, height: 792),  // 8.5" x 11" at 72 dpi
            margins: EdgeInsets(top: 72, left: 72, bottom: 72, right: 72),
            staffHeight: staffHeight
        )
    }

    /// Creates a context for A4 size paper (210mm x 297mm).
    ///
    /// Uses 1-inch (approximately 25mm) margins on all sides.
    ///
    /// - Parameter staffHeight: The staff height in points. Default: 40
    /// - Returns: A layout context configured for A4 paper.
    public static func a4Size(staffHeight: CGFloat = 40) -> LayoutContext {
        LayoutContext(
            pageSize: CGSize(width: 595, height: 842),  // A4 at 72 dpi
            margins: EdgeInsets(top: 72, left: 72, bottom: 72, right: 72),
            staffHeight: staffHeight
        )
    }
}

// MARK: - Edge Insets

/// Edge insets for margins.
public struct EdgeInsets: Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    /// Uniform insets.
    public init(all: CGFloat) {
        self.top = all
        self.left = all
        self.bottom = all
        self.right = all
    }

    public static let zero = EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

// MARK: - Legacy Compatibility

/// Computed layout for a score (legacy type for compatibility).
public typealias ScoreLayout = EngravedScore
