import Foundation
import CoreGraphics
import CoreText

/// Manages loading and caching of SMuFL-compliant music notation fonts.
///
/// `SMuFLFontManager` is the central point for loading and accessing SMuFL fonts
/// in your application. SMuFL (Standard Music Font Layout) is a specification
/// for music notation fonts that ensures consistent glyph naming and positioning.
///
/// ## What is SMuFL?
///
/// SMuFL defines:
/// - A standardized set of music notation glyphs
/// - Unicode Private Use Area (PUA) code points for each glyph
/// - Metadata format for glyph metrics and positioning
/// - Engraving defaults for consistent notation layout
///
/// Popular SMuFL fonts include Bravura (bundled), Petaluma, Leland, and Finale Maestro.
///
/// ## Loading Fonts
///
/// Use the shared instance to load fonts from your app bundle:
///
/// ```swift
/// // Load a font from your app bundle
/// let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
///
/// // Load from a specific bundle (e.g., the SMuFLKit module bundle)
/// let font = try SMuFLFontManager.shared.loadFont(
///     named: "Bravura",
///     from: Bundle.module
/// )
/// ```
///
/// ## Using Loaded Fonts
///
/// Once loaded, access the font and its metadata:
///
/// ```swift
/// let font = SMuFLFontManager.shared.currentFont!
///
/// // Create a font at a specific staff height
/// let ctFont = font.font(forStaffHeight: 40)
///
/// // Access glyph information
/// if let glyph = font.glyph(for: .noteheadBlack) {
///     // Use with Core Text for drawing
/// }
///
/// // Get glyph metrics
/// if let bbox = font.boundingBox(for: .noteheadBlack) {
///     let width = bbox.ne.x - bbox.sw.x
/// }
/// ```
///
/// ## Font Files Required
///
/// For each SMuFL font, you need:
/// 1. The font file (`.otf` or `.ttf`)
/// 2. The metadata file (`fontname_metadata.json`)
///
/// Both should be added to your app bundle.
///
/// ## Thread Safety
///
/// `SMuFLFontManager` is thread-safe and can be accessed from any thread.
/// Font loading operations are serialized internally.
///
/// - SeeAlso: `LoadedSMuFLFont` for font access and glyph lookup
/// - SeeAlso: `SMuFLGlyphName` for the complete glyph catalog
/// - SeeAlso: `EngravingDefaults` for layout recommendations
public final class SMuFLFontManager: @unchecked Sendable {

    /// The shared font manager instance.
    ///
    /// Use this singleton for all font loading operations:
    ///
    /// ```swift
    /// let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
    /// ```
    public static let shared = SMuFLFontManager()

    // MARK: - Private Properties

    private var loadedFonts: [String: LoadedSMuFLFont] = [:]
    private var currentFontName: String?
    private let lock = NSLock()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// The currently active font, or `nil` if no font has been loaded.
    ///
    /// After loading a font with `loadFont(named:from:)`, it automatically
    /// becomes the current font. You can also switch between loaded fonts
    /// using `setCurrentFont(named:)`.
    public var currentFont: LoadedSMuFLFont? {
        lock.lock()
        defer { lock.unlock() }
        guard let name = currentFontName else { return nil }
        return loadedFonts[name]
    }

