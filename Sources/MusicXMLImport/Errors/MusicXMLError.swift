import Foundation

/// Errors that can occur during MusicXML import.
///
/// `MusicXMLError` provides detailed information about failures during the import
/// process. Errors are grouped into categories: file access, archive handling,
/// XML parsing, version compatibility, and content validation.
///
/// ## Error Handling
///
/// Use pattern matching to handle specific error cases:
///
/// ```swift
/// do {
///     let score = try importer.importScore(from: url)
/// } catch let error as MusicXMLError {
///     switch error {
///     case .fileNotFound(let url):
///         showError("File not found: \(url.lastPathComponent)")
///     case .xmlParsingFailed(let line, let column, let message):
///         showError("Parse error at line \(line ?? 0): \(message)")
///     case .invalidPitch(let step, let octave):
///         showError("Invalid pitch: \(step ?? "?") \(octave ?? 0)")
///     default:
///         showError(error.localizedDescription)
///     }
/// }
/// ```
///
/// ## Error Categories
///
/// - **File Errors**: Problems accessing or reading the file
/// - **Archive Errors**: Issues with compressed `.mxl` archives
/// - **XML Parsing Errors**: Malformed XML or structure problems
/// - **Version Errors**: Unsupported MusicXML versions
/// - **Content Errors**: Invalid musical content (pitches, durations, etc.)
public enum MusicXMLError: Error, LocalizedError {
    // MARK: - File Errors

    /// The specified file does not exist at the given URL.
    case fileNotFound(URL)

    /// The file exists but cannot be read (permissions, encoding, etc.).
    case unableToReadFile(URL, underlying: Error?)

    /// The file format is not recognized as MusicXML or MXL.
    case invalidFileFormat(String)

    // MARK: - Archive Errors

    /// The `.mxl` file is not a valid ZIP archive or is corrupted.
    case invalidMXLArchive(String)

    /// The MXL archive is missing the required `META-INF/container.xml` file.
    case missingContainerXML

    /// The `container.xml` file does not specify a root MusicXML file.
    case missingRootFile

    /// The archive could not be decompressed.
    case corruptedArchive(underlying: Error)

    // MARK: - XML Parsing Errors

    /// XML parsing failed at the specified location.
    case xmlParsingFailed(line: Int?, column: Int?, message: String)

    /// The XML structure is invalid (e.g., missing root element, wrong nesting).
    case invalidXMLStructure(String)

    /// A required XML element is missing.
    case missingRequiredElement(element: String, parent: String?)

    /// An XML attribute has an invalid value.
    case invalidAttributeValue(attribute: String, element: String, value: String)

    // MARK: - Version Errors

    /// The MusicXML version is not supported by this importer.
    case unsupportedVersion(String)

    /// The MusicXML file does not specify a version.
    case missingVersion

    // MARK: - Content Errors

    /// A pitch specification is invalid (bad step letter or octave).
    case invalidPitch(step: String?, octave: Int?)

    /// A duration value is invalid or cannot be computed.
    case invalidDuration(value: Int?, divisions: Int?)

    /// A time signature has invalid beat count or beat type.
    case invalidTimeSignature(beats: String?, beatType: String?)

    /// A key signature has an invalid number of fifths.
    case invalidKeySignature(fifths: Int?)

    /// A spanner (slur, tie, beam) has no matching start or stop element.
    case orphanedSpanner(type: String, number: Int)

    // MARK: - LocalizedError
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .unableToReadFile(let url, let underlying):
            let base = "Unable to read file: \(url.lastPathComponent)"
            if let error = underlying {
                return "\(base) - \(error.localizedDescription)"
            }
            return base
        case .invalidFileFormat(let message):
            return "Invalid file format: \(message)"
        case .invalidMXLArchive(let message):
            return "Invalid MXL archive: \(message)"
        case .missingContainerXML:
            return "MXL archive missing META-INF/container.xml"
        case .missingRootFile:
            return "Container.xml does not specify a root file"
        case .corruptedArchive(let error):
            return "Corrupted archive: \(error.localizedDescription)"
        case .xmlParsingFailed(let line, let column, let message):
            if let line = line, let column = column {
                return "XML parsing failed at line \(line), column \(column): \(message)"
            }
            return "XML parsing failed: \(message)"
        case .invalidXMLStructure(let message):
            return "Invalid XML structure: \(message)"
        case .missingRequiredElement(let element, let parent):
            if let parent = parent {
                return "Missing required element <\(element)> in <\(parent)>"
            }
            return "Missing required element <\(element)>"
        case .invalidAttributeValue(let attribute, let element, let value):
            return "Invalid value '\(value)' for attribute '\(attribute)' in <\(element)>"
        case .unsupportedVersion(let version):
            return "Unsupported MusicXML version: \(version)"
        case .missingVersion:
            return "MusicXML version not specified"
        case .invalidPitch(let step, let octave):
            return "Invalid pitch: step=\(step ?? "nil"), octave=\(octave.map(String.init) ?? "nil")"
        case .invalidDuration(let value, let divisions):
            return "Invalid duration: value=\(value.map(String.init) ?? "nil"), divisions=\(divisions.map(String.init) ?? "nil")"
        case .invalidTimeSignature(let beats, let beatType):
            return "Invalid time signature: \(beats ?? "?")/\(beatType ?? "?")"
        case .invalidKeySignature(let fifths):
            return "Invalid key signature: fifths=\(fifths.map(String.init) ?? "nil")"
        case .orphanedSpanner(let type, let number):
            return "Orphaned \(type) spanner (number=\(number)) without matching start/stop"
        }
    }
}

/// Recovery action that can be taken when encountering an error.
public enum MusicXMLRecoveryAction {
    /// Skip the problematic element and continue.
    case skip
    /// Use a default value.
    case useDefault
    /// Abort parsing.
    case abort
}

/// A warning encountered during parsing (non-fatal).
public struct MusicXMLWarning: CustomStringConvertible {
    public let message: String
    public let location: SourceLocation?
    public let recoveryAction: MusicXMLRecoveryAction

    public init(message: String, location: SourceLocation? = nil, recoveryAction: MusicXMLRecoveryAction = .skip) {
        self.message = message
        self.location = location
        self.recoveryAction = recoveryAction
    }

    public var description: String {
        if let loc = location {
            return "[\(loc)] \(message)"
        }
        return message
    }
}

/// Location in the source XML document.
public struct SourceLocation: CustomStringConvertible {
    public let line: Int
    public let column: Int
    public let elementPath: String?

    public init(line: Int, column: Int, elementPath: String? = nil) {
        self.line = line
        self.column = column
        self.elementPath = elementPath
    }

    public var description: String {
        if let path = elementPath {
            return "line \(line), column \(column) (\(path))"
        }
        return "line \(line), column \(column)"
    }
}
