#if DEBUG
import SwiftUI
import SwiftData

enum ScreenshotScenario: String {
    case today, match, rig, chain, preview, paywall, gearsnap

    static var current: ScreenshotScenario? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-screenshotScenario"), index + 1 < args.count else { return nil }
        return ScreenshotScenario(rawValue: args[index + 1])
    }

    static var autoLightKnobs: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotAutoLight")
    }
}

struct ScreenshotRootView: View {
    let scenario: ScreenshotScenario
    @Environment(\.modelContext) private var modelContext
    @Query private var rigs: [Rig]
    @State private var didSeed = false

    private var featuredRecipe: ToneRecipe {
        ResourceStore.loadRecipes().first { $0.song == "Sweet Child O' Mine" }
            ?? ResourceStore.loadRecipes().first!
    }

    var body: some View {
        Group {
            if let rig = rigs.first {
                screen(rig: rig)
            } else {
                Color.tolex.ignoresSafeArea()
            }
        }
        .task { seed() }
    }

    @ViewBuilder
    private func screen(rig: Rig) -> some View {
        switch scenario {
        case .today:
            MainTabView()
        case .match:
            NavigationStack { MatchResultView(recipe: featuredRecipe) }
        case .rig:
            NavigationStack { RigView() }
        case .chain:
            NavigationStack { ChainCoachView(rig: rig) }
        case .preview:
            PreviewView(
                targetKnobs: featuredRecipe.baseKnobs,
                adaptedKnobs: ToneMatchEngine.adapt(recipe: featuredRecipe, rig: rig).knobs
            )
        case .paywall:
            PaywallView()
        case .gearsnap:
            GearSnapView { _ in }
        }
    }

    private func seed() {
        guard !didSeed else { return }
        didSeed = true
        UserDefaults.standard.set(true, forKey: "onboarded")
        UserDefaults.standard.set(0, forKey: "matchesToday")
        guard rigs.isEmpty else { return }

        let rig = Rig()
        rig.guitarBrand = "Gibson"
        rig.guitarModel = "Les Paul Standard '50s"
        rig.pickupType = .humbucker
        rig.ampBrand = "Marshall"
        rig.ampModel = "JCM800 2203"
        rig.ampFamily = .marshallMid
        rig.cabBrand = "Marshall"
        rig.cabModel = "1960A 4x12"
        rig.cabBrightness = 0.55
        rig.scene = .rehearsal
        rig.pedals = [
            GearItem(brand: "Dunlop", model: "Cry Baby GCB95", kind: .pedal, pickupType: nil, pedalFamily: .wah, ampFamily: nil, cabBrightness: nil),
            GearItem(brand: "Ibanez", model: "TS9 Tube Screamer", kind: .pedal, pickupType: nil, pedalFamily: .tubeScreamer, ampFamily: nil, cabBrightness: nil),
            GearItem(brand: "Electro-Harmonix", model: "Big Muff Pi", kind: .pedal, pickupType: nil, pedalFamily: .fuzz, ampFamily: nil, cabBrightness: nil),
            GearItem(brand: "Boss", model: "DD-8 Digital Delay", kind: .pedal, pickupType: nil, pedalFamily: .delay, ampFamily: nil, cabBrightness: nil)
        ]
        modelContext.insert(rig)
        try? modelContext.save()
    }
}
#endif
