import Foundation

/// Errors that can occur during MIDI file parsing and import.
public enum MIDIError: Error, Sendable {
    /// The file does not start with a valid MThd header.
    case invalidHeader
    /// The MIDI format is not supported (only formats 0 and 1).
    case unsupportedFormat(Int)
    /// Unexpected end of data while parsing.
    case unexpectedEOF
    /// A track chunk is malformed or has an invalid header.
    case invalidTrackChunk
    /// The file contains no tracks.
    case noTracks
    /// No note events were found in the file.
    case noNotes
    /// The time division format is not supported.
    case unsupportedTimeDivision
    /// A meta event has invalid data.
    case invalidMetaEvent(UInt8)
    /// The file could not be read from the given URL.
    case fileReadError(URL)
}

extension MIDIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidHeader:
            return "Invalid MIDI file header (expected MThd)."
        case .unsupportedFormat(let format):
            return "Unsupported MIDI format \(format). Only formats 0 and 1 are supported."
        case .unexpectedEOF:
            return "Unexpected end of data while parsing MIDI file."
        case .invalidTrackChunk:
            return "Invalid or malformed MIDI track chunk."
        case .noTracks:
            return "MIDI file contains no tracks."
        case .noNotes:
            return "MIDI file contains no note events."
        case .unsupportedTimeDivision:
            return "SMPTE time division is not currently supported."
        case .invalidMetaEvent(let type):
            return "Invalid meta event of type 0x\(String(type, radix: 16))."
        case .fileReadError(let url):
            return "Could not read MIDI file at \(url.path)."
        }
    }
}

/// A non-fatal warning generated during MIDI import.
public struct MIDIWarning: Sendable {
    /// A human-readable description of the warning.
    public let message: String
    /// The track index where the warning occurred, if applicable.
    public let track: Int?
    /// The tick position where the warning occurred, if applicable.
    public let tick: Int?

    public init(message: String, track: Int? = nil, tick: Int? = nil) {
        self.message = message
        self.track = track
        self.tick = tick
    }
}
