import SwiftUI
import MusicXMLExport

struct ExportSettingsView: View {
    @Binding var selectedPreset: ExportPreset
    @Binding var customVersion: String
    @Binding var includeDoctype: Bool
    @Binding var addSignature: Bool
    @State private var useCustomSettings = false

    var body: some View {
        Form {
            Section("Export Preset") {
                Picker("Preset", selection: $selectedPreset) {
                    ForEach(ExportPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedPreset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Advanced Options") {
                Toggle("Use Custom Settings", isOn: $useCustomSettings)

                if useCustomSettings {
                    Picker("MusicXML Version", selection: $customVersion) {
                        Text("4.0 (Latest)").tag("4.0")
                        Text("3.1").tag("3.1")
                        Text("3.0").tag("3.0")
                        Text("2.0 (Legacy)").tag("2.0")
                    }

                    Toggle("Include DOCTYPE", isOn: $includeDoctype)
                    Toggle("Add Software Signature", isOn: $addSignature)
                }
            }

            Section("About MusicXML Export") {
                Text("MusicXML is the standard format for sharing music notation between applications.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Settings")
        .onChange(of: selectedPreset) { _, newPreset in
            // Update custom settings to match preset
            let config = newPreset.configuration
            customVersion = config.musicXMLVersion
            includeDoctype = config.includeDoctype
            addSignature = config.addEncodingSignature
        }
    }

    var currentConfiguration: ExportConfiguration {
        if useCustomSettings {
            var config = ExportConfiguration()
            config.musicXMLVersion = customVersion
            config.includeDoctype = includeDoctype
            config.addEncodingSignature = addSignature
            return config
        } else {
            return selectedPreset.configuration
        }
    }
}
