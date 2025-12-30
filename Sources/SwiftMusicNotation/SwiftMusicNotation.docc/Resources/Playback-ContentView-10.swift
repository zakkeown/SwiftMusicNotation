import SwiftUI
import SwiftMusicNotation
import Combine

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    @State private var cancellables = Set<AnyCancellable>()
    @State private var highlightedMeasure: Int = 0
    @State private var showMixer = false

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    VStack(spacing: 0) {
                        // Score view
                        ScrollViewReader { proxy in
                            ScrollView([.horizontal, .vertical]) {
                                ZStack {
                                    ScoreViewRepresentable(
                                        score: .constant(score),
                                        layoutContext: layoutContext
                                    )

                                    if highlightedMeasure > 0 {
                                        MeasureHighlight(
                                            measureNumber: highlightedMeasure,
                                            totalMeasures: score.parts.first?.measures.count ?? 0
                                        )
                                    }
                                }
                            }
                        }

                        Divider()

                        // Control panel
                        HStack(alignment: .top, spacing: 20) {
                            // Playback controls
                            VStack {
                                PlaybackControls(
                                    engine: playbackEngine,
                                    totalMeasures: score.parts.first?.measures.count ?? 0
                                )

                                // Master volume
                                HStack {
                                    Image(systemName: "speaker.wave.3")
                                        .foregroundStyle(.secondary)
                                    Slider(value: $playbackEngine.masterVolume, in: 0...1)
                                        .frame(width: 100)
                                    Text("\(Int(playbackEngine.masterVolume * 100))%")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .frame(width: 40)
                                }
                            }

                            // Mixer (conditionally shown)
                            if showMixer {
                                Divider()

                                MixerView(score: score, engine: playbackEngine)
                                    .frame(width: 280)
                            }
                        }
                        .padding(.bottom)
                    }
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Score",
                        systemImage: "music.note",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle("Score Player")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            showMixer.toggle()
                        }
                    } label: {
                        Label("Mixer", systemImage: "slider.horizontal.3")
                    }
                }
            }
        }
        .task {
            await loadScore()
        }
        .onAppear {
            subscribeToPlaybackEvents()
        }
    }

    private func subscribeToPlaybackEvents() {
        playbackEngine.events
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .positionChanged(let measure, _):
                    highlightedMeasure = measure
                case .stopped:
                    highlightedMeasure = 0
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func loadScore() async {
        do {
            _ = try SMuFLFontManager.shared.loadFont(named: "Bravura")

            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "Sample file not found"
                isLoading = false
                return
            }
            let loadedScore = try importer.importScore(from: url)
            score = loadedScore
            isLoading = false

            try await playbackEngine.load(loadedScore)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
