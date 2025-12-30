import SwiftUI
import SwiftMusicNotation

struct SettingsView: View {
    @Bindable var settings: AppearanceSettings
    @Environment(\.dismiss) private var dismiss
    @State private var fontLoadError: String?

    enum ColorPreset: String, CaseIterable {
        case classic = "Classic"
        case dark = "Dark Mode"
        case sepia = "Sepia"
        case highContrast = "High Contrast"
        case custom = "Custom"
    }

    @State private var selectedColorPreset: ColorPreset = .classic

    var body: some View {
        NavigationStack {
            Form {
                // Font section
                Section("Font") {
                    Picker("Music Font", selection: $settings.selectedFontName) {
                        ForEach(settings.availableFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    .onChange(of: settings.selectedFontName) { _, newFont in
                        loadFont(newFont)
                    }
                }

                // Color presets section
                Section {
                    Picker("Color Scheme", selection: $selectedColorPreset) {
                        ForEach(ColorPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .onChange(of: selectedColorPreset) { _, newPreset in
                        applyColorPreset(newPreset)
                    }

                    if selectedColorPreset == .custom {
                        ColorPicker("Background", selection: $settings.backgroundColor)
                        ColorPicker("Notes", selection: $settings.noteColor)
                        ColorPicker("Staff Lines", selection: $settings.staffLineColor)
                        ColorPicker("Barlines", selection: $settings.barlineColor)
                    }
                } header: {
                    Text("Colors")
                }

                // Line thickness section
                Section("Line Thickness") {
                    SliderRow(label: "Staff Lines", value: $settings.staffLineThickness, range: 0.3...2.0)
                    SliderRow(label: "Stems", value: $settings.stemThickness, range: 0.3...2.0)
                }

                // Layout section with expanded controls
                Section {
                    // Page size picker
                    Picker("Page Size", selection: $settings.pageSize) {
                        ForEach(AppearanceSettings.PageSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }

                    if settings.pageSize == .custom {
                        HStack {
                            Text("Width")
                            Spacer()
                            TextField("Width", value: $settings.customPageWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("pt")
                        }
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $settings.customPageHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("pt")
                        }
                    }

                    // Staff height
                    SliderRow(
                        label: "Staff Height",
                        value: $settings.staffHeight,
                        range: 20...60,
                        format: "%.0f pt"
                    )

                    // Horizontal spacing
                    DisclosureGroup("Horizontal Spacing") {
                        SliderRow(
                            label: "Quarter Note Width",
                            value: $settings.quarterNoteSpacing,
                            range: 20...50,
                            format: "%.0f pt"
                        )
                        SliderRow(
                            label: "Spacing Factor",
                            value: $settings.spacingFactor,
                            range: 0.4...1.2,
                            format: "%.2f"
                        )
                    }

                    // Vertical spacing
                    DisclosureGroup("Vertical Spacing") {
                        SliderRow(
                            label: "System Distance",
                            value: $settings.systemDistance,
                            range: 40...120,
                            format: "%.0f pt"
                        )
                        SliderRow(
                            label: "Part Distance",
                            value: $settings.partDistance,
                            range: 40...120,
                            format: "%.0f pt"
                        )
                    }

                    // Margins
                    DisclosureGroup("Margins") {
                        SliderRow(label: "Top", value: $settings.marginTop, range: 20...150, format: "%.0f pt")
                        SliderRow(label: "Bottom", value: $settings.marginBottom, range: 20...150, format: "%.0f pt")
                        SliderRow(label: "Left", value: $settings.marginLeft, range: 20...150, format: "%.0f pt")
                        SliderRow(label: "Right", value: $settings.marginRight, range: 20...150, format: "%.0f pt")
                    }
                } header: {
                    Text("Layout")
                } footer: {
                    Text("Adjust spacing and page dimensions for different display or print needs.")
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
            fontLoadError = "Failed to load \(fontName)"
        }
    }

    private func applyColorPreset(_ preset: ColorPreset) {
        switch preset {
        case .classic:
            settings.backgroundColor = .white
            settings.noteColor = .black
            settings.staffLineColor = .black
            settings.barlineColor = .black
        case .dark:
            settings.backgroundColor = Color(white: 0.1)
            settings.noteColor = Color(white: 0.95)
            settings.staffLineColor = Color(white: 0.85)
            settings.barlineColor = Color(white: 0.85)
        case .sepia:
            settings.backgroundColor = Color(red: 0.98, green: 0.96, blue: 0.90)
            settings.noteColor = Color(red: 0.2, green: 0.15, blue: 0.1)
            settings.staffLineColor = Color(red: 0.35, green: 0.3, blue: 0.25)
            settings.barlineColor = Color(red: 0.25, green: 0.2, blue: 0.15)
        case .highContrast:
            settings.backgroundColor = .white
            settings.noteColor = .black
            settings.staffLineColor = .black
            settings.barlineColor = .black
            settings.staffLineThickness = 1.2
            settings.stemThickness = 1.0
        case .custom:
            break
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
