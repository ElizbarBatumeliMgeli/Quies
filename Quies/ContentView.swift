import SwiftUI

struct ContentView: View {
    @EnvironmentObject var watchConnection: WatchConnectionManager
    @EnvironmentObject var alarmKitManager: AlarmKitManager
    @State private var showingWatchNotConnected = false
    
    var body: some View {
        Group {
            if watchConnection.isWatchPaired && watchConnection.isWatchAppInstalled {
                MainTabView()
            } else {
                WatchConnectionView()
            }
        }
        .onAppear {
            showingWatchNotConnected = !watchConnection.isWatchPaired || !watchConnection.isWatchAppInstalled
        }
    }
}

struct WatchConnectionView: View {
    @EnvironmentObject var watchConnection: WatchConnectionManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "applewatch.watchface")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
                
                VStack(spacing: 12) {
                    Text(connectionStatusTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(connectionStatusMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if !watchConnection.isWatchPaired {
                    VStack(spacing: 16) {
                        Label("Pair Apple Watch", systemImage: "1.circle.fill")
                            .foregroundColor(.blue)
                        
                        Label("Open Watch app", systemImage: "2.circle.fill")
                            .foregroundColor(.blue)
                        
                        Label("Install Quies", systemImage: "3.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .font(.system(.callout, design: .rounded))
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var connectionStatusTitle: String {
        if !watchConnection.isWatchPaired {
            return "Apple Watch Not Paired"
        } else if !watchConnection.isWatchAppInstalled {
            return "Install Quies on Watch"
        } else {
            return "Connecting..."
        }
    }
    
    private var connectionStatusMessage: String {
        if !watchConnection.isWatchPaired {
            return "Please pair your Apple Watch with your iPhone using the Watch app to continue."
        } else if !watchConnection.isWatchAppInstalled {
            return "Open the Watch app and install Quies on your Apple Watch to enable sleep monitoring."
        } else {
            return "Establishing connection with your Apple Watch..."
        }
    }
}
