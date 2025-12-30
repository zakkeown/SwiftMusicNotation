import SwiftUI
import SwiftMusicNotation

/// A visual highlight overlay for the current playback measure with animation
struct MeasureHighlight: View {
    let measureNumber: Int
    let totalMeasures: Int

    let measureWidth: CGFloat = 100
    let measuresPerSystem: Int = 4

    // Track previous position for animation
    @State private var displayedMeasure: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let systemIndex = (displayedMeasure - 1) / measuresPerSystem
            let measureInSystem = (displayedMeasure - 1) % measuresPerSystem

            let xOffset = CGFloat(measureInSystem) * measureWidth + 50
            let yOffset = CGFloat(systemIndex) * 120 + 60

            ZStack {
                // Highlight rectangle
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: measureWidth - 4, height: 76)

                // Border with glow effect
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: measureWidth - 4, height: 76)
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            }
            .position(x: xOffset + measureWidth / 2, y: yOffset + 40)
            // Animate position changes
            .animation(.easeInOut(duration: 0.15), value: displayedMeasure)
        }
        .allowsHitTesting(false)
        .onChange(of: measureNumber) { _, newValue in
            displayedMeasure = newValue
        }
        .onAppear {
            displayedMeasure = measureNumber
        }
    }
}

/// A beat indicator that shows position within the measure
struct BeatIndicator: View {
    let beat: Double
    let beatsPerMeasure: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...beatsPerMeasure, id: \.self) { beatNum in
                Circle()
                    .fill(beatNum == Int(beat) ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(beatNum == Int(beat) ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: beat)
            }
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        MeasureHighlight(measureNumber: 3, totalMeasures: 16)
            .frame(width: 500, height: 300)
            .background(Color.gray.opacity(0.1))

        BeatIndicator(beat: 2.0, beatsPerMeasure: 4)
    }
}
