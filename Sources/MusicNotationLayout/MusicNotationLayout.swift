// MusicNotationLayout Module
// Layout engine for computing music notation positions

import Foundation
import CoreGraphics
import MusicNotationCore
import SMuFLKit

// MARK: - Layout Engine Protocol

/// Protocol for layout engines, enabling dependency injection and testing.
///
/// Conform to this protocol to create custom layout engines or mock
/// implementations for testing.
public protocol LayoutEngineProtocol {
    /// Configuration options that control layout behavior.
    var config: LayoutConfiguration { get set }

    /// Computes the complete layout for a score.
    ///
    /// - Parameters:
    ///   - score: The score to compute layout for.
    ///   - context: Page size, margins, and display settings.
    /// - Returns: An ``EngravedScore`` with computed positions for all elements.
    func layout(score: Score, context: LayoutContext) -> EngravedScore
}

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
public final class LayoutEngine: LayoutEngineProtocol {
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

        // Compute inherited divisions (MusicXML convention: divisions carry forward)
        let inheritedDivisions = computeInheritedDivisions(from: score)

        // Compute measure widths
        let measureWidths = computeMeasureWidths(score: score, scaling: scaling, inheritedDivisions: inheritedDivisions)

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
                inheritedDivisions: inheritedDivisions,
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

    /// Computes inherited divisions for each measure (MusicXML convention: divisions carry forward).
    private func computeInheritedDivisions(from score: Score) -> [Int] {
        guard let firstPart = score.parts.first else { return [] }
        var lastDiv = 1
        return firstPart.measures.map { measure in
            if let div = measure.attributes?.divisions {
                lastDiv = div
            }
            return lastDiv
        }
    }

