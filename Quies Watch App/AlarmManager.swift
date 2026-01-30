//
//  AlarmManager.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 05/01/26.
//

import Combine
import Foundation
import WatchKit
import UserNotifications

enum AppMode {
    case idle
    case napping
    case smartAlarm
}

class AlarmManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    
    // MARK: - Published State
    @Published var currentMode: AppMode = .idle
    @Published var statusMessage: String = "Ready"
    @Published var timerString: String = "--:--"
    @Published var targetWakeTime: Date?
    
    // MARK: - Dependencies
    private var bioSensors = BioSensors()
    private var widgetManager = WidgetManager()
    private var timer: Timer?
    private var session: WKExtendedRuntimeSession?
    private var hapticTimer: Timer?
    private var keepAliveTimer: Timer?
    
    // MARK: - Configuration
    private let smartWindowSeconds: TimeInterval = 30 * 60
    private var startTime: Date?
    
    // MARK: - Feature 1: Naps
    func startNap(duration: TimeInterval) {
        let now = Date()
        let wakeTime = now.addingTimeInterval(duration)
        self.startTime = now
        activateAlarm(mode: .napping, wakeTime: wakeTime)
    }
    
    // MARK: - Feature 2: Smart Alarm
    func setSmartAlarm(at date: Date) {
        let now = Date()
        let calendar = Calendar.current
        
        let userComponents = calendar.dateComponents([.hour, .minute], from: date)
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        targetComponents.hour = userComponents.hour
        targetComponents.minute = userComponents.minute
        targetComponents.second = 0
        
        var targetDate = calendar.date(from: targetComponents) ?? now
        
        if targetDate <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }
        
        self.startTime = now
        activateAlarm(mode: .smartAlarm, wakeTime: targetDate)
    }
    
    // MARK: - Activation Logic
    private func activateAlarm(mode: AppMode, wakeTime: Date) {
        self.currentMode = mode
        self.targetWakeTime = wakeTime
        self.statusMessage = "Alarm Set"
        
        let windowStart = wakeTime.addingTimeInterval(-smartWindowSeconds)
        let now = Date()
        
        widgetManager.updateWidget(wakeTime: wakeTime, mode: mode, isActive: true)
        
        if windowStart <= now {
            startExtendedSession(at: now)
            bioSensors.startMonitoring()
            self.statusMessage = "Scanning Sleep..."
        } else {
            scheduleBackgroundTask(for: windowStart)
            scheduleWakeNotification(at: windowStart)
            startKeepAliveTimer()
        }
        
        scheduleBackupNotification(at: wakeTime)
        startTimerLoop()
    }
    
    func stop() {
        print("Stopping Alarm Manager")
        session?.invalidate()
        session = nil
        
        cancelBackupNotification()
        cancelWakeNotification()
        cancelBackgroundTask()
        stopKeepAliveTimer()
        widgetManager.clearWidget()
        bioSensors.stopMonitoring()
        timer?.invalidate()
        stopAlarmSequence()
        
        DispatchQueue.main.async {
            self.currentMode = .idle
            self.statusMessage = "Ready"
            self.timerString = "--:--"
            self.targetWakeTime = nil
        }
    }
    
    // MARK: - Background Task Scheduling
    private func scheduleBackgroundTask(for date: Date) {
        let bufferTime: TimeInterval = 5 * 60
        let taskDate = date.addingTimeInterval(-bufferTime)
        
        if taskDate > Date() {
            let userInfo = NSDictionary(dictionary: ["wakeTime": date.timeIntervalSince1970])
            
            WKApplication.shared().scheduleBackgroundRefresh(
                withPreferredDate: taskDate,
                userInfo: userInfo
            ) { error in
                if let error = error {
                    print("Failed to schedule background task: \(error)")
                } else {
                    print("✅ Background task scheduled for \(taskDate.formatted(date: .omitted, time: .shortened))")
                }
            }
        }
    }
    
    private func cancelBackgroundTask() {
        print("Background task cancelled")
    }
    
    // MARK: - Handle Background Task
    func handleBackgroundTask(task: WKApplicationRefreshBackgroundTask) {
        print("🔄 Background task fired!")
        
        guard let wakeTime = targetWakeTime else {
            task.setTaskCompletedWithSnapshot(false)
            return
        }
        
        let windowStart = wakeTime.addingTimeInterval(-smartWindowSeconds)
        
        if Date() >= windowStart {
            print("✅ Starting extended session from background task")
            startExtendedSession(at: Date())
            bioSensors.startMonitoring()
            self.statusMessage = "Scanning Sleep..."
        }
        
        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: - Wake Notification
    private func scheduleWakeNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Quies"
        content.body = "Sleep tracking starting"
        content.sound = nil
        content.categoryIdentifier = "QUIES_WAKE"
        
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "WAKE_NOTIFICATION", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule wake notification: \(error)")
            } else {
                print("✅ Wake notification scheduled for \(date.formatted(date: .omitted, time: .shortened))")
            }
        }
    }
    
    private func cancelWakeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WAKE_NOTIFICATION"])
    }
    
    // MARK: - Keep Alive Timer
    private func startKeepAliveTimer() {
        stopKeepAliveTimer()
        
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 60.0 * 60.0, repeats: true) { [weak self] _ in
            guard let self = self, let wakeTime = self.targetWakeTime else { return }
            
            print("⏰ Keep-alive tick")
            
            self.widgetManager.updateWidget(wakeTime: wakeTime, mode: self.currentMode, isActive: true)
            
            let windowStart = wakeTime.addingTimeInterval(-self.smartWindowSeconds)
            if Date() >= windowStart && self.session == nil {
                print("✅ Starting extended session from keep-alive")
                self.startExtendedSession(at: Date())
                self.bioSensors.startMonitoring()
                self.statusMessage = "Scanning Sleep..."
            }
        }
        
        print("✅ Keep-alive timer started (updates every hour)")
    }
    
    private func stopKeepAliveTimer() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    // MARK: - Extended Runtime Session
    private func startExtendedSession(at date: Date) {
        if session != nil { session?.invalidate(); session = nil }
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start(at: date)
        stopKeepAliveTimer()
    }
    
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.bioSensors.startMonitoring()
            self.statusMessage = "Scanning Sleep..."
        }
        print("✅ Extended runtime session started")
    }
    
    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session expiring")
        triggerTotalAlarm(reason: "Session Expired")
    }
    
    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("❌ Extended runtime session invalidated: \(reason)")
        stop()
    }

    // MARK: - Backup Notification
    private func scheduleBackupNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Quies Backup Alarm"
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "QUIES_ALARM"
        content.interruptionLevel = .timeSensitive
        
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 {
            print("⚠️ Cannot schedule notification in the past")
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "BACKUP_ALARM", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule backup alarm: \(error)")
            } else {
                print("✅ Backup alarm scheduled for \(date.formatted(date: .omitted, time: .shortened))")
                self.debugNotifications()
            }
        }
    }
    
    private func cancelBackupNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["BACKUP_ALARM"])
    }
    
    // MARK: - Debug Notifications
    private func debugNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📬 Pending notifications: \(requests.count)")
            for request in requests {
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    let fireDate = Date().addingTimeInterval(trigger.timeInterval)
                    print("   - \(request.identifier): fires at \(fireDate.formatted(date: .omitted, time: .shortened))")
                } else {
                    print("   - \(request.identifier): trigger type \(type(of: request.trigger))")
                }
            }
        }
    }
    
    // MARK: - Timer Loop
    private func startTimerLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let wakeTime = self.targetWakeTime else { return }
            
            let timeLeft = wakeTime.timeIntervalSince(Date())
            self.formatTimer(timeLeft: timeLeft)
            
            if timeLeft <= 0 {
                self.triggerTotalAlarm(reason: "Time's Up")
                return
            }
            
            if timeLeft <= self.smartWindowSeconds {
                if self.bioSensors.movementScore > 0.15 {
                    self.triggerTotalAlarm(reason: "Light Sleep Detected")
                }
            }
        }
    }
    
    // MARK: - Total Alarm
    private func triggerTotalAlarm(reason: String) {
        guard hapticTimer == nil else { return }
        
        self.statusMessage = "WAKE UP! (\(reason))"
        timer?.invalidate()
        
        print("🚨 TOTAL ALARM TRIGGERED (Haptic) 🚨")
        startHapticLoop()
    }
    
    private func stopAlarmSequence() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
    
    private func startHapticLoop() {
        hapticTimer?.invalidate()
        
        WKInterfaceDevice.current().play(.failure)
        
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            WKInterfaceDevice.current().play(.failure)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
    
    private func formatTimer(timeLeft: TimeInterval) {
        if timeLeft > 0 {
            let h = Int(timeLeft) / 3600
            let m = Int(timeLeft) / 60 % 60
            let s = Int(timeLeft) % 60
            self.timerString = String(format: "%02i:%02i:%02i", h, m, s)
        } else {
            self.timerString = "00:00:00"
        }
    }
}
