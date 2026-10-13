import SwiftUI
import SwiftData

@main
struct AmpWhisperApp: App {
    let container: ModelContainer

    init() {
        AppTheme.apply()
        do {
            container = try ModelContainer(for: Rig.self, MatchHistory.self)
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .tint(.amber)
        }
    }
}

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false

    var body: some View {
        if onboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "music.note.house.fill") }
            RigView()
                .tabItem { Label("My Rig", systemImage: "guitars.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.amber)
    }
}
