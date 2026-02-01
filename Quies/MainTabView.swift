import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            NapView()
                .tabItem {
                    Label("Nap", systemImage: "moon.zzz.fill")
                }
                .tag(0)
            
            SmartAlarmView()
                .tabItem {
                    Label("Alarm", systemImage: "alarm.fill")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
            
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
