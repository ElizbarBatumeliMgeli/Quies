import SwiftUI

struct SmartAlarmView: View {
    @EnvironmentObject var watchConnection: WatchConnectionManager
    @EnvironmentObject var alarmKitManager: AlarmKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var selectedTime = Date()
    @State private var showingTimePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                if let currentAlarm = alarmKitManager.currentAlarm,
                   currentAlarm.mode == .smartAlarm {
                    activeAlarmView(alarm: currentAlarm)
                } else {
                    alarmSetupView
                }
            }
            .navigationTitle("Smart Alarm")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, .orange.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var alarmSetupView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.variableColor)
                
                Text("Smart Wake")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Wake during light sleep")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 20) {
                Text("Set Wake Time")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Button(action: { showingTimePicker = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                        
                        Text(selectedTime, style: .time)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Text("Alarm window: 30 min before")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { setSmartAlarm() }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Set Smart Alarm")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }
    
    private func activeAlarmView(alarm: AlarmData) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 8) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.variableColor.iterative)
                    
                    Text(alarm.wakeTime, style: .time)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Smart Alarm Active")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake Window")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(alarm.wakeTime.addingTimeInterval(-1800), style: .time)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target Time")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(alarm.wakeTime, style: .time)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 32)
                
                Text("Monitoring sleep phases")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { stopAlarm() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel Alarm")
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
    
    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Set Wake Time")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    DatePicker(
                        "Wake Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    
                    Button(action: {
                        showingTimePicker = false
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 32)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func setSmartAlarm() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        targetComponents.hour = components.hour
        targetComponents.minute = components.minute
        
        var targetDate = calendar.date(from: targetComponents) ?? Date()
        
        if targetDate <= Date() {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }
        
        let alarm = AlarmData(
            wakeTime: targetDate,
            mode: .smartAlarm,
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
}
