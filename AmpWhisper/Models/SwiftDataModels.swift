import Foundation
import SwiftData

@Model
final class Rig {
    var guitarBrand: String = "Fender"
    var guitarModel: String = "Player Stratocaster"
    var pickupTypeRaw: String = PickupType.singleCoil.rawValue
    var ampBrand: String = "Fender"
    var ampModel: String = "Hot Rod Deluxe"
    var ampFamilyRaw: String = AmpFamily.fenderClean.rawValue
    var cabBrand: String = ""
    var cabModel: String = ""
    var cabBrightness: Double = 0.8
    var pedalsJSON: Data = Data("[]".utf8)
    var sceneRaw: String = RigScene.bedroom.rawValue
    var isKnownGear: Bool = true
    var createdAt: Date = Date()

    init() {}

    var pickupType: PickupType {
        get { PickupType(rawValue: pickupTypeRaw) ?? .singleCoil }
        set { pickupTypeRaw = newValue.rawValue }
    }
    var ampFamily: AmpFamily {
        get { AmpFamily(rawValue: ampFamilyRaw) ?? .fenderClean }
        set { ampFamilyRaw = newValue.rawValue }
    }
    var scene: RigScene {
        get { RigScene(rawValue: sceneRaw) ?? .bedroom }
        set { sceneRaw = newValue.rawValue }
    }
    var pedals: [GearItem] {
        get { (try? JSONDecoder().decode([GearItem].self, from: pedalsJSON)) ?? [] }
        set { pedalsJSON = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8) }
    }
    var cabBacking: CabBacking { cabBrightness >= 0.7 ? .open : .closed }
    var summary: String { "\(guitarBrand) \(guitarModel) → \(ampBrand) \(ampModel)" }
}

enum CabBacking: String, Codable {
    case open, closed
}

@Model
final class MatchHistory {
    var songTitle: String = ""
    var artist: String = ""
    var knobsJSON: Data = Data()
    var adjustmentsJSON: Data = Data()
    var confidence: Double = 0
    var warningsJSON: Data = Data()
    var sceneRaw: String = RigScene.bedroom.rawValue
    var matchedAt: Date = Date()

    init(songTitle: String, artist: String, result: ToneMatchResult, scene: RigScene) {
        self.songTitle = songTitle
        self.artist = artist
        self.knobsJSON = (try? JSONEncoder().encode(result.knobs)) ?? Data()
        self.adjustmentsJSON = (try? JSONEncoder().encode(result.adjustments)) ?? Data()
        self.confidence = result.overallConfidence
        self.warningsJSON = (try? JSONEncoder().encode(result.warnings)) ?? Data()
        self.sceneRaw = scene.rawValue
    }

    var knobs: [String: Int] { (try? JSONDecoder().decode([String: Int].self, from: knobsJSON)) ?? [:] }
    var adjustments: [KnobAdjust] { (try? JSONDecoder().decode([KnobAdjust].self, from: adjustmentsJSON)) ?? [] }
    var warnings: [String] { (try? JSONDecoder().decode([String].self, from: warningsJSON)) ?? [] }
    var scene: RigScene { RigScene(rawValue: sceneRaw) ?? .bedroom }
}
