import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var loader = ScoreLoader()
    @State private var zoomLevel: CGFloat = 1.0
    @State private var selectedElements: [SelectableElement] = []

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
                    zoomLevel: $zoomLevel,
                    selectedElements: $selectedElements,
                    layoutContext: layoutContext,
                    onElementTapped: { element in
                        print("Tapped: \(element.elementType)")
                    },
                    onElementDoubleTapped: { element in
                        print("Double-tapped: \(element.elementType)")
                    },
                    onEmptySpaceTapped: {
                        selectedElements.removeAll()
                    }
                )
            } else {
                Text("No score loaded")
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    zoomLevel = max(0.25, zoomLevel / 1.25)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }

                Text("\(Int(zoomLevel * 100))%")
                    .monospacedDigit()
                    .frame(width: 50)

                Button {
                    zoomLevel = min(4.0, zoomLevel * 1.25)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
        }
        .task {
            loader.loadScore(named: "MySong")
        }
    }
}
