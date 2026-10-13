import SwiftUI

extension Color {
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.125)
    static let tolex = Color(red: 0.11, green: 0.106, blue: 0.102)
    static let cream = Color(red: 0.96, green: 0.937, blue: 0.878)
    static let tolexCard = Color(red: 0.16, green: 0.155, blue: 0.148)
}

struct AppTheme {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.tolexCard)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct KnobDial: View {
    let label: String
    @Binding var value: Int
    var isConfirmed: Bool = false
    var suggestedValue: Int
    var onConfirm: () -> Void = {}
    @State private var dragStartValue: Int?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.tolexCard)
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(isConfirmed ? Color.amber : Color.white.opacity(0.2), lineWidth: isConfirmed ? 3 : 1.5))
                    .shadow(color: isConfirmed ? Color.amber.opacity(0.5) : .clear, radius: 12)

                ForEach(0...10, id: \.self) { tick in
                    Capsule()
                        .fill(tick <= value ? Color.amber : Color.cream.opacity(0.25))
                        .frame(width: 2, height: tick % 5 == 0 ? 10 : 6)
                        .offset(y: -40)
                        .rotationEffect(.degrees(Double(tick) / 10.0 * 270 - 135))
                }

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.cream)
                    .frame(width: 4, height: 32)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(value) / 10.0 * 270 - 135))
                    .animation(.spring(duration: 0.3), value: value)

                Text("\(value)")
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundStyle(isConfirmed ? Color.amber : Color.cream)
            }
            .frame(width: 96, height: 96)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        let start = dragStartValue ?? value
                        if dragStartValue == nil { dragStartValue = value }
                        let vertical = -gesture.translation.height
                        let steps = Int((vertical / 18).rounded())
                        value = ToneMatchEngine.clamp(start + steps, 0, 10)
                    }
                    .onEnded { _ in dragStartValue = nil }
            )
            .onTapGesture { onConfirm() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label) \(value) of 10, suggested \(suggestedValue)")
            .accessibilityHint("Drag up or down to adjust. Tap to confirm the suggested value.")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: value = min(value + 1, 10)
                case .decrement: value = max(value - 1, 0)
                @unknown default: break
                }
            }

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cream.opacity(0.8))
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidence >= 0.75 ? "checkmark.seal.fill" : "info.circle.fill")
            Text("\(Int(confidence * 100))% confident")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(confidence >= 0.75 ? Color.amber : Color.cream.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.tolexCard))
        .accessibilityLabel("Overall confidence \(Int(confidence * 100)) percent")
    }
}

struct WhisperNoteCard: View {
    let adjustment: KnobAdjust
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundStyle(Color.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(AppConstants.knobLabels[adjustment.knob] ?? adjustment.knob) \(adjustment.delta >= 0 ? "+" : "")\(adjustment.delta)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cream)
                        Text(adjustment.reason)
                            .font(.caption)
                            .foregroundStyle(Color.cream.opacity(0.6))
                            .lineLimit(isExpanded ? nil : 1)
                    }
                    Spacer()
                    Text("\(Int(adjustment.confidence * 100))%")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.amber)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
        .accessibilityElement(children: .combine)
    }
}

struct ChainStrip: View {
    let pedals: [String]
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .foregroundStyle(Color.amber)
                Text("Pedal Chain")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.cream)
            }
            if pedals.isEmpty {
                Text("No pedals in your rig — straight into the amp.")
                    .font(.caption)
                    .foregroundStyle(Color.cream.opacity(0.55))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(pedals.enumerated()), id: \.offset) { index, pedal in
                            HStack(spacing: 4) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(Color.tolex)
                                    .padding(4)
                                    .background(Circle().fill(Color.amber))
                                Text(pedal)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.cream)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.tolexCard))
                        }
                    }
                }
            }
            ForEach(notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.caption)
                        .foregroundStyle(Color.amber)
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.cream.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
    }
}
