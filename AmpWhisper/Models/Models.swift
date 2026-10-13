import Foundation

enum GearKind: String, Codable, CaseIterable, Hashable {
    case guitar, amp, cab, pedal
}

enum PickupType: String, Codable, CaseIterable, Hashable {
    case singleCoil, humbucker, p90
}

enum PedalFamily: String, Codable, CaseIterable, Hashable {
    case tubeScreamer, transparent, fuzz, compressor, wah, delay, reverb, modulation
}

enum AmpFamily: String, Codable, CaseIterable, Hashable {
    case fenderClean, marshallMid, voxChime, highGainModern
}

enum RigScene: String, Codable, CaseIterable, Hashable {
    case bedroom, rehearsal, gig
}

struct GearItem: Codable, Hashable, Identifiable {
    var id: String { "\(brand)-\(model)-\(kind.rawValue)" }
    var brand: String
    var model: String
    var kind: GearKind
    var pickupType: PickupType?
    var pedalFamily: PedalFamily?
    var ampFamily: AmpFamily?
    var cabBrightness: Double?

    var displayName: String { "\(brand) \(model)" }
}

struct DeviceLibrary: Codable {
    var devices: [GearItem]
}

struct KnobAdjust: Codable, Hashable {
    var knob: String
    var delta: Int
    var reason: String
    var confidence: Double
}

struct ToneMatchResult: Codable, Hashable {
    var knobs: [String: Int]
    var chain: [String]
    var adjustments: [KnobAdjust]
    var overallConfidence: Double
    var warnings: [String]
}

struct ToneRecipe: Codable, Hashable, Identifiable {
    var id: String
    var song: String
    var artist: String
    var genre: String
    var baseKnobs: [String: Int]
    var guitarPickup: String
    var ampFamily: String
    var cabBrightness: Double
    var pedalFamilies: [String]
    var source: String
    var isWeeklyDrop: Bool

    var targetAmpFamily: AmpFamily? { AmpFamily(rawValue: ampFamily) }
    var targetPickup: PickupType? { PickupType(rawValue: guitarPickup) }
    var targetPedalFamilies: [PedalFamily] { pedalFamilies.compactMap { PedalFamily(rawValue: $0) } }
}

struct GearCandidates: Codable, Hashable {
    struct Candidate: Codable, Hashable, Identifiable {
        var id: String { "\(brand)-\(model)" }
        var brand: String
        var model: String
        var confidence: Double
    }
    var candidates: [Candidate]
    var sourceEngine: String
}

struct RecipeEnvelope: Codable {
    var recipes: [ToneRecipe]
}

enum AppConstants {
    static let knobOrder = ["gain", "treble", "middle", "bass", "presence", "level"]
    static let knobLabels: [String: String] = [
        "gain": "Gain", "treble": "Treble", "middle": "Middle",
        "bass": "Bass", "presence": "Presence", "level": "Level"
    ]
    static let freeMatchesPerDay = 1
    static let freeFMRecognitionsPerDay = 5
    static let paywallPrivacyURL = URL(string: "https://asunnyboy861.github.io/AmpWhisper/privacy.html")!
    static let paywallTermsURL = URL(string: "https://asunnyboy861.github.io/AmpWhisper/terms.html")!
    static let supportURL = URL(string: "https://asunnyboy861.github.io/AmpWhisper/support.html")!
}
