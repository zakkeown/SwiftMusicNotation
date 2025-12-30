import Foundation

/// The root container for a musical work.
///
/// `Score` is the top-level object representing a complete piece of music. It contains
/// all parts (instruments/voices), metadata about the work, and layout defaults. A score
/// corresponds to the root `<score-partwise>` or `<score-timewise>` element in MusicXML.
///
/// ## Score Hierarchy
///
/// ```
/// Score
/// ├── metadata: ScoreMetadata (title, composer, etc.)
/// ├── defaults: ScoreDefaults (page size, scaling)
/// ├── credits: [Credit] (displayed text on pages)
/// └── parts: [Part]
///     └── measures: [Measure]
///         └── elements: [MeasureElement] (notes, rests, etc.)
/// ```
///
/// ## Creating a Score
///
/// Scores are typically created by importing MusicXML:
///
/// ```swift
/// let importer = MusicXMLImporter()
/// let score = try importer.importScore(from: musicXMLURL)
///
/// print(score.metadata.workTitle ?? "Untitled")
/// print("Parts: \(score.parts.count)")
/// print("Measures: \(score.measureCount)")
/// ```
///
/// You can also create scores programmatically:
///
/// ```swift
/// let score = Score(
///     metadata: ScoreMetadata(
///         workTitle: "My Composition",
///         creators: [Creator(type: "composer", name: "J. Doe")]
///     ),
///     parts: [pianopart, violinPart]
/// )
/// ```
///
/// ## Navigating the Score
///
/// Access parts by index or ID:
///
/// ```swift
/// // By index
/// let firstPart = score.parts[0]
///
/// // By ID (from MusicXML)
/// if let piano = score.part(withID: "P1") {
///     print(piano.name)
/// }
/// ```
///
/// ## Thread Safety
///
/// `Score` conforms to `Sendable` and can be safely passed between actors.
/// However, modifications should be coordinated to avoid data races.
///
/// - SeeAlso: ``Part`` for instrument/voice containers
/// - SeeAlso: ``Measure`` for bar containers
/// - SeeAlso: ``ScoreMetadata`` for work information
public final class Score: Identifiable, Sendable {
    /// Unique identifier for this score.
    public let id: UUID

    /// Metadata about the work (title, composer, etc.).
    public var metadata: ScoreMetadata

    /// The parts in this score (instruments/voices).
    public var parts: [Part]

    /// Score-wide layout and engraving defaults.
    public var defaults: ScoreDefaults?

    /// Credits displayed on the score (titles, copyright, etc.).
    public var credits: [Credit]

    /// Creates a new score.
    public init(
        id: UUID = UUID(),
        metadata: ScoreMetadata = ScoreMetadata(),
        parts: [Part] = [],
        defaults: ScoreDefaults? = nil,
        credits: [Credit] = []
    ) {
        self.id = id
        self.metadata = metadata
        self.parts = parts
        self.defaults = defaults
        self.credits = credits
    }

    /// The total number of measures across all parts (uses the first part's count).
    public var measureCount: Int {
        parts.first?.measures.count ?? 0
    }

    /// Returns the part with the specified ID.
    public func part(withID id: String) -> Part? {
        parts.first { $0.id == id }
    }
}

// MARK: - Score Metadata

/// Metadata about a musical work.
///
/// `ScoreMetadata` contains bibliographic information about a composition including
/// the work title, movement information, creators (composer, lyricist, arranger),
/// and encoding details.
///
/// ## Example
///
/// ```swift
/// let metadata = ScoreMetadata(
///     workTitle: "Symphony No. 5",
///     workNumber: "Op. 67",
///     movementTitle: "Allegro con brio",
///     movementNumber: "I",
///     creators: [
///         Creator(type: "composer", name: "Ludwig van Beethoven")
///     ],
///     rights: ["Public Domain"]
/// )
/// ```
///
/// ## MusicXML Correspondence
///
/// This maps to the `<work>`, `<identification>`, and `<movement-title>` elements
/// in MusicXML.
public struct ScoreMetadata: Codable, Sendable {
    /// The work title (e.g., "Symphony No. 5").
    public var workTitle: String?

    /// The work number (e.g., "Op. 67").
    public var workNumber: String?

    /// The movement title (e.g., "Allegro con brio").
    public var movementTitle: String?

    /// The movement number (e.g., "I").
    public var movementNumber: String?

    /// Creators of the work (composers, arrangers, lyricists, etc.).
    public var creators: [Creator]

    /// Copyright and rights information.
    public var rights: [String]

    /// Encoding information (software, date, etc.).
    public var encoding: EncodingInfo?

    /// Source document information.
    public var source: String?