    /// Loads a SMuFL font from a bundle.
    ///
    /// This method:
    /// 1. Locates the font file (`.otf` or `.ttf`) in the bundle
    /// 2. Registers the font with Core Text
    /// 3. Loads the metadata file if present
    /// 4. Caches the font for future use
    /// 5. Sets it as the current font
    ///
    /// If the font is already loaded, returns the cached instance without
    /// re-registering.
    ///
    /// - Parameters:
    ///   - fontName: The name of the font file without extension (e.g., "Bravura").
    ///   - bundle: The bundle containing the font and metadata files.
    ///     Defaults to `Bundle.main`.
    /// - Returns: The loaded font instance.
    /// - Throws: `SMuFLFontError.fontFileNotFound` if the font file doesn't exist.
    ///   `SMuFLFontError.fontRegistrationFailed` if Core Text fails to load it.
    ///   `SMuFLFontError.invalidFontFile` if the font data is corrupted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
    ///     print("Loaded \(font.name)")
    /// } catch let error as SMuFLFontError {
    ///     print("Font loading failed: \(error.localizedDescription)")
    /// }
    /// ```
    @discardableResult
    public func loadFont(named fontName: String, from bundle: Bundle = .main) throws -> LoadedSMuFLFont {
        // Validate font name before any file operations
        try validateFontName(fontName)

        lock.lock()
        defer { lock.unlock() }

        // Return cached font if already loaded
        if let cached = loadedFonts[fontName] {
            currentFontName = fontName
            return cached
        }

        // Find font file
        guard let fontURL = bundle.url(forResource: fontName, withExtension: "otf")
            ?? bundle.url(forResource: fontName, withExtension: "ttf") else {
            throw SMuFLFontError.fontFileNotFound(fontName)
        }

        // Find metadata file
        let metadataURL = bundle.url(forResource: "\(fontName.lowercased())_metadata", withExtension: "json")
            ?? bundle.url(forResource: "\(fontName)_metadata", withExtension: "json")
            ?? bundle.url(forResource: "metadata", withExtension: "json",
                         subdirectory: "Fonts/\(fontName)")

        // Register font with Core Text
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) else {
            if let cfError = error?.takeRetainedValue() {
                throw SMuFLFontError.fontRegistrationFailed(fontName, cfError as Error)
            }
            throw SMuFLFontError.fontRegistrationFailed(fontName, nil)
        }

        // Create CTFont
        guard let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
              let descriptor = fontDescriptors.first else {
            throw SMuFLFontError.invalidFontFile(fontName)
        }

        let ctFont = CTFontCreateWithFontDescriptor(descriptor, 0, nil)

        // Load metadata if available
        var metadata: SMuFLFontMetadata?
        if let metadataURL = metadataURL {
            metadata = try loadMetadata(from: metadataURL)
        }

        let loadedFont = LoadedSMuFLFont(
            name: fontName,
            ctFont: ctFont,
            metadata: metadata
        )

        loadedFonts[fontName] = loadedFont
        currentFontName = fontName

        return loadedFont
    }

    /// Sets the current font to a previously loaded font.
    ///
    /// Use this to switch between multiple loaded fonts without reloading.
    ///
    /// - Parameter fontName: The name of a previously loaded font.
    /// - Throws: `SMuFLFontError.fontNotLoaded` if the font hasn't been loaded.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Load multiple fonts
    /// try SMuFLFontManager.shared.loadFont(named: "Bravura")
    /// try SMuFLFontManager.shared.loadFont(named: "Petaluma")
    ///
    /// // Switch between them
    /// try SMuFLFontManager.shared.setCurrentFont(named: "Bravura")
    /// ```
    public func setCurrentFont(named fontName: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard loadedFonts[fontName] != nil else {
            throw SMuFLFontError.fontNotLoaded(fontName)
        }
        currentFontName = fontName
    }

    /// The names of all currently loaded fonts.
    ///
    /// Use this to populate a font selection UI or check if a font is loaded.
    public var loadedFontNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(loadedFonts.keys)
    }

    // MARK: - Private Methods

    /// Maximum allowed size for metadata files (10 MB).
    private static let maxMetadataFileSize: Int = 10 * 1024 * 1024

    private func loadMetadata(from url: URL) throws -> SMuFLFontMetadata {
        // Check file size before loading to prevent DoS
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Int, fileSize > Self.maxMetadataFileSize {
            throw SMuFLFontError.metadataFileTooLarge(url.lastPathComponent, fileSize)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(SMuFLFontMetadata.self, from: data)
    }

    /// Validates that a font name doesn't contain path traversal attempts.
    private func validateFontName(_ fontName: String) throws {
        // Check for path separators
        if fontName.contains("/") || fontName.contains("\\") {
            throw SMuFLFontError.invalidFontName(fontName)
        }

        // Check for path traversal
        if fontName.contains("..") {
            throw SMuFLFontError.invalidFontName(fontName)
        }

        // Check for empty or whitespace-only names
        if fontName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SMuFLFontError.invalidFontName(fontName)
        }
    }
}

