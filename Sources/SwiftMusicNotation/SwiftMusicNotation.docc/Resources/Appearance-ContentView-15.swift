import SwiftUI
import SwiftMusicNotation

// MARK: - Configuration Presets

enum LayoutPreset: String, CaseIterable {
    case screenDisplay = "Screen Display"
    case printReady = "Print Ready"
    case denseScore = "Dense Score"
    case easyRead = "Easy Read"
}

extension LayoutConfiguration {
    /// Screen-optimized layout with comfortable spacing
    static var screenDisplay: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig.quarterNoteSpacing = 32.0
        config.spacingConfig.spacingFactor = 0.7
        config.verticalConfig.systemDistance = 85.0
        config.firstPageTopOffset = 70
        return config
    }

    /// Print-optimized layout with professional spacing
    static var printReady: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig.quarterNoteSpacing = 30.0
        config.spacingConfig.spacingFactor = 0.65
        config.verticalConfig.systemDistance = 75.0
        config.firstPageTopOffset = 60
        return config
    }

    /// Compact layout for scores with many measures
    static var denseScore: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig.quarterNoteSpacing = 25.0
        config.spacingConfig.spacingFactor = 0.6
        config.spacingConfig.minimumNoteSpacing = 10.0
        config.verticalConfig.staffDistance = 50.0
        config.verticalConfig.partDistance = 65.0
        config.verticalConfig.systemDistance = 60.0
        config.firstPageTopOffset = 50
        return config
    }

    /// Large, spacious layout for educational use
    static var easyRead: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig.quarterNoteSpacing = 40.0
        config.spacingConfig.spacingFactor = 0.8
        config.spacingConfig.minimumNoteSpacing = 18.0
        config.verticalConfig.staffDistance = 75.0
        config.verticalConfig.partDistance = 100.0
        config.verticalConfig.systemDistance = 100.0
        config.firstPageTopOffset = 90
        return config
    }
}

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @AppStorage("layoutPreset") private var selectedPreset = LayoutPreset.screenDisplay.rawValue

    var layoutContext: LayoutContext {
        switch LayoutPreset(rawValue: selectedPreset) {
        case .easyRead:
            return LayoutContext.letterSize(staffHeight: 50)
        case .denseScore:
            return LayoutContext.letterSize(staffHeight: 30)
        default:
            return LayoutContext.letterSize(staffHeight: 40)
        }
    }

    var layoutConfig: LayoutConfiguration {
        switch LayoutPreset(rawValue: selectedPreset) {
        case .screenDisplay:
            return .screenDisplay
        case .printReady:
            return .printReady
        case .denseScore:
            return .denseScore
        case .easyRead:
            return .easyRead
        case .none:
            return .screenDisplay
        }
    }

    var body: some View {
        VStack {
            Picker("Layout", selection: $selectedPreset) {
                ForEach(LayoutPreset.allCases, id: \.rawValue) { preset in
                    Text(preset.rawValue).tag(preset.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: layoutContext,
                        layoutConfiguration: layoutConfig
                    )
                    .id(selectedPreset)  // Force re-layout when preset changes
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func loadScore() async {
        do {
            _ = try SMuFLFontManager.shared.loadFont(named: "Bravura")
            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "File not found"
                isLoading = false
                return
            }
            score = try importer.importScore(from: url)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
