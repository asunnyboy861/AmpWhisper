import Foundation

@MainActor
final class QuotaManager: ObservableObject {
    static let shared = QuotaManager()

    @Published private(set) var matchesToday: Int
    @Published private(set) var fmRecognitionsToday: Int
    @Published private(set) var glmTrialUsed: Bool

    private let defaults: UserDefaults
    private enum Key: String {
        case lastMatchDate, matchesToday, lastFMDate, fmRecognitionsToday, glmTrialUsed
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        matchesToday = 0
        fmRecognitionsToday = 0
        glmTrialUsed = false
        rollDateIfNeeded()
        matchesToday = defaults.integer(forKey: Key.matchesToday.rawValue)
        fmRecognitionsToday = defaults.integer(forKey: Key.fmRecognitionsToday.rawValue)
        glmTrialUsed = defaults.bool(forKey: Key.glmTrialUsed.rawValue)
    }

    private func rollDateIfNeeded() {
        let today = Self.dayString(Date())
        if defaults.string(forKey: Key.lastMatchDate.rawValue) != today {
            defaults.set(today, forKey: Key.lastMatchDate.rawValue)
            defaults.set(0, forKey: Key.matchesToday.rawValue)
        }
        if defaults.string(forKey: Key.lastFMDate.rawValue) != today {
            defaults.set(today, forKey: Key.lastFMDate.rawValue)
            defaults.set(0, forKey: Key.fmRecognitionsToday.rawValue)
        }
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var canFullMatch: Bool { matchesToday < AppConstants.freeMatchesPerDay }

    func consumeMatch() {
        rollDateIfNeeded()
        matchesToday += 1
        defaults.set(matchesToday, forKey: Key.matchesToday.rawValue)
    }

    var canRoughRecognize: Bool { fmRecognitionsToday < AppConstants.freeFMRecognitionsPerDay }

    func consumeFMRecognition() {
        rollDateIfNeeded()
        fmRecognitionsToday += 1
        defaults.set(fmRecognitionsToday, forKey: Key.fmRecognitionsToday.rawValue)
    }

    var glmTrialAvailable: Bool { !glmTrialUsed }

    func consumeGLMTrial() {
        glmTrialUsed = true
        defaults.set(true, forKey: Key.glmTrialUsed.rawValue)
    }
}
