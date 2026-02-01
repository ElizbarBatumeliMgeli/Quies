import SwiftUI

struct NapView: View {
    @EnvironmentObject var watchConnection: WatchConnectionManager
    @EnvironmentObject var alarmKitManager: AlarmKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var history = AlarmHistory()
    
    @State private var showingActiveAlarm = false
    
    private let napDurations: [(hours: Double, label: String)] = [
        (1.0, "1"),
        (1.5, "1.5"),
        (2.0, "2"),
        (2.5, "2.5")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                if let currentAlarm = alarmKitManager.currentAlarm,
                   currentAlarm.mode == .nap {
                    activeAlarmView(alarm: currentAlarm)
                } else {
                    napSelectionView
                }
            }
            .navigationTitle("Quick Naps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, .indigo.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var napSelectionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Power Naps")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Quick recharge sessions")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(napDurations, id: \.hours) { duration in
                    NapButton(
                        hours: duration.hours,
                        label: duration.label,
                        action: { startNap(duration: duration.hours) }
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            watchStatusBanner
        }
    }
    
    private func activeAlarmView(alarm: AlarmData) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(timeRemaining(to: alarm.wakeTime))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Nap Active")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 12) {
                Text("Wake Time")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(alarm.wakeTime, style: .time)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: { stopAlarm() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Stop Nap")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red.opacity(0.2))
                .foregroundColor(.red)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }
    
    private var watchStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: watchConnection.isWatchReachable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(watchConnection.isWatchReachable ? .green : .orange)
            
            Text(watchConnection.isWatchReachable ? "Watch Connected" : "Watch Disconnected")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 8)
    }
    
    private func startNap(duration: Double) {
        let wakeTime = Date().addingTimeInterval(duration * 3600)
        let alarm = AlarmData(
            wakeTime: wakeTime,
            mode: .nap,
            isActive: true
        )
        
        Task {
            do {
                try await alarmKitManager.scheduleAlarm(alarm)
                await notificationManager.scheduleBackupAlarm(for: alarm)
                watchConnection.sendAlarmToWatch(alarm)
                watchConnection.updateContext(alarm: alarm)
            } catch {
                print("Failed to schedule alarm: \(error)")
            }
        }
    }
    
    private func stopAlarm() {
        Task {
            await alarmKitManager.cancelAlarm()
            if let alarm = alarmKitManager.currentAlarm {
                await notificationManager.cancelBackupAlarm(id: alarm.id)
            }
            watchConnection.stopAlarmOnWatch()
            watchConnection.updateContext(alarm: nil)
        }
    }
    
    private func timeRemaining(to date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        guard remaining > 0 else { return "00:00:00" }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        let seconds = Int(remaining) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
