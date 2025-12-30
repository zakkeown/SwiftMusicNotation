import SwiftUI
import SwiftMusicNotation

struct SettingsView: View {
    @Bindable var settings: AppearanceSettings
    @Environment(\.dismiss) private var dismiss
    @State private var fontLoadError: String?

    var body: some View {
        NavigationStack {
            Form {
                // Font section with preview and loading status
                Section {
                    Picker("Music Font", selection: $settings.selectedFontName) {
                        ForEach(settings.availableFonts, id: \.self) { font in
                            HStack {
                                Text(font)
                                Spacer()
                                if SMuFLFontManager.shared.loadedFontNames.contains(font) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .tag(font)
                        }
                    }
                    .onChange(of: settings.selectedFontName) { _, newFont in
                        loadFont(newFont)
                    }

                    if let error = fontLoadError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    // Font info
                    if let font = SMuFLFontManager.shared.currentFont {
                        HStack {
                            Text("Loaded:")
                            Spacer()
                            Text(font.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Font")
                } footer: {
                    Text("SMuFL fonts define how music notation symbols appear. Different fonts have different visual styles.")
                }

                // Colors section
                Section("Colors") {
                    ColorPicker("Background", selection: $settings.backgroundColor)
                    ColorPicker("Notes", selection: $settings.noteColor)
                    ColorPicker("Staff Lines", selection: $settings.staffLineColor)
                    ColorPicker("Barlines", selection: $settings.barlineColor)
                }

                // Line thickness section
                Section("Line Thickness") {
                    SliderRow(label: "Staff Lines", value: $settings.staffLineThickness, range: 0.3...2.0)
                    SliderRow(label: "Stems", value: $settings.stemThickness, range: 0.3...2.0)
                    SliderRow(label: "Thin Barlines", value: $settings.thinBarlineThickness, range: 0.3...2.0)
                    SliderRow(label: "Thick Barlines", value: $settings.thickBarlineThickness, range: 1.0...5.0)
                }

                // Layout section
                Section("Layout") {
                    SliderRow(label: "Staff Height", value: $settings.staffHeight, range: 20...60, format: "%.0f pt")
                    SliderRow(label: "Note Spacing", value: $settings.quarterNoteSpacing, range: 20...50, format: "%.0f pt")
                    SliderRow(label: "Spacing Factor", value: $settings.spacingFactor, range: 0.4...1.2, format: "%.2f")
                }
            }
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func loadFont(_ fontName: String) {
        do {
            try SMuFLFontManager.shared.loadFont(named: fontName)
            fontLoadError = nil
        } catch {
            fontLoadError = "Failed to load \(fontName): \(error.localizedDescription)"
        }
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.1f"

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}
