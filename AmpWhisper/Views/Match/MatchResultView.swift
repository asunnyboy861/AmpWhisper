import SwiftUI
import SwiftData

@MainActor
final class MatchViewModel: ObservableObject {
    @Published var knobs: [String: Int] = [:]
    @Published var result: ToneMatchResult?
    @Published var confirmedKnobs: Set<String> = []
    @Published var showCelebration = false
    @Published var showPaywall = false
    @Published var quotaBlocked = false
    @Published var shareImage: UIImage?

    private(set) var recipe: ToneRecipe
    private var audioEngine = AudioEngine()

    init(recipe: ToneRecipe) {
        self.recipe = recipe
    }

    func compute(rig: Rig, quota: QuotaManager, purchase: PurchaseManager) {
        let entitled = purchase.isPro || purchase.hasBYOLifetime
        guard entitled || quota.canFullMatch else {
            quotaBlocked = true
            showPaywall = true
            knobs = recipe.baseKnobs
            return
        }
        if !entitled { quota.consumeMatch() }
        let adapted = ToneMatchEngine.adapt(recipe: recipe, rig: rig)
        result = adapted
        knobs = adapted.knobs
    }

    func confirm(_ knob: String) {
        guard let suggested = result?.knobs[knob] else { return }
        knobs[knob] = suggested
        confirmedKnobs.insert(knob)
        if confirmedKnobs.count == AppConstants.knobOrder.count {
            showCelebration = true
        }
    }

    var allLit: Bool { confirmedKnobs.count == AppConstants.knobOrder.count }

    func play(track: AudioEngine.Track) {
        try? audioEngine.play(knobs: track == .target ? recipe.baseKnobs : knobs)
    }

    func stopAudio() {
        audioEngine.stop()
    }

    func makeShareCard(rig: Rig) {
        guard let result else { return }
        let ampModel = rig.ampModel.isEmpty ? "my amp" : rig.ampModel
        shareImage = ShareCardRenderer.render(song: recipe.song, artist: recipe.artist, knobs: knobs, ampModel: ampModel, confidence: result.overallConfidence)
    }
}

struct MatchResultView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MatchViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @Query private var rigs: [Rig]
    @State private var showPreview = false
    @State private var showShare = false
    @State private var showCelebrationOverlay = false

    init(recipe: ToneRecipe, isNewRig: Bool = false) {
        _viewModel = StateObject(wrappedValue: MatchViewModel(recipe: recipe))
    }

    private var rig: Rig? { rigs.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                if viewModel.quotaBlocked {
                    quotaBanner
                } else if let result = viewModel.result {
                    knobGrid
                    ConfidenceBadge(confidence: result.overallConfidence)
                    ChainStrip(pedals: result.chain, notes: result.warnings)
                    previewButton
                    whisperNotes(result)
                }
            }
            .padding()
        }
        .background(Color.tolex)
        .navigationTitle("ToneMatch")
        .navigationBarTitleDisplayMode(.inline)
        .overlay { celebrationOverlay }
        .sheet(isPresented: $showPreview) {
            PreviewView(targetKnobs: viewModel.recipe.baseKnobs, adaptedKnobs: viewModel.knobs)
        }
        .sheet(isPresented: $showShare, content: shareSheet)
        .onAppear { compute() }
        .onDisappear { viewModel.stopAudio() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.recipe.song)
                .font(.title.weight(.black))
                .foregroundStyle(Color.cream)
            Text(viewModel.recipe.artist)
                .font(.subheadline)
                .foregroundStyle(Color.cream.opacity(0.6))
            Text("Source: \(viewModel.recipe.source)")
                .font(.caption2)
                .foregroundStyle(Color.cream.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quotaBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(Color.amber)
            Text("You've used today's free match")
                .font(.headline)
                .foregroundStyle(Color.cream)
            Text("Come back tomorrow for another free match, or go Pro for unlimited.")
                .font(.caption)
                .foregroundStyle(Color.cream.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tolexCard))
    }

    private var knobGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
            ForEach(AppConstants.knobOrder, id: \.self) { knob in
                let suggested = viewModel.result?.knobs[knob] ?? 5
                KnobDial(
                    label: AppConstants.knobLabels[knob] ?? knob,
                    value: binding(for: knob),
                    isConfirmed: viewModel.confirmedKnobs.contains(knob),
                    suggestedValue: suggested,
                    onConfirm: { viewModel.confirm(knob) }
                )
            }
        }
        .padding(.vertical, 8)
    }

    private func binding(for knob: String) -> Binding<Int> {
        Binding(
            get: { viewModel.knobs[knob] ?? 5 },
            set: { viewModel.knobs[knob] = $0 }
        )
    }

    private var previewButton: some View {
        Button {
            showPreview = true
        } label: {
            Label("Hear it before you turn it", systemImage: "play.circle.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
    }

    private func whisperNotes(_ result: ToneMatchResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Whisper Notes")
                .font(.headline)
                .foregroundStyle(Color.cream)
            if result.adjustments.isEmpty {
                Text("Your rig already matches the record's setup — no conversions needed.")
                    .font(.caption)
                    .foregroundStyle(Color.cream.opacity(0.6))
            }
            ForEach(result.adjustments, id: \.self) { adjustment in
                WhisperNoteCard(adjustment: adjustment)
            }
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if viewModel.showCelebration {
            ZStack {
                Color.black.opacity(0.75).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Dialed In ✅")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.amber)
                    Text("Every knob confirmed. Share your tone.")
                        .font(.subheadline)
                        .foregroundStyle(Color.cream.opacity(0.8))
                    HStack(spacing: 12) {
                        Button {
                            viewModel.makeShareCard(rig: rig ?? Rig())
                            showShare = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Done") {
                            viewModel.showCelebration = false
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(Color.cream)
                    }
                }
                .padding(32)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.tolexCard))
                .padding(40)
            }
            .transition(.opacity)
        }
    }

    private func shareSheet() -> some View {
        VStack {
            if let image = viewModel.shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func compute() {
        guard let rig else { return }
        viewModel.compute(rig: rig, quota: quotaManager, purchase: purchaseManager)
        saveHistory()
    }

    private func saveHistory() {
        guard let result = viewModel.result, let rig else { return }
        modelContext.insert(MatchHistory(songTitle: viewModel.recipe.song, artist: viewModel.recipe.artist, result: result, scene: rig.scene))
        try? modelContext.save()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