    /// Creates empty metadata.
    public init(
        workTitle: String? = nil,
        workNumber: String? = nil,
        movementTitle: String? = nil,
        movementNumber: String? = nil,
        creators: [Creator] = [],
        rights: [String] = [],
        encoding: EncodingInfo? = nil,
        source: String? = nil
    ) {
        self.workTitle = workTitle
        self.workNumber = workNumber
        self.movementTitle = movementTitle
        self.movementNumber = movementNumber
        self.creators = creators
        self.rights = rights
        self.encoding = encoding
        self.source = source
    }
}

/// A creator of a musical work.
public struct Creator: Codable, Sendable {
    /// The type of creator (e.g., "composer", "lyricist", "arranger").
    public var type: String?

    /// The creator's name.
    public var name: String

    public init(type: String? = nil, name: String) {
        self.type = type
        self.name = name
    }
}

/// Information about how the score was encoded.
public struct EncodingInfo: Codable, Sendable {
    /// The software used to create the encoding.
    public var software: [String]

    /// The encoding date.
    public var encodingDate: String?

    /// The encoder's name.
    public var encoder: String?

    /// Encoding description.
    public var encodingDescription: String?

    public init(
        software: [String] = [],
        encodingDate: String? = nil,
        encoder: String? = nil,
        encodingDescription: String? = nil
    ) {
        self.software = software
        self.encodingDate = encodingDate
        self.encoder = encoder
        self.encodingDescription = encodingDescription
    }
}

// MARK: - Score Defaults

/// Score-wide layout and engraving defaults.
///
/// `ScoreDefaults` contains information about page dimensions, scaling, and appearance
/// settings that apply to the entire score. These values typically come from MusicXML's
/// `<defaults>` element and inform the layout engine.
///
/// ## Scaling System
///
/// MusicXML uses "tenths" as its internal unit, where 40 tenths = one staff space.
/// The `Scaling` struct converts between tenths and physical units (millimeters/points).
///
/// ```swift
/// if let scaling = score.defaults?.scaling {
///     let pointsPerTenth = scaling.toPoints(1)
///     let staffHeight = scaling.toPoints(40 * 4)  // 4 staff spaces
/// }
/// ```
///
/// ## Concert vs. Transposed Scores
///
/// The `concertScore` property indicates whether pitches are written at sounding
/// pitch (concert) or in the key of each transposing instrument.
public struct ScoreDefaults: Codable, Sendable {
    /// Page scaling (relationship between tenths and millimeters).
    public var scaling: Scaling?

    /// Whether this is a concert score (vs. transposed).
    public var concertScore: Bool

    /// Page layout settings.
    public var pageSettings: PageSettings?

    /// System layout settings.
    public var systemLayout: SystemLayout?

    /// Staff-specific layout settings.
    public var staffLayouts: [StaffLayout]

    /// Appearance settings (line widths, note sizes).
    public var appearance: Appearance?

    /// The music font to use.
    public var musicFont: FontSpecification?

    /// The word font for text.
    public var wordFont: FontSpecification?

    public init(
        scaling: Scaling? = nil,
        concertScore: Bool = false,
        pageSettings: PageSettings? = nil,
        systemLayout: SystemLayout? = nil,
        staffLayouts: [StaffLayout] = [],
        appearance: Appearance? = nil,
        musicFont: FontSpecification? = nil,
        wordFont: FontSpecification? = nil
    ) {
        self.scaling = scaling
        self.concertScore = concertScore
        self.pageSettings = pageSettings
        self.systemLayout = systemLayout
        self.staffLayouts = staffLayouts
        self.appearance = appearance
        self.musicFont = musicFont
        self.wordFont = wordFont
    }
}

/// Scaling between tenths and physical units.
///
/// `Scaling` defines the relationship between MusicXML's internal "tenths" unit
/// and real-world measurements. This is essential for rendering at the correct size.
///
/// ## Understanding Tenths
///
/// In MusicXML, one staff space (the distance between two staff lines) equals 40 tenths.
/// The scaling tells us how many millimeters correspond to this reference.
///
/// ```swift
/// // Typical values: 40 tenths = 7.05mm (standard staff height ~28.2mm)
/// let scaling = Scaling(millimeters: 7.05, tenths: 40)
///
/// // Convert tenths to points for Core Graphics
/// let noteheadWidth = scaling.toPoints(12)  // ~2.1 points
/// ```
public struct Scaling: Codable, Sendable {
    /// Millimeters for the reference distance.
    public var millimeters: Double

    /// Tenths (internal units) for the reference distance.
    public var tenths: Double

    public init(millimeters: Double, tenths: Double) {
        self.millimeters = millimeters
        self.tenths = tenths
    }

    /// Converts tenths to millimeters.
    public func toMillimeters(_ value: Double) -> Double {
        (value / tenths) * millimeters
    }

    /// Converts millimeters to tenths.
    public func toTenths(_ mm: Double) -> Double {
        (mm / millimeters) * tenths
    }

    /// Converts tenths to points (72 points per inch).
    public func toPoints(_ value: Double) -> Double {
        let mm = toMillimeters(value)
        return mm * (72.0 / 25.4)
    }
}

