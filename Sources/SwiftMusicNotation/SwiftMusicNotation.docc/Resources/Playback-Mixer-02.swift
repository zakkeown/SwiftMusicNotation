import SwiftUI
import SwiftMusicNotation

struct MixerView: View {
    let score: Score
    @ObservedObject var engine: PlaybackEngine

    // Track volume for each part
    @State private var partVolumes: [String: Float] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mixer")
                .font(.headline)

            ForEach(score.parts, id: \.id) { part in
                HStack(spacing: 12) {
                    // Part name
                    Text(part.name)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)

                    // Volume slider
                    Slider(
                        value: Binding(
                            get: { partVolumes[part.id] ?? 1.0 },
                            set: { newValue in
                                partVolumes[part.id] = newValue
                                engine.setVolume(newValue, forPart: part.id)
                            }
                        ),
                        in: 0...1
                    )

                    // Volume percentage
                    Text("\(Int((partVolumes[part.id] ?? 1.0) * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .onAppear {
            // Initialize all volumes to 100%
            for part in score.parts {
                partVolumes[part.id] = 1.0
            }
        }
    }
}

#Preview {
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
        .frame(width: 300)
}
