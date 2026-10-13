import Foundation

struct RuleTableAdjust: Codable {
    var knob: String
    var delta: Int
    var reason: String
    var confidence: Double
}

struct AdaptationRule: Codable {
    var id: String
    var level: Int
    var from: String
    var to: String
    var adjusts: [RuleTableAdjust]
}

struct SceneStrategy: Codable {
    var knob: String
    var delta: Int
    var reason: String
    var confidence: Double
}

struct ChainException: Codable {
    var condition: String
    var note: String
}

struct RuleTables: Codable {
    var rules: [AdaptationRule]
    var sceneStrategies: [String: [SceneStrategy]]
    var chainOrder: ChainOrderConfig

    struct ChainOrderConfig: Codable {
        var conventional: [String]
        var exceptions: [ChainException]
    }
}

enum RuleTableStore {
    static func load() -> RuleTables {
        guard let url = Bundle.main.url(forResource: "RuleTables", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tables = try? JSONDecoder().decode(RuleTables.self, from: data) else {
            return RuleTables(rules: [], sceneStrategies: [:], chainOrder: .init(conventional: [], exceptions: []))
        }
        return tables
    }
}

enum ToneMatchEngine {

    static func adapt(recipe: ToneRecipe, rig: Rig, tables: RuleTables = RuleTableStore.load()) -> ToneMatchResult {
        var knobs = recipe.baseKnobs
        var adjusts: [KnobAdjust] = []
        var warnings: [String] = []

        let recipeBacking: CabBacking = recipe.cabBrightness >= 0.7 ? .open : .closed

        if let target = recipe.targetPickup, target != rig.pickupType {
            let matched = rulesFor(level: 1, from: target.rawValue, to: rig.pickupType.rawValue, tables: tables)
            if matched.isEmpty {
                warnings.append("Pickup difference \(target.rawValue) → \(rig.pickupType.rawValue): showing generic advice")
            }
            adjusts += matched.map { KnobAdjust(knob: $0.knob, delta: $0.delta, reason: $0.reason, confidence: $0.confidence) }
        }

        let userPedals = rig.pedals
        let targetFamilies = recipe.targetPedalFamilies
        for (slot, family) in targetFamilies.enumerated() {
            guard slot < userPedals.count, let userFamily = userPedals[slot].pedalFamily else { continue }
            if userFamily != family {
                let matched = rulesFor(level: 2, from: family.rawValue, to: userFamily.rawValue, tables: tables)
                if matched.isEmpty {
                    warnings.append("Your \(userPedals[slot].model) differs from the record's \(family.rawValue) pedal — using generic advice")
                } else {
                    adjusts += matched.map { KnobAdjust(knob: $0.knob, delta: $0.delta, reason: $0.reason, confidence: $0.confidence) }
                }
            }
        }
        if userPedals.count > targetFamilies.count {
            warnings.append("You run more pedals than the record — check Chain Coach for ordering")
        }

        if let userBrightness = rigBrightness(rig), abs(recipe.cabBrightness - userBrightness) > 0.05 {
            let d = clamp(Int(((recipe.cabBrightness - userBrightness) * 4).rounded()), -4, 4)
            if d != 0 {
                let reason = d > 0 ? "Your cab is darker than the record's — compensating Presence" : "Your cab is brighter than the record's — easing Presence"
                adjusts.append(KnobAdjust(knob: "presence", delta: d, reason: reason, confidence: 0.7))
            }
            let backingMatched = rulesFor(level: 3, from: recipeBacking.rawValue, to: rig.cabBacking.rawValue, tables: tables)
            adjusts += backingMatched.map { KnobAdjust(knob: $0.knob, delta: $0.delta, reason: $0.reason, confidence: $0.confidence) }
        }

        if let targetFamily = recipe.targetAmpFamily, targetFamily != rig.ampFamily {
            let matched = rulesFor(level: 4, from: targetFamily.rawValue, to: rig.ampFamily.rawValue, tables: tables)
            if matched.isEmpty {
                warnings.append("Amp family difference \(targetFamily.rawValue) → \(rig.ampFamily.rawValue): showing generic advice")
            }
            adjusts += matched.map { KnobAdjust(knob: $0.knob, delta: $0.delta, reason: $0.reason, confidence: $0.confidence) }
        }

        if let sceneDeltas = tables.sceneStrategies[rig.scene.rawValue] {
            adjusts += sceneDeltas.map { KnobAdjust(knob: $0.knob, delta: $0.delta, reason: $0.reason, confidence: $0.confidence) }
        }

        if !rig.isKnownGear {
            warnings.append("Your gear is outside the verified library — these are generic starting points")
        }

        for a in adjusts {
            knobs[a.knob, default: 5] = clamp((knobs[a.knob, default: 5]) + a.delta, 0, 10)
        }

        let conf: Double
        if adjusts.isEmpty {
            conf = rig.isKnownGear ? 0.9 : 0.5
        } else {
            conf = adjusts.map(\.confidence).min() ?? 0.5
        }

        let chain = ChainOrderEngine.order(pedals: userPedals, tables: tables).names
        let notes = ChainOrderEngine.order(pedals: userPedals, tables: tables).exceptionNotes

        return ToneMatchResult(knobs: knobs, chain: chain, adjustments: adjusts, overallConfidence: conf, warnings: warnings + notes)
    }

    private static func rigBrightness(_ rig: Rig) -> Double? {
        rig.cabBrand.isEmpty ? nil : rig.cabBrightness
    }

    private static func rulesFor(level: Int, from: String, to: String, tables: RuleTables) -> [RuleTableAdjust] {
        tables.rules
            .filter { $0.level == level && $0.from == from && $0.to == to }
            .flatMap(\.adjusts)
    }

    static func clamp(_ value: Int, _ low: Int, _ high: Int) -> Int {
        min(max(value, low), high)
    }
}

enum ChainOrderEngine {

    struct OrderResult {
        var names: [String]
        var exceptionNotes: [String]
    }

    static func order(pedals: [GearItem], tables: RuleTables = RuleTableStore.load()) -> OrderResult {
        let conventional = tables.chainOrder.conventional
        let rank: [PedalFamily: Int] = Dictionary(uniqueKeysWithValues: conventional.enumerated().map { (PedalFamily(rawValue: $1) ?? .transparent, $0) })
        let sorted = pedals.sorted {
            (rank[$0.pedalFamily ?? .transparent] ?? conventional.count) < (rank[$1.pedalFamily ?? .transparent] ?? conventional.count)
        }
        var notes: [String] = []
        let families = Set(pedals.compactMap(\.pedalFamily))
        for exception in tables.chainOrder.exceptions {
            let parts = exception.condition.split(separator: "+").map(String.init)
            if parts.count == 2, families.contains(PedalFamily(rawValue: parts[0]) ?? .transparent), families.contains(PedalFamily(rawValue: parts[1]) ?? .transparent) {
                notes.append(exception.note)
            }
        }
        return OrderResult(names: sorted.map(\.model), exceptionNotes: notes)
    }
}
