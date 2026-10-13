import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboarded") private var onboarded = false
    @State private var step = 0
    @State private var showGearSnap = false
    @State private var rig = Rig()
    @State private var pickupChosen = false
    @State private var selectedRecipe: ToneRecipe?

    private let catalog = GearCatalog.shared

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: welcome
                case 1: rigSetup
                case 2: pickupPick
                default: songPick
                }
            }
            .background(Color.tolex)
            .navigationDestination(item: $selectedRecipe) { recipe in
                MatchResultView(recipe: recipe, isNewRig: true)
            }
        }
        .sheet(isPresented: $showGearSnap) {
            GearSnapView { item in
                applyGearItem(item)
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "guitars.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.amber)
            Text("Your amp has secrets.")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(Color.cream)
                .multilineTextAlignment(.center)
            Text("We whisper them. Photograph your gear, pick a song, and get every knob setting matched to YOUR rig.")
                .font(.body)
                .foregroundStyle(Color.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            Button {
                saveRig()
                onboarded = true
            } label: {
                Text("Explore first")
                    .font(.subheadline)
                    .foregroundStyle(Color.cream.opacity(0.6))
            }
            .padding(.bottom, 24)
        }
    }

    private var rigSetup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Build your rig")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.cream)
                Text("GearSnap reads your amp panel in about 5 seconds. Or pick manually — pedals are optional.")
                    .font(.subheadline)
                    .foregroundStyle(Color.cream.opacity(0.7))

                Button {
                    showGearSnap = true
                } label: {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GearSnap")
                                .font(.headline)
                            Text("Photograph your amp or headstock")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.tolexCard))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amber.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(Color.cream)
                }
                .buttonStyle(.plain)

                gearSection(title: "Amp", current: rig.ampModel.isEmpty ? "Not set" : "\(rig.ampBrand) \(rig.ampModel)") {
                    GearPickerSheet(kind: .amp) { item in
                        rig.ampBrand = item.brand
                        rig.ampModel = item.model
                        rig.ampFamily = item.ampFamily ?? .fenderClean
                    }
                }
                gearSection(title: "Guitar", current: "\(rig.guitarBrand) \(rig.guitarModel)") {
                    GearPickerSheet(kind: .guitar) { item in
                        rig.guitarBrand = item.brand
                        rig.guitarModel = item.model
                        rig.pickupType = item.pickupType ?? .singleCoil
                        pickupChosen = true
                    }
                }
                gearSection(title: "Cab (optional)", current: rig.cabModel.isEmpty ? "Not set" : "\(rig.cabBrand) \(rig.cabModel)") {
                    GearPickerSheet(kind: .cab) { item in
                        rig.cabBrand = item.brand
                        rig.cabModel = item.model
                        rig.cabBrightness = item.cabBrightness ?? 0.6
                    }
                }

                Button {
                    withAnimation { step = pickupChosen ? 2 : 1 }
                } label: {
                    Text("Continue")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
            }
            .padding()
        }
    }

    private func gearSection<Content: View>(title: String, current: String, @ViewBuilder picker: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.cream)
                Text(current)
                    .font(.caption)
                    .foregroundStyle(Color.cream.opacity(0.6))
            }
            Spacer()
            picker()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
    }

    private var pickupPick: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Which pickups are in your guitar?")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.cream)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                ForEach([PickupType.singleCoil, .humbucker], id: \.self) { type in
                    Button {
                        rig.pickupType = type
                        withAnimation { step = 3 }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type == .singleCoil ? "circle.grid.3x3" : "rectangle.roundedbottom")
                                .font(.system(size: 40))
                            Text(type == .singleCoil ? "Single Coil" : "Humbucker")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tolexCard))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.amber.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(Color.cream)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pickup type: \(type == .singleCoil ? "Single coil" : "Humbucker")")
                }
            }
            .padding(.horizontal, 24)
            Button("My guitar has P90s") {
                rig.pickupType = .p90
                withAnimation { step = 3 }
            }
            .font(.subheadline)
            .foregroundStyle(Color.cream.opacity(0.6))
            Spacer()
        }
    }

    private var songPick: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick a song to start")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.cream)
                Text("Tap any song to see the knob settings matched to your rig.")
                    .font(.subheadline)
                    .foregroundStyle(Color.cream.opacity(0.7))
                let picks = Array(ResourceStore.loadRecipes().prefix(12))
                ForEach(picks) { recipe in
                    Button {
                        saveRig()
                        selectedRecipe = recipe
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.song)
                                    .font(.headline)
                                    .foregroundStyle(Color.cream)
                                Text(recipe.artist)
                                    .font(.caption)
                                    .foregroundStyle(Color.cream.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.amber)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
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
            rig.pickupType = item.pickupType ?? .singleCoil
            pickupChosen = true
        case .cab:
            rig.cabBrand = item.brand
            rig.cabModel = item.model
            rig.cabBrightness = item.cabBrightness ?? 0.6
        case .pedal:
            rig.pedals.append(item)
        }
    }

    private func saveRig() {
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Rig>())) ?? 0
        guard existing == 0 else { return }
        modelContext.insert(rig)
        try? modelContext.save()
    }
}

struct GearPickerSheet: View {
    let kind: GearKind
    let onSelect: (GearItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var brand = ""
    @State private var model = ""
    @State private var search = ""
    @State private var customMode = false

    private let catalog = GearCatalog.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(catalog.brands(for: kind), id: \.self) { b in
                        DisclosureGroup {
                            ForEach(catalog.models(brand: b, kind: kind)) { item in
                                Button {
                                    onSelect(item)
                                    dismiss()
                                } label: {
                                    Text(item.model)
                                        .foregroundStyle(Color.primary)
                                }
                            }
                        } label: {
                            Text(b)
                        }
                    }
                } header: {
                    Text("Pick from library")
                } footer: {
                    Button(customMode ? "Browse library instead" : "Can't find it? Add manually") {
                        customMode.toggle()
                    }
                    .font(.footnote.weight(.semibold))
                }

                if customMode {
                    Section {
                        TextField("Brand", text: $brand)
                        TextField("Model", text: $model)
                        Button("Use this gear") {
                            var item = GearItem(brand: brand, model: model, kind: kind, pickupType: nil, pedalFamily: nil, ampFamily: nil, cabBrightness: nil)
                            if kind == .guitar { item.pickupType = .humbucker }
                            if kind == .amp { item.ampFamily = .marshallMid }
                            if kind == .cab { item.cabBrightness = 0.55 }
                            onSelect(item)
                            dismiss()
                        }
                        .disabled(brand.isEmpty || model.isEmpty)
                    } header: {
                        Text("Custom gear")
                    } footer: {
                        Text("Custom gear uses generic advice with an explicit confidence note.")
                    }
                }
            }
            .searchable(text: $search, prompt: "Search \(kind.rawValue)")
            .overlay {
                if !search.isEmpty {
                    searchResults
                }
            }
            .navigationTitle("Choose \(kind.rawValue.capitalized)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var searchResults: some View {
        List {
            ForEach(catalog.search(query: search).filter { $0.kind == kind }) { item in
                Button {
                    onSelect(item)
                    dismiss()
                } label: {
                    Text("\(item.brand) \(item.model)")
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }
}
