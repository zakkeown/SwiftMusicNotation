import Foundation
import MusicXMLExport

/// Reusable export configuration builder
struct ExportConfigBuilder {
    /// Creates a configuration for maximum compatibility
    static func compatibleConfig() -> ExportConfiguration {
        var config = ExportConfiguration()
        config.musicXMLVersion = "3.1"      // Broader compatibility
        config.encoding = .utf8             // Universal encoding
        config.includeDoctype = true        // Expected by validators
        config.addEncodingSignature = true  // Track source
        return config
    }

    /// Creates a minimal configuration for smaller files
    static func minimalConfig() -> ExportConfiguration {
        var config = ExportConfiguration()
        config.musicXMLVersion = "4.0"
        config.encoding = .utf8
        config.includeDoctype = false       // Skip DOCTYPE
        config.addEncodingSignature = false // No signature
        return config
    }

    /// Creates a configuration matching an original file's settings
    static func matchingConfig(from score: Score) -> ExportConfiguration {
        var config = ExportConfiguration()

        // Try to match the original version
        if let version = score.metadata.encoding?.musicXMLVersion {
            config.musicXMLVersion = version
        }

        config.includeDoctype = true
        config.addEncodingSignature = true
        return config
    }
}
