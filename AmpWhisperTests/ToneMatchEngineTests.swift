import Testing
import Foundation
@testable import AmpWhisper

@Suite("ToneMatchEngine")
struct ToneMatchEngineTests {

    private let tables = RuleTableStore.load()

    private func makeRecipe(pickup: PickupType = .humbucker, amp: AmpFamily = .marshallMid, cab: Double = 0.55, pedals: [PedalFamily] = []) -> ToneRecipe {
        ToneRecipe(
            id: "test", song: "Test", artist: "Artist", genre: "classic_rock",
            baseKnobs: ["gain": 6, "treble": 6, "middle": 5, "bass": 5, "presence": 6, "level": 6],
            guitarPickup: pickup.rawValue, ampFamily: amp.rawValue, cabBrightness: cab,
            pedalFamilies: pedals.map(\.rawValue), source: "test", isWeeklyDrop: false
        )
    }

    private func makeRig(pickup: PickupType, amp: AmpFamily, cab: Double? = nil, pedals: [GearItem] = [], known: Bool = true, scene: RigScene = .rehearsal) -> Rig {
        let rig = Rig()
        rig.pickupType = pickup
        rig.ampFamily = amp
        if let cab {
            rig.cabBrand = "Test"
            rig.cabModel = "Test Cab"
            rig.cabBrightness = cab
        }
        rig.pedals = pedals
        rig.isKnownGear = known
        rig.scene = scene
        return rig
    }

    @Test("Humbucker to single coil: gain -1 treble +1")
    func humbuckerToSingleCoil() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(pickup: .humbucker), rig: makeRig(pickup: .singleCoil, amp: .marshallMid), tables: tables)
        #expect(result.knobs["gain"] == 5)
        #expect(result.knobs["treble"] == 7)
    }

    @Test("Single coil to humbucker: gain +1 treble -1")
    func singleCoilToHumbucker() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(pickup: .singleCoil, amp: .fenderClean), rig: makeRig(pickup: .humbucker, amp: .fenderClean), tables: tables)
        #expect(result.knobs["gain"] == 7)
        #expect(result.knobs["treble"] == 5)
    }

    @Test("TS to transparent: gain +1 middle -2")
    func tsToTransparent() {
        let recipe = makeRecipe(pedals: [.tubeScreamer])
        let pedal = GearItem(brand: "Klon", model: "KTR", kind: .pedal, pickupType: nil, pedalFamily: .transparent, ampFamily: nil, cabBrightness: nil)
        let result = ToneMatchEngine.adapt(recipe: recipe, rig: makeRig(pickup: .humbucker, amp: .marshallMid, pedals: [pedal]), tables: tables)
        #expect(result.knobs["gain"] == 7)
        #expect(result.knobs["middle"] == 3)
    }

    @Test("Marshall to Fender family: bass +1 middle -1 gain +1")
    func marshallToFender() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(amp: .marshallMid), rig: makeRig(pickup: .humbucker, amp: .fenderClean), tables: tables)
        #expect(result.knobs["bass"] == 6)
        #expect(result.knobs["middle"] == 4)
        #expect(result.knobs["gain"] == 7)
    }

    @Test("Cab brightness compensation adds presence then backing rule adjusts")
    func cabBrightnessCompensation() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(cab: 0.9), rig: makeRig(pickup: .humbucker, amp: .marshallMid, cab: 0.3), tables: tables)
        #expect(result.knobs["presence"] == 7)
        #expect(result.adjustments.contains { $0.knob == "presence" && $0.delta == 2 })
        #expect(result.adjustments.contains { $0.knob == "presence" && $0.delta == -1 })
    }

    @Test("Unknown gear produces warning and lower confidence")
    func unknownGearWarns() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(), rig: makeRig(pickup: .humbucker, amp: .marshallMid, known: false), tables: tables)
        #expect(result.warnings.contains { $0.contains("generic starting points") })
        #expect(result.overallConfidence <= 0.9)
    }

    @Test("Knob values never leave 0-10")
    func knobClamping() {
        let result = ToneMatchEngine.adapt(recipe: makeRecipe(amp: .fenderClean, cab: 0.9), rig: makeRig(pickup: .singleCoil, amp: .fenderClean, cab: 0.1), tables: tables)
        for (_, value) in result.knobs {
            #expect((0...10).contains(value))
        }
    }

    @Test("Scene strategy applies level delta for gig")
    func sceneStrategy() {
        let baseline = ToneMatchEngine.adapt(recipe: makeRecipe(), rig: makeRig(pickup: .humbucker, amp: .marshallMid, scene: .rehearsal), tables: tables)
        let gig = ToneMatchEngine.adapt(recipe: makeRecipe(), rig: makeRig(pickup: .humbucker, amp: .marshallMid, scene: .gig), tables: tables)
        #expect(gig.knobs["level"] == 8)
        #expect(gig.knobs["bass"] == baseline.knobs["bass"]! - 1)
    }
}

@Suite("ChainOrderEngine")
struct ChainOrderEngineTests {

    private let tables = RuleTableStore.load()

    private func pedal(_ family: PedalFamily, model: String) -> GearItem {
        GearItem(brand: "Test", model: model, kind: .pedal, pickupType: nil, pedalFamily: family, ampFamily: nil, cabBrightness: nil)
    }

    @Test("Conventional order sorts compressor before gain before time")
    func conventionalOrder() {
        let pedals = [pedal(.delay, model: "Delay"), pedal(.tubeScreamer, model: "TS9"), pedal(.compressor, model: "Comp")]
        let result = ChainOrderEngine.order(pedals: pedals, tables: tables)
        #expect(result.names == ["Comp", "TS9", "Delay"])
    }

    @Test("Fuzz plus wah triggers exception note")
    func fuzzWahException() {
        let pedals = [pedal(.wah, model: "Cry Baby"), pedal(.fuzz, model: "Big Muff")]
        let result = ChainOrderEngine.order(pedals: pedals, tables: tables)
        #expect(result.names == ["Cry Baby", "Big Muff"])
        #expect(result.exceptionNotes.contains { $0.contains("Fuzz goes before wah") })
    }

    @Test("Empty pedals yields empty chain without crash")
    func emptyChain() {
        let result = ChainOrderEngine.order(pedals: [], tables: tables)
        #expect(result.names.isEmpty)
        #expect(result.exceptionNotes.isEmpty)
    }
}