// MARK: - Loaded Font

/// A loaded SMuFL font ready for use in music notation rendering.
///
/// `LoadedSMuFLFont` represents a fully loaded SMuFL font with its Core Text
/// font reference and optional metadata. Use this class to:
/// - Create font instances at specific sizes
/// - Look up glyphs by SMuFL name
/// - Access glyph metrics (bounding boxes, anchors, advance widths)
/// - Get engraving defaults for layout
///
/// ## Creating Sized Fonts
///
/// SMuFL fonts are designed so 1 em = 4 staff spaces. Create a font for your
/// desired staff height:
///
/// ```swift
/// // For a 40-point staff height
/// let ctFont = loadedFont.font(forStaffHeight: 40)
///
/// // Use with Core Text for drawing
/// CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)
/// ```
///
/// ## Looking Up Glyphs
///
/// Access glyphs by their standardized SMuFL name:
///
/// ```swift
/// if let glyph = font.glyph(for: .noteheadBlack) {
///     // glyph is a CGGlyph ready for Core Text rendering
/// }
///
/// // Or by Unicode code point
/// if let glyph = font.glyph(forCodePoint: 0xE0A4) {
///     // Same notehead by code point
/// }
/// ```
///
/// ## Accessing Metrics
///
/// Get precise glyph metrics for layout calculations:
///
/// ```swift
/// // Bounding box (in staff spaces)
/// if let bbox = font.boundingBox(for: .noteheadBlack) {
///     let width = bbox.ne.x - bbox.sw.x  // Width in staff spaces
/// }
///
/// // Anchor points for precise alignment
/// if let anchors = font.anchors(for: .noteheadBlack) {
///     let stemUpSE = anchors.stemUpSE  // Stem attachment point
/// }
///
/// // Advance width for horizontal spacing
/// if let advance = font.advanceWidth(for: .noteheadBlack) {
///     // advance is in staff spaces
/// }
/// ```
///
/// ## Thread Safety
///
/// `LoadedSMuFLFont` is thread-safe. Glyph lookups are cached internally
/// for performance.
///
/// - SeeAlso: `SMuFLFontManager` for loading fonts
/// - SeeAlso: `SMuFLGlyphName` for glyph name constants
/// - SeeAlso: `EngravingDefaults` for layout recommendations
public final class LoadedSMuFLFont: @unchecked Sendable {

    /// The font name (e.g., "Bravura").
    public let name: String

    /// The Core Text font reference at the default size.
    ///
    /// Use `font(forStaffHeight:)` to create a font at a specific size.
    public let ctFont: CTFont

    /// The font metadata, or `nil` if metadata wasn't loaded.
    ///
    /// Metadata includes glyph bounding boxes, anchors, and engraving defaults.
    /// While optional, most SMuFL fonts include metadata for proper rendering.
    public let metadata: SMuFLFontMetadata?

    /// The engraving defaults recommended by this font.
    ///
    /// Returns the font's recommended values for things like stem length,
    /// beam thickness, etc. Falls back to standard defaults if metadata
    /// isn't available.
    public var engravingDefaults: EngravingDefaults {
        metadata?.engravingDefaults ?? .default
    }

    // MARK: - Caches

    private var glyphCache: [UInt32: CGGlyph] = [:]
    private let cacheLock = NSLock()

    // MARK: - Initialization

    init(name: String, ctFont: CTFont, metadata: SMuFLFontMetadata?) {
        self.name = name
        self.ctFont = ctFont
        self.metadata = metadata
    }

    // MARK: - Font Creation

    /// Creates a Core Text font at the specified staff height.
    ///
    /// SMuFL fonts are designed so that 1 em (the font size) equals 4 staff
    /// spaces. This means the font size in points equals the staff height
    /// in points.
    ///
    /// - Parameter staffHeight: The desired staff height in points. For example,
    ///   40 points creates a standard-sized staff.
    /// - Returns: A `CTFont` at the appropriate size for rendering.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let ctFont = loadedFont.font(forStaffHeight: 40)
    ///
    /// // Draw a glyph
    /// var glyph = font.glyph(for: .gClef)!
    /// var position = CGPoint(x: 100, y: 200)
    /// CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)
    /// ```
    public func font(forStaffHeight staffHeight: CGFloat) -> CTFont {
        CTFontCreateCopyWithAttributes(ctFont, staffHeight, nil, nil)
    }

