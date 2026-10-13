import SwiftUI
import PhotosUI

@MainActor
final class GearSnapViewModel: ObservableObject {
    @Published var state: State = .idle
    @Published var captureMode = 0

    enum State {
        case idle
        case scanning
        case result(GearCandidates)
        case failed(String)
    }

    let modes = ["Headstock", "Amp Panel", "Pedalboard"]

    func process(imageData: Data, purchase: PurchaseManager, quota: QuotaManager) async {
        state = .scanning
        do {
            let service = try AIRouter.recognitionService(purchase: purchase, quota: quota)
            let candidates = try await service.recognize(jpegData: imageData)
            state = candidates.candidates.isEmpty ? .failed("No match found. Pick manually below.") : .result(candidates)
        } catch let error as AIError {
            state = .failed(error.errorDescription ?? "Recognition failed")
        } catch {
            state = .failed("Recognition failed. Pick manually below.")
        }
    }
}

struct GearSnapView: View {
    let onConfirm: (GearItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GearSnapViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showManualPicker = false
    @State private var manualKind = GearKind.amp

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Capture mode", selection: $viewModel.captureMode) {
                    ForEach(0..<viewModel.modes.count, id: \.self) { Text(viewModel.modes[$0]) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                viewfinder

                switch viewModel.state {
                case .idle:
                    Text("Photograph your \(viewModel.modes[viewModel.captureMode].lowercased()). Recognition runs on-device or in the cloud depending on your plan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                case .scanning:
                    scanningShimmer
                case .result(let candidates):
                    candidateCards(candidates)
                case .failed(let message):
                    VStack(spacing: 8) {
                        Text(message)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                        Button("Pick manually instead") {
                            manualKind = viewModel.modes[viewModel.captureMode].contains("Amp") ? .amp : .guitar
                            showManualPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(.headline.weight(.semibold))
                }
                .buttonStyle(.bordered)

                Button("Pick manually instead") {
                    showManualPicker = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical)
            .navigationTitle("GearSnap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showManualPicker) {
                GearPickerSheet(kind: manualKind) { item in
                    onConfirm(item)
                    dismiss()
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { imageData in
                    Task {
                        await viewModel.process(imageData: imageData, purchase: purchaseManager, quota: quotaManager)
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await viewModel.process(imageData: data, purchase: purchaseManager, quota: quotaManager)
                    }
                }
                selectedPhoto = nil
            }
        }
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(height: 240)
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(Color.amber.opacity(0.6))
            VStack {
                Spacer()
                Text("Photograph your \(viewModel.modes[viewModel.captureMode].lowercased()) for the best match")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal)
    }

    private var scanningShimmer: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.amber)
                .symbolEffect(.pulse)
            Text("Scanning…")
                .font(.caption.weight(.semibold))
        }
        .padding()
        .accessibilityLabel("Scanning photo for gear")
    }

    private func candidateCards(_ candidates: GearCandidates) -> some View {
        VStack(spacing: 8) {
            Text("Top candidates — \(candidates.sourceEngine)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(candidates.candidates) { candidate in
                Button {
                    let kind: GearKind = viewModel.modes[viewModel.captureMode].contains("Amp") ? .amp : (viewModel.modes[viewModel.captureMode].contains("Pedal") ? .pedal : .guitar)
                    var item = GearItem(brand: candidate.brand, model: candidate.model, kind: kind, pickupType: nil, pedalFamily: nil, ampFamily: nil, cabBrightness: nil)
                    if kind == .amp { item.ampFamily = .marshallMid }
                    if kind == .guitar { item.pickupType = .humbucker }
                    if kind == .cab { item.cabBrightness = 0.55 }
                    onConfirm(item)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(candidate.brand) \(candidate.model)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("\(Int(candidate.confidence * 100))% confident")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if candidate.confidence >= 0.85 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.amber)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                }
                .buttonStyle(.plain)
            }
            Text("None of these? Pick manually — you're never stuck.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}
