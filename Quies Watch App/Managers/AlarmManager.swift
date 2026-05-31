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

@MainActor
@Observable class AlarmManager: NSObject, WKExtendedRuntimeSessionDelegate {
    
    // MARK: - Published State
    var currentMode: AppMode = .idle
    var statusMessage: String = "Ready"
    var timerString: String = "--:--"
    var targetWakeTime: Date?
    
    // MARK: - Dependencies
    private var bioSensors = BioSensors()
    private var session: WKExtendedRuntimeSession?
    
    // MARK: - Modern Concurrency
    private var timerTask: Task<Void, Never>?
    private var hapticTask: Task<Void, Never>?
    
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
        startTimerTask()
    }
    
    func stop() {
        session?.invalidate()
        session = nil
        
        cancelBackupNotification()
        bioSensors.stopMonitoring()
        
        timerTask?.cancel()
        timerTask = nil
        
        stopAlarmSequence()
        
        self.currentMode = .idle
        self.statusMessage = "Ready"
        self.timerString = "--:--"
        self.targetWakeTime = nil
    }
    
    // MARK: - Extended Runtime Session
    private func startExtendedSession(at date: Date) {
        if session != nil { session?.invalidate(); session = nil }
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start(at: date)
    }
    
    nonisolated func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.bioSensors.startMonitoring()
            self.statusMessage = "Scanning Sleep..."
        }
    }
    
    nonisolated func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.triggerTotalAlarm(reason: "Session Expired")
        }
    }
    
    nonisolated func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        Task { @MainActor in
            self.stop()
        }
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
    
    // MARK: - Timer Task
    private func startTimerTask() {
        timerTask?.cancel()
        
        timerTask = Task {
            while !Task.isCancelled {
                guard let wakeTime = self.targetWakeTime else { break }
                
                let timeLeft = wakeTime.timeIntervalSince(Date())
                self.formatTimer(timeLeft: timeLeft)
                
                if timeLeft <= 0 {
                    self.triggerTotalAlarm(reason: "Time's Up")
                    break
                }
                
                if timeLeft <= self.smartWindowSeconds {
                    if self.bioSensors.movementScore > 0.10 {
                        self.triggerTotalAlarm(reason: "Light Sleep Detected")
                        break
                    }
                }
                
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    // MARK: - Total Alarm (Haptic Loop)
    private func triggerTotalAlarm(reason: String) {
        guard hapticTask == nil else { return }
        
        self.statusMessage = "WAKE UP! (\(reason))"
        timerTask?.cancel()
        
        startHapticLoop()
    }
    
    private func stopAlarmSequence() {
        hapticTask?.cancel()
        hapticTask = nil
    }
    
    private func startHapticLoop() {
        hapticTask?.cancel()
        
        hapticTask = Task {
            WKInterfaceDevice.current().play(.failure)
            
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.5))
                
                WKInterfaceDevice.current().play(.failure)
                
                try? await Task.sleep(for: .milliseconds(200))
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
