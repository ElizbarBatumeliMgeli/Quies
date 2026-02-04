//
//  AlarmManager.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 05/01/26.
//

import Foundation
import WatchKit
import UserNotifications

enum AppMode {
    case idle
    case napping
    case smartAlarm
}

@Observable class AlarmManager: NSObject, WKExtendedRuntimeSessionDelegate {
    
    // MARK: - Published State
    var currentMode: AppMode = .idle
    var statusMessage: String = "Ready"
    var timerString: String = "--:--"
    var targetWakeTime: Date?
    
    // MARK: - Dependencies
    private var bioSensors = BioSensors()
    private var timer: Timer?
    private var session: WKExtendedRuntimeSession?
    
    private var hapticTimer: Timer?
    
    // MARK: - Configuration
    private let smartWindowSeconds: TimeInterval = 30 * 60 // 30 Minutes
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
        self.statusMessage = "Session Active"
        
        let windowStart = wakeTime.addingTimeInterval(-smartWindowSeconds)
        
        if windowStart < Date() {
            startExtendedSession(at: Date())
            bioSensors.startMonitoring()
        } else {
            startExtendedSession(at: windowStart)
        }
        
        scheduleBackupNotification(at: wakeTime)
        startTimerLoop()
    }
    
    func stop() {
        print("Stopping Alarm Manager")
        session?.invalidate()
        session = nil
        
        cancelBackupNotification()
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
    
    // MARK: - Extended Runtime Session
    private func startExtendedSession(at date: Date) {
        if session != nil { session?.invalidate(); session = nil }
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start(at: date)
    }
    
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.bioSensors.startMonitoring()
            self.statusMessage = "Scanning Sleep..."
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        triggerTotalAlarm(reason: "Session Expired")
    }
    
    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        stop()
    }

    // MARK: - Backup Notification
    private func scheduleBackupNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "NapGuard Backup Alarm"
        content.sound = UNNotificationSound.default
        
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "BACKUP_ALARM", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    private func cancelBackupNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["BACKUP_ALARM"])
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
                if self.bioSensors.movementScore > 0.10 {
                    self.triggerTotalAlarm(reason: "Light Sleep Detected")
                }
            }
        }
    }
    
    // MARK: - ðŸš¨ TOTAL ALARM (Haptic Loop Only) ðŸš¨
    private func triggerTotalAlarm(reason: String) {
        guard hapticTimer == nil else { return }
        
        self.statusMessage = "WAKE UP! (\(reason))"
        timer?.invalidate()
        
        print("ðŸš¨ TOTAL ALARM TRIGGERED (Haptic) ðŸš¨")
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