    // MARK: - Glyph Access

    /// Returns the Core Graphics glyph for a SMuFL glyph name.
    ///
    /// - Parameter name: The standardized SMuFL glyph name.
    /// - Returns: The `CGGlyph` for use with Core Text, or `nil` if the glyph
    ///   doesn't exist in this font.
    public func glyph(for name: SMuFLGlyphName) -> CGGlyph? {
        glyph(forCodePoint: name.codePoint)
    }

    /// Returns the Core Graphics glyph for a Unicode code point.
    ///
    /// SMuFL glyphs use Unicode Private Use Area code points (U+E000-U+F8FF).
    ///
    /// - Parameter codePoint: The Unicode code point (e.g., 0xE050 for G clef).
    /// - Returns: The `CGGlyph` for use with Core Text, or `nil` if the glyph
    ///   doesn't exist in this font.
    public func glyph(forCodePoint codePoint: UInt32) -> CGGlyph? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = glyphCache[codePoint] {
            return cached == 0 ? nil : cached
        }

        // Convert code point to UTF-16
        guard let scalar = UnicodeScalar(codePoint) else {
            glyphCache[codePoint] = 0
            return nil
        }

        let string = String(Character(scalar))
        var characters = Array(string.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)

        guard CTFontGetGlyphsForCharacters(ctFont, &characters, &glyphs, characters.count),
              let firstGlyph = glyphs.first else {
            glyphCache[codePoint] = 0
            return nil
        }

        glyphCache[codePoint] = firstGlyph
        return firstGlyph
    }

    // MARK: - Metadata Access

    /// Returns the bounding box for a glyph in staff spaces.
    ///
    /// The bounding box defines the visual extent of the glyph.
    ///
    /// - Parameter name: The glyph to query.
    /// - Returns: The bounding box, or `nil` if metadata isn't available.
    public func boundingBox(for name: SMuFLGlyphName) -> GlyphBoundingBox? {
        metadata?.glyphBBoxes?[name.rawValue]
    }

    /// Returns the anchor points for a glyph.
    ///
    /// Anchors define precise attachment points for stems, articulations,
    /// and other elements. Common anchors include:
    /// - `stemUpSE`: Stem attachment point for stem-up notes
    /// - `stemDownNW`: Stem attachment point for stem-down notes
    /// - `cutOutNE`, `cutOutSE`: Notehead cutout points for flag positioning
    ///
    /// - Parameter name: The glyph to query.
    /// - Returns: The anchor points, or `nil` if not defined.
    public func anchors(for name: SMuFLGlyphName) -> GlyphAnchors? {
        guard let anchorData = metadata?.glyphsWithAnchors?[name.rawValue] else {
            return nil
        }
        return GlyphAnchors(anchors: anchorData)
    }

    /// Returns the advance width for a glyph in staff spaces.
    ///
    /// The advance width is the horizontal distance to move after drawing
    /// the glyph, used for spacing calculations.
    ///
    /// - Parameter name: The glyph to query.
    /// - Returns: The advance width, or `nil` if not defined.
    public func advanceWidth(for name: SMuFLGlyphName) -> StaffSpaces? {
        metadata?.glyphAdvanceWidths?[name.rawValue]
    }
}

// MARK: - Font Metadata

/// Complete metadata for a SMuFL font, loaded from its `metadata.json` file.
///
/// SMuFL metadata provides essential information for accurate music notation
/// rendering, including glyph metrics, anchor points, and font-specific
/// engraving recommendations.
///
/// This structure is automatically populated when loading a font with
/// `SMuFLFontManager`. Access it through `LoadedSMuFLFont.metadata` or
/// use the convenience methods on `LoadedSMuFLFont`.
///
/// - Note: Not all fonts provide complete metadata. Always handle optional
///   values appropriately.
public struct SMuFLFontMetadata: Codable, Sendable {
    /// The font name as specified in the metadata file.
    public let fontName: String?

    /// The font version string.
    public let fontVersion: String?