/// Page layout settings (MusicXML page-layout).
public struct PageSettings: Codable, Sendable {
    /// Page height in tenths.
    public var pageHeight: Double?

    /// Page width in tenths.
    public var pageWidth: Double?

    /// Left margin in tenths.
    public var leftMargin: Double?

    /// Right margin in tenths.
    public var rightMargin: Double?

    /// Top margin in tenths.
    public var topMargin: Double?

    /// Bottom margin in tenths.
    public var bottomMargin: Double?

    public init(
        pageHeight: Double? = nil,
        pageWidth: Double? = nil,
        leftMargin: Double? = nil,
        rightMargin: Double? = nil,
        topMargin: Double? = nil,
        bottomMargin: Double? = nil
    ) {
        self.pageHeight = pageHeight
        self.pageWidth = pageWidth
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
    }
}

/// System layout settings.
public struct SystemLayout: Codable, Sendable {
    /// Left margin for systems.
    public var systemLeftMargin: Double?

    /// Right margin for systems.
    public var systemRightMargin: Double?

    /// Distance between systems.
    public var systemDistance: Double?

    /// Distance from page top to first system.
    public var topSystemDistance: Double?

    public init(
        systemLeftMargin: Double? = nil,
        systemRightMargin: Double? = nil,
        systemDistance: Double? = nil,
        topSystemDistance: Double? = nil
    ) {
        self.systemLeftMargin = systemLeftMargin
        self.systemRightMargin = systemRightMargin
        self.systemDistance = systemDistance
        self.topSystemDistance = topSystemDistance
    }
}

/// Staff-specific layout settings.
public struct StaffLayout: Codable, Sendable {
    /// The staff number this applies to (nil = all staves).
    public var staffNumber: Int?

    /// Distance from the previous staff.
    public var staffDistance: Double?

    public init(staffNumber: Int? = nil, staffDistance: Double? = nil) {
        self.staffNumber = staffNumber
        self.staffDistance = staffDistance
    }
}

/// Visual appearance settings.
public struct Appearance: Codable, Sendable {
    /// Line width settings.
    public var lineWidths: [LineWidth]

    /// Note size settings.
    public var noteSizes: [NoteSize]

    public init(lineWidths: [LineWidth] = [], noteSizes: [NoteSize] = []) {
        self.lineWidths = lineWidths
        self.noteSizes = noteSizes
    }
}

/// A line width setting.
public struct LineWidth: Codable, Sendable {
    /// The type of line.
    public var type: String

    /// The width in tenths.
    public var value: Double

    public init(type: String, value: Double) {
        self.type = type
        self.value = value
    }
}

/// A note size setting.
public struct NoteSize: Codable, Sendable {
    /// The type of note (e.g., "cue", "grace").
    public var type: String

    /// The size as a percentage (100 = normal).
    public var value: Double

    public init(type: String, value: Double) {
        self.type = type
        self.value = value
    }
}

/// Font specification.
public struct FontSpecification: Codable, Sendable {
    /// Font family names in preference order.
    public var fontFamily: [String]

    /// Font style.
    public var fontStyle: FontStyle?

    /// Font size in points.
    public var fontSize: Double?

    /// Font weight.
    public var fontWeight: FontWeight?

    public init(
        fontFamily: [String],
        fontStyle: FontStyle? = nil,
        fontSize: Double? = nil,
        fontWeight: FontWeight? = nil
    ) {
        self.fontFamily = fontFamily
        self.fontStyle = fontStyle
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
}

/// Font style.
public enum FontStyle: String, Codable, Sendable {
    case normal
    case italic
}

/// Font weight.
public enum FontWeight: String, Codable, Sendable {
    case normal
    case bold
}

// MARK: - Credit

/// A credit element displayed on the score.
public struct Credit: Codable, Sendable {
    /// The page number this credit appears on.
    public var page: Int?

    /// The type of credit (e.g., "title", "composer").
    public var creditType: String?

    /// The credit text content.
    public var creditWords: [CreditWords]

    public init(page: Int? = nil, creditType: String? = nil, creditWords: [CreditWords] = []) {
        self.page = page
        self.creditType = creditType
        self.creditWords = creditWords
    }
}

/// Text content within a credit.
public struct CreditWords: Codable, Sendable {
    /// The text content.
    public var text: String

    /// X position in tenths.
    public var defaultX: Double?

    /// Y position in tenths.
    public var defaultY: Double?

    /// Font specification.
    public var font: FontSpecification?

    /// Justification.
    public var justify: Justification?

    public init(
        text: String,
        defaultX: Double? = nil,
        defaultY: Double? = nil,
        font: FontSpecification? = nil,
        justify: Justification? = nil
    ) {
        self.text = text
        self.defaultX = defaultX
        self.defaultY = defaultY
        self.font = font
        self.justify = justify
    }
}

/// Text justification.
public enum Justification: String, Codable, Sendable {
    case left
    case center
    case right
}
