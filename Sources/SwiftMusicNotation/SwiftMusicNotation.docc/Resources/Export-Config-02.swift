import Foundation
import MusicXMLExport

/// Reusable export configuration builder
struct ExportConfigBuilder {
    /// Creates a configuration for maximum compatibility
    static func compatibleConfig() -> ExportConfiguration {
        var config = ExportConfiguration()
        config.musicXMLVersion = "3.1"
        config.encoding = .utf8
        config.includeDoctype = true
        config.addEncodingSignature = true
        return config
    }

    /// Creates a minimal configuration for smaller files
    static func minimalConfig() -> ExportConfiguration {
        var config = ExportConfiguration()
        config.musicXMLVersion = "4.0"
        config.encoding = .utf8
        config.includeDoctype = false
        config.addEncodingSignature = false
        return config
    }

    /// Creates a configuration matching an original file's settings
    static func matchingConfig(from score: Score) -> ExportConfiguration {
        var config = ExportConfiguration()
        if let version = score.metadata.encoding?.musicXMLVersion {
            config.musicXMLVersion = version
        }
        config.includeDoctype = true
        config.addEncodingSignature = true
        return config
    }
}

// MARK: - Export Presets

enum ExportPreset: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case finale = "Finale Compatible"
    case sibelius = "Sibelius Compatible"
    case musescore = "MuseScore Compatible"
    case minimal = "Minimal"

    var id: String { rawValue }

    var configuration: ExportConfiguration {
        switch self {
        case .standard:
            var config = ExportConfiguration()
            config.musicXMLVersion = "4.0"
            config.includeDoctype = true
            config.addEncodingSignature = true
            return config

        case .finale:
            var config = ExportConfiguration()
            config.musicXMLVersion = "3.1"  // Finale prefers 3.1
            config.includeDoctype = true
            config.addEncodingSignature = true
            return config

        case .sibelius:
            var config = ExportConfiguration()
            config.musicXMLVersion = "3.0"  // Sibelius has good 3.0 support
            config.includeDoctype = true
            config.addEncodingSignature = true
            return config

        case .musescore:
            var config = ExportConfiguration()
            config.musicXMLVersion = "4.0"  // MuseScore supports latest
            config.includeDoctype = true
            config.addEncodingSignature = true
            return config

        case .minimal:
            var config = ExportConfiguration()
            config.musicXMLVersion = "4.0"
            config.includeDoctype = false
            config.addEncodingSignature = false
            return config
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "MusicXML 4.0 with full metadata"
        case .finale:
            return "Optimized for Finale import"
        case .sibelius:
            return "Optimized for Sibelius import"
        case .musescore:
            return "Optimized for MuseScore import"
        case .minimal:
            return "Smallest file size"
        }
    }
}
