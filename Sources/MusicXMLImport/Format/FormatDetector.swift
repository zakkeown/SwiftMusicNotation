import Foundation

/// Detected MusicXML format type.
public enum MusicXMLFormat {
    /// Uncompressed partwise MusicXML (.xml or .musicxml).
    case partwise
    /// Uncompressed timewise MusicXML (.xml or .musicxml).
    case timewise
    /// Compressed MusicXML archive (.mxl).
    case compressed
    /// Unknown or unsupported format.
    case unknown
}

/// Detects the format of a MusicXML file.
public struct FormatDetector {
    public init() {}

    /// Detects the format from a file URL.
    public func detectFormat(at url: URL) throws -> MusicXMLFormat {
        let ext = url.pathExtension.lowercased()

        // Check file extension first
        if ext == "mxl" {
            return .compressed
        }

        // For XML files, we need to peek at the content
        if ext == "xml" || ext == "musicxml" {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return detectFormat(from: data)
        }

        // Try to detect from content for unknown extensions
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
            return detectFormat(from: data)
        }

        return .unknown
    }

    /// Detects the format from data.
    public func detectFormat(from data: Data) -> MusicXMLFormat {
        // Check for ZIP signature (compressed MXL)
        if isZipArchive(data) {
            return .compressed
        }

        // Check for XML content
        guard let xmlPrefix = String(data: data.prefix(1024), encoding: .utf8) else {
            return .unknown
        }

        // Look for root element
        if xmlPrefix.contains("<score-partwise") {
            return .partwise
        } else if xmlPrefix.contains("<score-timewise") {
            return .timewise
        } else if xmlPrefix.contains("<!DOCTYPE score-partwise") {
            return .partwise
        } else if xmlPrefix.contains("<!DOCTYPE score-timewise") {
            return .timewise
        }

        return .unknown
    }

    /// Checks if data starts with ZIP file signature.
    private func isZipArchive(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        // ZIP files start with PK\x03\x04
        return data[0] == 0x50 && data[1] == 0x4B && data[2] == 0x03 && data[3] == 0x04
    }
}

/// Detects the MusicXML version from document content.
public struct VersionDetector {
    public init() {}

    /// Supported MusicXML versions.
    public static let supportedVersions = ["3.0", "3.1", "4.0"]

    /// Detects the MusicXML version from XML data.
    public func detectVersion(from data: Data) -> String? {
        guard let xmlString = String(data: data.prefix(2048), encoding: .utf8) else {
            return nil
        }

        // Look for version attribute in root element
        // <score-partwise version="4.0">
        let patterns = [
            #"<score-partwise[^>]*version\s*=\s*"([^"]+)""#,
            #"<score-timewise[^>]*version\s*=\s*"([^"]+)""#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: xmlString, options: [], range: NSRange(xmlString.startIndex..., in: xmlString)),
               let versionRange = Range(match.range(at: 1), in: xmlString) {
                return String(xmlString[versionRange])
            }
        }

        // Look for DOCTYPE declaration
        // <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
        let doctypePattern = #"MusicXML\s+(\d+\.\d+)"#
        if let regex = try? NSRegularExpression(pattern: doctypePattern, options: []),
           let match = regex.firstMatch(in: xmlString, options: [], range: NSRange(xmlString.startIndex..., in: xmlString)),
           let versionRange = Range(match.range(at: 1), in: xmlString) {
            return String(xmlString[versionRange])
        }

        return nil
    }

    /// Checks if a version is supported.
    public func isSupported(version: String) -> Bool {
        // Support major.minor versions that are <= 4.0
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }

        let major = components[0]
        let minor = components[1]

        // Support versions 1.0 through 4.0
        if major >= 1 && major <= 4 {
            return true
        }

        return false
    }
}