    /// The design size in decipoints (1/720 inch).
    public let designSize: Int?

    /// The recommended size range as [min, max] in points.
    public let sizeRange: [Int]?

    /// Engraving defaults recommended by this font.
    ///
    /// Contains values for stem lengths, beam thicknesses, and other
    /// layout parameters.
    public let engravingDefaults: EngravingDefaults?

    /// Advance widths for each glyph in staff spaces.
    public let glyphAdvanceWidths: [String: StaffSpaces]?

    /// Bounding boxes for each glyph.
    public let glyphBBoxes: [String: GlyphBoundingBox]?

    /// Anchor points for glyphs that have them.
    ///
    /// The dictionary maps glyph names to a dictionary of anchor names
    /// to coordinate arrays [x, y] in staff spaces.
    public let glyphsWithAnchors: [String: [String: [CGFloat]]]?

    /// Optional glyphs provided by this font beyond the required set.
    public let optionalGlyphs: [String: OptionalGlyph]?

    /// Alternate glyphs available for some base glyphs.
    public let glyphsWithAlternates: [String: GlyphAlternateSet]?

    /// Ligatures (combined glyphs) available in this font.
    public let ligatures: [String: GlyphLigature]?

    /// Stylistic sets defining alternate glyph appearances.
    public let sets: [String: StylisticSet]?
}

/// A set of alternate forms for a base glyph.
public struct GlyphAlternateSet: Codable, Sendable {
    /// The available alternate glyphs.
    public let alternates: [GlyphAlternate]
}

/// Defines a named stylistic set in the font.
///
/// Stylistic sets provide coordinated alternate glyphs, such as
/// "handwritten" or "large noteheads" variants.
public struct StylisticSet: Codable, Sendable {
    /// Human-readable description of this stylistic set.
    public let description: String?
    /// The glyphs included in this stylistic set.
    public let glyphs: [String: StylisticSetGlyph]
}

/// A glyph that belongs to a stylistic set.
public struct StylisticSetGlyph: Codable, Sendable {
    /// The Unicode code point as a hex string (e.g., "E0A4").
    public let codepoint: String
    /// The glyph name.
    public let name: String
    /// The base glyph this replaces, if applicable.
    public let alternateFor: String?
}

// MARK: - Errors

/// Errors that can occur when working with SMuFL fonts.
///
/// Handle these errors when loading fonts to provide appropriate feedback
/// to users or fallback behavior.
public enum SMuFLFontError: LocalizedError {
    /// The font file (`.otf` or `.ttf`) was not found in the bundle.
    case fontFileNotFound(String)
    /// The metadata JSON file was not found (optional in some workflows).
    case metadataFileNotFound(String)
    /// The font file exists but couldn't be parsed as a valid font.
    case invalidFontFile(String)
    /// Core Text refused to register the font.
    case fontRegistrationFailed(String, Error?)
    /// Attempted to use a font that hasn't been loaded yet.
    case fontNotLoaded(String)
    /// A specific glyph was requested but doesn't exist in the font.
    case glyphNotFound(SMuFLGlyphName)
    /// The font name contains invalid characters (path separators, traversal).
    case invalidFontName(String)
    /// The metadata file exceeds the maximum allowed size.
    case metadataFileTooLarge(String, Int)

    public var errorDescription: String? {
        switch self {
        case .fontFileNotFound(let name):
            return "Font file not found: \(name)"
        case .metadataFileNotFound(let name):
            return "Metadata file not found for font: \(name)"
        case .invalidFontFile(let name):
            return "Invalid font file: \(name)"
        case .fontRegistrationFailed(let name, let error):
            if let error = error {
                return "Failed to register font '\(name)': \(error.localizedDescription)"
            }
            return "Failed to register font: \(name)"
        case .fontNotLoaded(let name):
            return "Font not loaded: \(name)"
        case .glyphNotFound(let glyph):
            return "Glyph not found: \(glyph.rawValue)"
        case .invalidFontName(let name):
            return "Invalid font name: \(name)"
        case .metadataFileTooLarge(let name, let size):
            return "Metadata file '\(name)' is too large (\(size) bytes)"
        }
    }
}
