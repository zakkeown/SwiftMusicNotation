import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var loader = ScoreLoader()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        Group {
            if loader.isLoading {
                ProgressView("Loading score...")
            } else if let error = loader.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error.localizedDescription)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loader.loadScore(named: "MySong")
                    }
                }
                .padding()
            } else if loader.score != nil {
                ScoreViewRepresentable(
                    score: Binding(
                        get: { loader.score },
                        set: { loader.score = $0 }
                    ),
                    layoutContext: layoutContext
                )
            } else {
                Text("No score loaded")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            loader.loadScore(named: "MySong")
        }
    }
}
