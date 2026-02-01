import SwiftUI

@main
struct QuiesApp: App {
    @StateObject private var watchConnection = WatchConnectionManager()
    @StateObject private var alarmKitManager = AlarmKitManager()
    @StateObject private var notificationManager = NotificationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environmentObject(watchConnection)
            .environmentObject(alarmKitManager)
            .environmentObject(notificationManager)
            .task {
                await notificationManager.requestAuthorization()
            }
        }
    }
}
