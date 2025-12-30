import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var loader = ScoreLoader()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        ScoreViewRepresentable(
            score: Binding(
                get: { loader.score },
                set: { loader.score = $0 }
            ),
            layoutContext: layoutContext
        )
    }
}
