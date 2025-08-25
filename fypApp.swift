import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct fypApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var moodStore = MoodStore()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                NavigationView {
                    TabView {
                        ContentView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                        StatsView()
                            .tabItem {
                                Label("Stats", systemImage: "chart.bar.xaxis")
                            }
                        CalendarView()
                            .tabItem {
                                Label("Calendar", systemImage: "calendar")
                            }
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                    }
                    .accentColor(.purple)
                    .environmentObject(moodStore)
                }
            } else {
                AuthView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
