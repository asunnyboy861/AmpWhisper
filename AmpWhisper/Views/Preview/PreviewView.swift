import SwiftUI

struct PreviewView: View {
    let targetKnobs: [String: Int]
    let adaptedKnobs: [String: Int]
    @Environment(\.dismiss) private var dismiss
    @State private var isTarget = true
    @State private var isPlaying = false
    @State private var engine = AudioEngine()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("A/B Preview")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.cream)
                Text("Target tone vs your adapted tone — modeled approximation. Final result depends on your real gear.")
                    .font(.caption)
                    .foregroundStyle(Color.cream.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                knobComparison

                Picker("Track", selection: $isTarget) {
                    Text("A · Target").tag(true)
                    Text("B · Yours").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: isTarget) { _, newValue in
                    if isPlaying { startPlayback() }
                }

                Button {
                    if isPlaying {
                        engine.stop()
                        isPlaying = false
                    } else {
                        startPlayback()
                        isPlaying = true
                    }
                } label: {
                    Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "stop.fill" : "play.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .background(Color.tolex)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        engine.stop()
                        dismiss()
                    }
                }
            }
            .onDisappear { engine.stop() }
        }
    }

    private var knobComparison: some View {
        HStack(spacing: 18) {
            ForEach(AppConstants.knobOrder, id: \.self) { knob in
                let target = targetKnobs[knob] ?? 5
                let adapted = adaptedKnobs[knob] ?? 5
                let current = isTarget ? target : adapted
                VStack(spacing: 4) {
                    Text(AppConstants.knobLabels[knob] ?? knob)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.cream.opacity(0.7))
                    Text("\(current)")
                        .font(.title3.weight(.black))
                        .foregroundStyle(isTarget ? Color.cream : Color.amber)
                        .animation(.spring(duration: 0.3), value: isTarget)
                    Text("rec: \(target)")
                        .font(.caption2)
                        .foregroundStyle(Color.cream.opacity(0.4))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(AppConstants.knobLabels[knob] ?? knob) \(current) of 10, record \(target)")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tolexCard))
        .padding(.horizontal)
    }

    private func startPlayback() {
        let knobs = isTarget ? targetKnobs : adaptedKnobs
        try? engine.play(knobs: knobs)
    }
}
