import SwiftUI
import SwiftData

struct RigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rigs: [Rig]
    @State private var showGearSnap = false
    @State private var editingKind: GearKind?
    @State private var showChainCoach = false

    private var rig: Rig {
        rigs.first ?? {
            let newRig = Rig()
            modelContext.insert(newRig)
            return newRig
        }()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Scene") {
                    sceneCards
                }
                Section("Guitar") {
                    row("Guitar", value: "\(rig.guitarBrand) \(rig.guitarModel)", icon: "guitars") { editingKind = .guitar }
                    row("Pickups", value: rig.pickupType == .singleCoil ? "Single Coil" : rig.pickupType == .humbucker ? "Humbucker" : "P90", icon: "circle.grid.3x3") {
                        showPickupMenu = true
                    }
                }
                Section("Amp & Cab") {
                    row("Amp", value: rig.ampModel.isEmpty ? "Not set" : "\(rig.ampBrand) \(rig.ampModel)", icon: "hifispeaker.2") { editingKind = .amp }
                    row("Cab", value: rig.cabModel.isEmpty ? "Not set" : "\(rig.cabBrand) \(rig.cabModel)", icon: "rectangle.righthalf.filled") { editingKind = .cab }
                }
                Section("Pedals") {
                    ForEach(rig.pedals) { pedal in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pedal.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(pedal.pedalFamily?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Custom")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        rig.pedals.remove(atOffsets: offsets)
                        save()
                    }
                    row("Add Pedal", value: "\(rig.pedals.count) pedals", icon: "plus.circle.fill") { editingKind = .pedal }
                    row("Chain Coach", value: "Order + exceptions", icon: "link.badge.plus") { showChainCoach = true }
                }
                Section {
                    Button {
                        showGearSnap = true
                    } label: {
                        Label("GearSnap — photograph your gear", systemImage: "camera.viewfinder")
                            .font(.headline)
                            .foregroundStyle(Color.amber)
                    }
                } footer: {
                    Text("GearSnap recognizes amp panels, headstocks, and pedalboards. Changing any gear instantly re-adapts open recipes.")
                }
            }
            .navigationTitle("My Rig")
            .navigationDestination(isPresented: $showChainCoach) { ChainCoachView(rig: rig) }
            .sheet(isPresented: $showGearSnap) { GearSnapView { item in applyGearItem(item) } }
            .sheet(item: $editingKind) { kind in
                GearPickerSheet(kind: kind) { item in
                    applyGearItem(item)
                    save()
                }
            }
            .confirmationDialog("Pickup type", isPresented: $showPickupMenu, titleVisibility: .visible) {
                ForEach(PickupType.allCases, id: \.self) { type in
                    Button(type == .singleCoil ? "Single Coil" : type == .humbucker ? "Humbucker" : "P90") {
                        rig.pickupType = type
                        save()
                    }
                }
            }
        }
    }

    @State private var showPickupMenu = false

    private var sceneCards: some View {
        HStack(spacing: 10) {
            ForEach(RigScene.allCases, id: \.self) { scene in
                Button {
                    rig.scene = scene
                    save()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: sceneIcon(scene))
                            .font(.title3)
                        Text(sceneLabel(scene))
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(rig.scene == scene ? Color.amber.opacity(0.25) : Color.tolexCard))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(rig.scene == scene ? Color.amber : Color.clear, lineWidth: 2))
                    .foregroundStyle(Color.cream)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scene \(sceneLabel(scene))\(rig.scene == scene ? ", selected" : "")")
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    private func sceneIcon(_ scene: RigScene) -> String {
        switch scene {
        case .bedroom: return "bed.double.fill"
        case .rehearsal: return "music.mic"
        case .gig: return "music.note.2"
        }
    }

    private func sceneLabel(_ scene: RigScene) -> String {
        switch scene {
        case .bedroom: return "Bedroom"
        case .rehearsal: return "Rehearsal"
        case .gig: return "Gig"
        }
    }

    private func row(_ title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(Color.cream)
                Spacer()
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func applyGearItem(_ item: GearItem) {
        switch item.kind {
        case .amp:
            rig.ampBrand = item.brand
            rig.ampModel = item.model
            rig.ampFamily = item.ampFamily ?? .fenderClean
        case .guitar:
            rig.guitarBrand = item.brand
            rig.guitarModel = item.model
            rig.pickupType = item.pickupType ?? rig.pickupType
        case .cab:
            rig.cabBrand = item.brand
            rig.cabModel = item.model
            rig.cabBrightness = item.cabBrightness ?? 0.6
        case .pedal:
            rig.pedals.append(item)
        }
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}

extension GearKind: Identifiable {
    public var id: String { rawValue }
}

struct ChainCoachView: View {
    let rig: Rig
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let order = ChainOrderEngine.order(pedals: rig.pedals)
        List {
            Section {
                ForEach(Array(rig.pedals.enumerated()), id: \.element.id) { index, pedal in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color.tolex)
                            .padding(8)
                            .background(Circle().fill(Color.amber))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pedal.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text(pedal.pedalFamily?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Custom")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Suggested order (conventional)")
            } footer: {
                Text("Conventional order: Tuner → Filter → Comp → Gain → Mod → Time → Reverb. Drag pedals in your real rig if you use exceptions.")
            }
            Section("Why this order") {
                if order.exceptionNotes.isEmpty {
                    Text("No exception rules triggered — your chain follows the conventional order.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(order.exceptionNotes, id: \.self) { note in
                    Label(note, systemImage: "exclamationmark.bubble.fill")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Chain Coach")
    }
}
