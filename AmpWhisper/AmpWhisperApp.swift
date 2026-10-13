import SwiftUI
import SwiftData

@main
struct AmpWhisperApp: App {
    let container: ModelContainer

    init() {
        AppTheme.apply()
        if let created = try? ModelContainer(for: Rig.self, MatchHistory.self) {
            container = created
        } else {
            container = try! ModelContainer(
                for: Rig.self, MatchHistory.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
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