    private func computeMeasureWidths(score: Score, scaling: ScalingContext, inheritedDivisions: [Int]) -> [CGFloat] {
        guard let firstPart = score.parts.first else { return [] }

        return firstPart.measures.enumerated().map { index, measure in
            let elements = extractSpacingElements(from: measure)
            let divisions = inheritedDivisions[index]
            let measureDuration = computeMeasureDuration(measure: measure, divisions: divisions)

            let result = horizontalSpacing.computeSpacing(
                elements: elements,
                divisions: divisions,
                measureDuration: measureDuration
            )

            // Add extra width for first measure (clef, key, time)
            let isFirstMeasure = index == 0
            var width = result.totalWidth
            var prefixWidth: CGFloat = 0

            if isFirstMeasure {
                prefixWidth = config.clefWidth + config.keySignatureWidth + config.timeSignatureWidth
                width += prefixWidth
            }

            width = max(width, config.spacingConfig.minimumMeasureWidth + prefixWidth)
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
        guard let first = staffPositions.first,
              let last = staffPositions.last else {
            return 0
        }
        return last.bottomY - first.topY
    }

    private func buildPage(
        pageIndex: Int,
        pageBreak: PageBreak,
        systemBreaks: [SystemBreak],
        systemHeights: [CGFloat],
        staffPositions: [StaffPositionInfo],
        measureWidths: [CGFloat],
        inheritedDivisions: [Int],
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
                inheritedDivisions: inheritedDivisions,
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
        inheritedDivisions: [Int],
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

        // Compute the staff extent height (just the staves, no system padding)
        // This is used for barline height — barlines should span only the staff area.
        let staffExtentHeight: CGFloat
        if let first = staves.first, let last = staves.last {
            staffExtentHeight = last.frame.maxY - first.frame.minY
        } else {
            staffExtentHeight = systemFrame.height
        }

        // Build measures with engraved elements
        // Justify measure widths to fill the system width.
        // The first measure's prefix (clef + key sig + time sig) is fixed overhead —
        // only scale the content portions so all measures get equal content space.
        let measureRange = systemBreak.startMeasure...systemBreak.endMeasure
        let totalPrefixWidth: CGFloat = (measureRange.contains(0) && systemIndex == 0)
            ? config.clefWidth + config.keySignatureWidth + config.timeSignatureWidth
            : 0
        let naturalTotal = measureRange.reduce(CGFloat(0)) { $0 + measureWidths[$1] }
        let contentTotal = naturalTotal - totalPrefixWidth
        let availableForContent = systemFrame.width - totalPrefixWidth
        let justificationRatio = contentTotal > 0 ? availableForContent / contentTotal : 1.0

        var measures: [EngravedMeasure] = []
        var measureX: CGFloat = 0

        for measureIndex in measureRange {
            let measurePrefix: CGFloat = (measureIndex == 0 && systemIndex == 0)
                ? config.clefWidth + config.keySignatureWidth + config.timeSignatureWidth
                : 0
            let contentWidth = measureWidths[measureIndex] - measurePrefix
            let justifiedWidth = contentWidth * justificationRatio + measurePrefix
            let isFirstInScore = (measureIndex == 0 && systemIndex == 0)
            let isFirstInSystem = (measureIndex == systemBreak.startMeasure)
            let divisions = inheritedDivisions[measureIndex]

            var elementsByStaff: [Int: [EngravedElement]] = [:]
            var beamGroups: [EngravedBeamGroup] = []

            if let firstPart = score.parts.first,
               measureIndex < firstPart.measures.count {
                let sourceMeasure = firstPart.measures[measureIndex]
                let result = engraveElements(
                    in: sourceMeasure,
                    measureIndex: measureIndex,
                    divisions: divisions,
                    isFirstInSystem: isFirstInSystem,
                    isFirstInScore: isFirstInScore,
                    staves: staves,
                    scaling: scaling,
                    targetWidth: justifiedWidth
                )
                elementsByStaff = result.0
                beamGroups = result.1
            }

            let measure = EngravedMeasure(
                measureNumber: measureIndex + 1,
                frame: CGRect(x: measureX, y: 0, width: justifiedWidth, height: staffExtentHeight),
                leftBarlineX: measureX,
                rightBarlineX: measureX + justifiedWidth,
                elementsByStaff: elementsByStaff,
                beamGroups: beamGroups
            )
            measures.append(measure)
            measureX += justifiedWidth
        }

        // Opening barline at the left edge of the system
        var systemBarlines: [EngravedSystemBarline] = []
        if let firstStaff = staves.first, let lastStaff = staves.last {
            systemBarlines.append(EngravedSystemBarline(
                x: 0,
                topY: firstStaff.frame.minY,
                bottomY: lastStaff.frame.maxY,
                style: .regular
            ))
        }

        return EngravedSystem(
            frame: systemFrame,
            staves: staves,
            measures: measures,
            systemBarlines: systemBarlines,
            measureRange: (systemBreak.startMeasure + 1)...(systemBreak.endMeasure + 1)
        )
    }

    // MARK: - Element Engraving

    // MARK: - Beam Tracker

    /// Tracks active beam groups as notes are processed sequentially.
    private struct BeamTracker {
        struct PendingGroup {
            var elementIndices: [Int]  // indices into the `elements` array
            var stemDirection: StemDirection
        }
        var active: [Int: PendingGroup] = [:]   // keyed by voice
        var completed: [PendingGroup] = []
        /// Indices of beamable notes that had no explicit beam data (candidates for auto-grouping).
        var unbeamedIndices: [(elementIndex: Int, stemDirection: StemDirection, position: Int)] = []

        mutating func processNote(note: Note, elementIndex: Int, stemDirection: StemDirection, position: Int) {
            guard !note.isChordTone else { return }

            let isBeamable = note.type == .eighth || note.type == .sixteenth || note.type == .thirtySecond

            if !note.beams.isEmpty {
                guard let primary = note.beams.first(where: { $0.number == 1 }) else { return }
                switch primary.value {
                case .begin:
                    active[note.voice] = PendingGroup(elementIndices: [elementIndex], stemDirection: stemDirection)
                case .continue:
                    active[note.voice]?.elementIndices.append(elementIndex)
                case .end:
                    active[note.voice]?.elementIndices.append(elementIndex)
                    if let group = active.removeValue(forKey: note.voice) { completed.append(group) }
                case .forwardHook, .backwardHook:
                    break  // Future: secondary beam hooks
                }
            } else if isBeamable {
                // No explicit beam data — track for auto-grouping
                unbeamedIndices.append((elementIndex: elementIndex, stemDirection: stemDirection, position: position))
            }
        }

        /// Auto-groups unbeamed beamable notes by beat grouping.
        /// Groups consecutive notes that fall within the same beat group (2 beats in 4/4).
        mutating func autoGroupUnbeamed(divisions: Int, beatsPerGroup: Int = 2) {
            guard !unbeamedIndices.isEmpty else { return }

            let divisionsPerGroup = divisions * beatsPerGroup
            var currentGroup: PendingGroup?
            var currentGroupBucket = -1

            for entry in unbeamedIndices {
                let bucket = entry.position / divisionsPerGroup
                if bucket == currentGroupBucket {
                    currentGroup?.elementIndices.append(entry.elementIndex)
                } else {
                    // Close previous group if it has 2+ notes
                    if let group = currentGroup, group.elementIndices.count >= 2 {
                        completed.append(group)
                    }
                    currentGroup = PendingGroup(elementIndices: [entry.elementIndex], stemDirection: entry.stemDirection)
                    currentGroupBucket = bucket
                }
            }

            // Close final group
            if let group = currentGroup, group.elementIndices.count >= 2 {
                completed.append(group)
            }
        }
    }

    private func engraveElements(
        in sourceMeasure: Measure,
        measureIndex: Int,
        divisions: Int,
        isFirstInSystem: Bool,
        isFirstInScore: Bool,
        staves: [EngravedStaff],
        scaling: ScalingContext,
        targetWidth: CGFloat? = nil
    ) -> ([Int: [EngravedElement]], [EngravedBeamGroup]) {
        var elementsByStaff: [Int: [EngravedElement]] = [:]
        var beamGroups: [EngravedBeamGroup] = []

        let measureDuration = computeMeasureDuration(measure: sourceMeasure, divisions: divisions)

        // Recompute spacing to get x-position of each rhythmic column
        let spacingElements = extractSpacingElements(from: sourceMeasure)
        var spacingResult = horizontalSpacing.computeSpacing(
            elements: spacingElements,
            divisions: divisions,
            measureDuration: measureDuration
        )

        // First measure has extra prefix space for clef + key sig + time sig
        let prefixWidth: CGFloat = measureIndex == 0
            ? config.clefWidth + config.keySignatureWidth + config.timeSignatureWidth
            : 0

        // Justify spacing to fill target width if provided
        if let targetWidth = targetWidth {
            let contentTargetWidth = targetWidth - prefixWidth
            if contentTargetWidth > spacingResult.totalWidth {
                spacingResult = horizontalSpacing.justify(result: spacingResult, targetWidth: contentTargetWidth)
            }
        }

        // Get clefs from attributes
        let clefs = sourceMeasure.attributes?.clefs ?? []

        // Detect multi-voice context: check if there are notes in more than one voice
        let voicesPresent = Set(sourceMeasure.elements.compactMap { elem -> Int? in
            if case .note(let note) = elem, !note.isRest { return note.voice }
            return nil
        })
        let isMultiVoice = voicesPresent.count > 1

        for staff in staves {
            var elements: [EngravedElement] = []
            var beamTracker = BeamTracker()
            let staffNum = staff.staffNumber
            let halfSpace = staff.staffHeight / 8.0
            let staffSpace = halfSpace * 2.0  // Distance between two staff lines

            // Determine active clef for this staff
            let clef = clefs.first(where: {
                $0.staffNumber == staffNum || ($0.staffNumber == nil && staffNum == 1)
            })

            // --- Clef ---
            if isFirstInSystem, let clef = clef {
                let clefStaffPos = (clef.line - 3) * 2
                let clefY = staff.centerLineY - CGFloat(clefStaffPos) * halfSpace
                let clefX = (config.clefWidth + config.keySignatureWidth) / 2
                let engravedClef = EngravedClef(
                    clef: clef,
                    position: CGPoint(x: clefX, y: clefY),
                    glyph: glyphName(for: clef),
                    boundingBox: CGRect(x: 0, y: staff.frame.origin.y,
                                        width: config.clefWidth, height: staff.staffHeight)
                )
                elements.append(.clef(engravedClef))
            }

            // --- Time Signature ---
            if isFirstInScore,
               let timeSig = sourceMeasure.attributes?.timeSignatures.first {
                let tsElements = engraveTimeSignature(
                    timeSig, staff: staff, halfSpace: halfSpace,
                    xOffset: config.clefWidth + config.keySignatureWidth
                )
                elements.append(contentsOf: tsElements)
            }

            // --- Notes and Rests ---
            var currentPosition = 0
            var lastOnsetPosition = 0  // Tracks onset position for chord tones
            for elem in sourceMeasure.elements {
                switch elem {
                case .note(let note):
                    // Filter by staff
                    let matchesStaff = note.staff == staffNum
                        || (staves.count == 1 && note.staff <= 1)
                    guard matchesStaff else {
                        if !note.isChordTone { currentPosition += note.durationDivisions }
                        continue
                    }

                    // Chord tones share the onset position of the stem-owning note
                    let onsetPosition = note.isChordTone ? lastOnsetPosition : currentPosition
                    let noteX = spacingResult.interpolatedX(for: onsetPosition) + prefixWidth

                    if note.isRest {
                        // In multi-voice context, suppress rests for non-primary voices
                        if isMultiVoice && note.voice > 1 {
                            if !note.isChordTone {
                                currentPosition += note.durationDivisions
                            }
                            continue
                        }

                        let restY = staff.centerLineY
                        let glyph = restGlyph(for: note.type)
                        elements.append(.rest(EngravedRest(
                            position: CGPoint(x: noteX, y: restY),
                            glyph: glyph,
                            boundingBox: CGRect(x: noteX - 6, y: restY - 10, width: 12, height: 20)
                        )))
                    } else {
                        let staffPos = staffPositionForNote(note, clef: clef)
                        let noteY = staff.centerLineY - CGFloat(staffPos) * halfSpace
                        let noteheadGlyph = self.noteheadGlyph(for: note)

                        // Chord tones only get a notehead — the stem-owning note owns the stem
                        var stem: EngravedStem? = nil
                        var flagGlyph: SMuFLGlyphName? = nil
                        let needsStem = !note.isChordTone
                            && note.type != .whole && note.type != .breve && note.type != nil

                        if needsStem {
                            let stemDir = note.stemDirection ?? (staffPos >= 0 ? .down : .up)

                            // Stem X: right edge of notehead for up stems, left edge for down stems
                            // Notehead width ≈ 1.18 staff spaces (SMuFL noteheadBlack convention)
                            let noteheadWidth = 1.18 * staffSpace
                            let stemX = stemDir == .up ? noteX + noteheadWidth : noteX

                            // Stem length: 3.5 staff spaces default, but ensure stem reaches center line
                            let defaultStemLength = 3.5 * staffSpace
                            var stemEndY: CGFloat
                            if stemDir == .up {
                                stemEndY = noteY - defaultStemLength
                                // For notes below center, ensure stem reaches center
                                if noteY > staff.centerLineY {
                                    stemEndY = min(stemEndY, staff.centerLineY)
                                }
                            } else {
                                stemEndY = noteY + defaultStemLength
                                // For notes above center, ensure stem reaches center
                                if noteY < staff.centerLineY {
                                    stemEndY = max(stemEndY, staff.centerLineY)
                                }
                            }

                            stem = EngravedStem(
                                start: CGPoint(x: stemX, y: noteY),
                                end: CGPoint(x: stemX, y: stemEndY),
                                direction: stemDir,
                                thickness: 0.8
                            )

                            // Flag (only for unbeamed notes; beamed notes get beam lines)
                            if note.beams.isEmpty {
                                flagGlyph = self.flagGlyph(for: note.type, stemDirection: stemDir)
                            }
                        }

                        elements.append(.note(EngravedNote(
                            noteId: note.id,
                            position: CGPoint(x: noteX, y: noteY),
                            staffPosition: staffPos,
                            noteheadGlyph: noteheadGlyph,
                            stem: stem,
                            flagGlyph: flagGlyph,
                            boundingBox: CGRect(x: noteX - 6, y: noteY - 15, width: 12, height: 30)
                        )))

                        // Track beamed notes (only stem-owning notes participate)
                        if needsStem {
                            beamTracker.processNote(
                                note: note,
                                elementIndex: elements.count - 1,
                                stemDirection: stem?.direction ?? .up,
                                position: onsetPosition
                            )
                        }
                    }

                    if !note.isChordTone {
                        lastOnsetPosition = currentPosition
                        currentPosition += note.durationDivisions
                    }

                case .backup(let backup):
                    currentPosition -= backup.duration
                case .forward(let forward):
                    currentPosition += forward.duration
                default:
                    break
                }
            }

            // Auto-group unbeamed eighth notes by beat grouping (2 beats per group in 4/4)
            beamTracker.autoGroupUnbeamed(divisions: divisions)

            // --- Compute beam geometry for completed beam groups ---
            let beamThickness = 0.5 * staffSpace  // Standard beam thickness
            let maxSlope: CGFloat = 0.5

            for group in beamTracker.completed {
                // Collect stem end points from engraved notes
                var stemEnds: [CGPoint] = []
                for idx in group.elementIndices {
                    guard idx < elements.count,
                          case .note(let engravedNote) = elements[idx],
                          let stem = engravedNote.stem else { continue }
                    stemEnds.append(stem.end)
                }

                guard let beamLine = calculateBeamEndpoints(
                    stemEnds: stemEnds,
                    stemDirection: group.stemDirection,
                    maxSlope: maxSlope
                ) else { continue }

                // Adjust each note's stem end to meet the beam line and clear flags
                for idx in group.elementIndices {
                    guard idx < elements.count,
                          case .note(var engravedNote) = elements[idx],
                          var stem = engravedNote.stem else { continue }

                    let beamYAtStem = beamLine.start.y + beamLine.slope * (stem.end.x - beamLine.start.x)
                    stem.end.y = beamYAtStem
                    engravedNote.stem = stem
                    engravedNote.flagGlyph = nil  // Beamed notes don't get flags
                    elements[idx] = .note(engravedNote)
                }

                beamGroups.append(EngravedBeamGroup(
                    startPoint: beamLine.start,
                    endPoint: beamLine.end,
                    thickness: beamThickness,
                    slope: beamLine.slope,
                    stemDirection: group.stemDirection,
                    staffNumber: staffNum
                ))
            }

            if !elements.isEmpty {
                elementsByStaff[staffNum] = elements
            }
        }

        return (elementsByStaff, beamGroups)
    }

    // MARK: - Beam Geometry

    /// Calculates beam endpoints for a group of notes, clamping slope and shifting
    /// the beam so all stems can reach it.
    private func calculateBeamEndpoints(
        stemEnds: [CGPoint],
        stemDirection: StemDirection,
        maxSlope: CGFloat
    ) -> (start: CGPoint, end: CGPoint, slope: CGFloat)? {
        guard let firstStemEnd = stemEnds.first,
              let lastStemEnd = stemEnds.last,
              stemEnds.count >= 2 else {
            return nil
        }

        let dx = lastStemEnd.x - firstStemEnd.x
        guard dx != 0 else {
            return (firstStemEnd, lastStemEnd, 0)
        }

        let dy = lastStemEnd.y - firstStemEnd.y
        var slope = dy / dx
        slope = max(-maxSlope, min(maxSlope, slope))

        let adjustedEndY = firstStemEnd.y + slope * dx

        var beamStartY = firstStemEnd.y
        var beamEndY = adjustedEndY

        // Shift beam so all stems can reach it
        for stemEnd in stemEnds {
            let beamYAtStem = firstStemEnd.y + slope * (stemEnd.x - firstStemEnd.x)
            if stemDirection == .up {
                if stemEnd.y < beamYAtStem {
                    let adjustment = beamYAtStem - stemEnd.y
                    beamStartY -= adjustment
                    beamEndY -= adjustment
                }
            } else {
                if stemEnd.y > beamYAtStem {
                    let adjustment = stemEnd.y - beamYAtStem
                    beamStartY += adjustment
                    beamEndY += adjustment
                }
            }
        }

        return (
            CGPoint(x: firstStemEnd.x, y: beamStartY),
            CGPoint(x: lastStemEnd.x, y: beamEndY),
            slope
        )
    }

    // MARK: - Glyph Name Mapping

    private func glyphName(for clef: Clef) -> SMuFLGlyphName {
        switch clef.sign {
        case .g: return .gClef
        case .f: return .fClef
        case .c: return .cClef
        case .percussion: return .unpitchedPercussionClef1
        case .tab, .none: return .gClef
        }
    }

    private func noteheadGlyph(for note: Note) -> SMuFLGlyphName {
        let isXNotehead = note.notehead?.type == .x || note.notehead?.type == .cross

        switch note.type {
        case .whole:
            return isXNotehead ? .noteheadXWhole : .noteheadWhole
        case .half:
            return isXNotehead ? .noteheadXHalf : .noteheadHalf
        default:
            // Quarter and shorter are filled
            return isXNotehead ? .noteheadXBlack : .noteheadBlack
        }
    }

    private func restGlyph(for durationType: DurationBase?) -> SMuFLGlyphName {
        switch durationType {
        case .whole: return .restWhole
        case .half: return .restHalf
        case .quarter: return .restQuarter
        case .eighth: return .rest8th
        case .sixteenth: return .rest16th
        default: return .restQuarter
        }
    }

    private func flagGlyph(for durationType: DurationBase?, stemDirection: StemDirection) -> SMuFLGlyphName? {
        let isUp = stemDirection == .up
        switch durationType {
        case .eighth: return isUp ? .flag8thUp : .flag8thDown
        case .sixteenth: return isUp ? .flag16thUp : .flag16thDown
        default: return nil
        }
    }

    private func timeSigDigitGlyph(for digit: Character) -> SMuFLGlyphName? {
        switch digit {
        case "0": return .timeSig0
        case "1": return .timeSig1
        case "2": return .timeSig2
        case "3": return .timeSig3
        case "4": return .timeSig4
        case "5": return .timeSig5
        case "6": return .timeSig6
        case "7": return .timeSig7
        case "8": return .timeSig8
        case "9": return .timeSig9
        default: return nil
        }
    }

    // MARK: - Staff Position Calculation

    private func staffPositionForNote(_ note: Note, clef: Clef?) -> Int {
        switch note.noteType {
        case .pitched(let pitch):
            return staffPosition(step: pitch.step, octave: pitch.octave, clef: clef)
        case .unpitched(let unpitched):
            // Use treble-like mapping for percussion display positions
            return staffPosition(step: unpitched.displayStep, octave: unpitched.displayOctave, clef: nil)
        case .rest:
            return 0
        }
    }

    private func staffPosition(step: PitchStep, octave: Int, clef: Clef?) -> Int {
        // Reference: which note sits on which staff line for this clef
        let refStep: PitchStep
        let refOctave: Int
        let refStaffPos: Int

        if let clef = clef {
            let clefStaffPos = (clef.line - 3) * 2
            switch clef.sign {
            case .g:
                refStep = .g; refOctave = 4 + (clef.clefOctaveChange ?? 0); refStaffPos = clefStaffPos
            case .f:
                refStep = .f; refOctave = 3 + (clef.clefOctaveChange ?? 0); refStaffPos = clefStaffPos
            case .c:
                refStep = .c; refOctave = 4 + (clef.clefOctaveChange ?? 0); refStaffPos = clefStaffPos
            case .percussion, .tab, .none:
                // Treble-like mapping
                refStep = .g; refOctave = 4; refStaffPos = -2
            }
        } else {
            // Default: treble clef mapping
            refStep = .g; refOctave = 4; refStaffPos = -2
        }

        let diatonicDist = (octave - refOctave) * 7 + step.diatonicPosition - refStep.diatonicPosition
        return diatonicDist + refStaffPos
    }

    // MARK: - Time Signature Engraving

    private func engraveTimeSignature(
        _ timeSig: TimeSignature,
        staff: EngravedStaff,
        halfSpace: CGFloat,
        xOffset: CGFloat
    ) -> [EngravedElement] {
        let tsX = xOffset + 8 // Center within time sig area

        // Check for common/cut time symbols
        if let symbol = timeSig.symbol {
            switch symbol {
            case .common:
                return [.timeSignature(EngravedTimeSignature(
                    timeSignature: timeSig,
                    position: CGPoint(x: tsX, y: staff.centerLineY),
                    symbolGlyph: .timeSigCommon,
                    boundingBox: CGRect(x: tsX - 6, y: staff.frame.origin.y, width: 12, height: staff.staffHeight)
                ))]
            case .cut:
                return [.timeSignature(EngravedTimeSignature(
                    timeSignature: timeSig,
                    position: CGPoint(x: tsX, y: staff.centerLineY),
                    symbolGlyph: .timeSigCutCommon,
                    boundingBox: CGRect(x: tsX - 6, y: staff.frame.origin.y, width: 12, height: staff.staffHeight)
                ))]
            default:
                break
            }
        }

        // Numeric time signature: top digits above center, bottom digits below center
        let topY = staff.centerLineY - 2 * halfSpace    // Between lines 3 and 5
        let bottomY = staff.centerLineY + 2 * halfSpace // Between lines 1 and 3

        var topGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)] = []
        var bottomGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)] = []

        // Engrave numerator digits
        let beatsStr = timeSig.beats
        let beatsWidth = CGFloat(beatsStr.count) * halfSpace * 2
        var digitX = tsX - beatsWidth / 2 + halfSpace
        for char in beatsStr {
            if let glyph = timeSigDigitGlyph(for: char) {
                topGlyphs.append((glyph: glyph, position: CGPoint(x: digitX, y: topY)))
                digitX += halfSpace * 2
            }
        }

        // Engrave denominator digits
        let beatTypeStr = timeSig.beatType
        let beatTypeWidth = CGFloat(beatTypeStr.count) * halfSpace * 2
        digitX = tsX - beatTypeWidth / 2 + halfSpace
        for char in beatTypeStr {
            if let glyph = timeSigDigitGlyph(for: char) {
                bottomGlyphs.append((glyph: glyph, position: CGPoint(x: digitX, y: bottomY)))
                digitX += halfSpace * 2
            }
        }

        return [.timeSignature(EngravedTimeSignature(
            timeSignature: timeSig,
            position: CGPoint(x: tsX, y: staff.centerLineY),
            topGlyphs: topGlyphs,
            bottomGlyphs: bottomGlyphs,
            boundingBox: CGRect(x: tsX - 8, y: staff.frame.origin.y,
                                width: 16, height: staff.staffHeight)
        ))]
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

// MARK: - Equatable Conformance

extension LayoutContext: Equatable {
    public static func == (lhs: LayoutContext, rhs: LayoutContext) -> Bool {
        lhs.pageSize == rhs.pageSize
            && lhs.margins == rhs.margins
            && lhs.staffHeight == rhs.staffHeight
            && lhs.fontName == rhs.fontName
    }
}

extension EdgeInsets: Equatable {
    public static func == (lhs: EdgeInsets, rhs: EdgeInsets) -> Bool {
        lhs.top == rhs.top
            && lhs.left == rhs.left
            && lhs.bottom == rhs.bottom
            && lhs.right == rhs.right
    }
}

// MARK: - Legacy Compatibility

/// Computed layout for a score (legacy type for compatibility).
public typealias ScoreLayout = EngravedScore
