import SwiftUI
import SwiftMusicNotation

struct MixerView: View {
    let score: Score
    @ObservedObject var engine: PlaybackEngine

    @State private var partVolumes: [String: Float] = [:]
    @State private var mutedParts: Set<String> = []
    @State private var soloedPart: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mixer")
                .font(.headline)

            ForEach(score.parts, id: \.id) { part in
                HStack(spacing: 8) {
                    // Mute button
                    Button {
                        toggleMute(part.id)
                    } label: {
                        Image(systemName: mutedParts.contains(part.id) ? "speaker.slash.fill" : "speaker.fill")
                            .foregroundStyle(mutedParts.contains(part.id) ? .red : .primary)
                    }
                    .buttonStyle(.borderless)

                    // Solo button
                    Button {
                        toggleSolo(part.id)
                    } label: {
                        Text("S")
                            .font(.caption.bold())
                            .foregroundStyle(soloedPart == part.id ? .yellow : .primary)
                    }
                    .buttonStyle(.bordered)
                    .tint(soloedPart == part.id ? .yellow : nil)

                    // Part name
                    Text(part.name)
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)
                        .foregroundStyle(isPartAudible(part.id) ? .primary : .secondary)

                    // Volume slider
                    Slider(
                        value: Binding(
                            get: { partVolumes[part.id] ?? 1.0 },
                            set: { newValue in
                                partVolumes[part.id] = newValue
                                updatePartVolume(part.id)
                            }
                        ),
                        in: 0...1
                    )
                    .disabled(!isPartAudible(part.id))

                    // Volume percentage
                    Text("\(Int((partVolumes[part.id] ?? 1.0) * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 35, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }

            Divider()

            // Reset button
            Button("Reset All") {
                resetMixer()
            }
            .font(.caption)
        }
        .padding()
        .onAppear {
            for part in score.parts {
                partVolumes[part.id] = 1.0
            }
        }
    }

    private func isPartAudible(_ partId: String) -> Bool {
        if let solo = soloedPart {
            return partId == solo
        }
        return !mutedParts.contains(partId)
    }

    private func toggleMute(_ partId: String) {
        if mutedParts.contains(partId) {
            mutedParts.remove(partId)
        } else {
            mutedParts.insert(partId)
        }
        engine.setMuted(!isPartAudible(partId), forPart: partId)
    }

    private func toggleSolo(_ partId: String) {
        if soloedPart == partId {
            soloedPart = nil
        } else {
            soloedPart = partId
        }
        // Update all parts
        for part in score.parts {
            engine.setMuted(!isPartAudible(part.id), forPart: part.id)
        }
    }

    private func updatePartVolume(_ partId: String) {
        let volume = partVolumes[partId] ?? 1.0
        engine.setVolume(volume, forPart: partId)
    }

    private func resetMixer() {
        mutedParts.removeAll()
        soloedPart = nil
        for part in score.parts {
            partVolumes[part.id] = 1.0
            engine.setVolume(1.0, forPart: part.id)
            engine.setMuted(false, forPart: part.id)
        }
    }
}
