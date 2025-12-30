import SwiftUI
import SwiftMusicNotation

/// A mixer view for controlling individual part volumes
struct MixerView: View {
    let score: Score
    @ObservedObject var engine: PlaybackEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mixer")
                .font(.headline)

            // List all parts
            ForEach(score.parts, id: \.id) { part in
                HStack {
                    // Part name
                    Text(part.name)
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

#Preview {
    // Create a mock score for preview
    let score = Score(
        metadata: ScoreMetadata(),
        parts: [
            Part(id: "P1", name: "Soprano"),
            Part(id: "P2", name: "Alto"),
            Part(id: "P3", name: "Tenor"),
            Part(id: "P4", name: "Bass")
        ]
    )

    return MixerView(score: score, engine: PlaybackEngine())
}
