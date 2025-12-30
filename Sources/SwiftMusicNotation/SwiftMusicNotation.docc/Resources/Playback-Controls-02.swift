import SwiftUI
import SwiftMusicNotation

struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine

    var body: some View {
        HStack(spacing: 16) {
            // Previous measure button
            Button {
                try? engine.previousMeasure()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title3)
            }
            .disabled(!engine.isLoaded)

            // Stop button
            Button {
                engine.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
            }
            .disabled(engine.state == .stopped)

            // Play/Pause button
            Button {
                togglePlayback()
            } label: {
                Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            .disabled(!engine.isLoaded)
            .buttonStyle(.borderedProminent)

            // Next measure button
            Button {
                try? engine.nextMeasure()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title3)
            }
            .disabled(!engine.isLoaded)
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
