import SwiftUI
import SwiftMusicNotation

struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine

    var body: some View {
        VStack(spacing: 12) {
            // Transport controls
            HStack(spacing: 16) {
                Button {
                    try? engine.previousMeasure()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                }
                .disabled(!engine.isLoaded)

                Button {
                    engine.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(engine.state == .stopped)

                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                .disabled(!engine.isLoaded)
                .buttonStyle(.borderedProminent)

                Button {
                    try? engine.nextMeasure()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                }
                .disabled(!engine.isLoaded)
            }

            // Tempo control
            HStack {
                Image(systemName: "metronome")
                    .foregroundStyle(.secondary)

                Slider(value: $engine.tempo, in: 40...240, step: 1)
                    .frame(width: 150)
                    .disabled(!engine.isLoaded)

                Text("\(Int(engine.tempo)) BPM")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
    }

    private func togglePlayback() {
        do {
            if engine.state == .playing {
                engine.pause()
            } else {
                try engine.play()
            }
        } catch {
            print("Playback error: \(error)")
        }
    }
}

#Preview {
    PlaybackControls(engine: PlaybackEngine())
}
