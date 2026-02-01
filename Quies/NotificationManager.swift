
import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func requestAuthorization() async {
        do {
            isAuthorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            if isAuthorized {
                await registerCategories()
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }
    
    func checkAuthorization() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    func scheduleBackupAlarm(for alarm: AlarmData) async {
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = alarm.mode == .nap ? "Your nap time is over" : "Time to wake up"
        content.sound = .default
        content.categoryIdentifier = "ALARM"
        
        let timeInterval = alarm.wakeTime.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func cancelBackupAlarm(id: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id.uuidString]
        )
    }
    
    private func registerCategories() async {
        let stopAction = UNNotificationAction(
            identifier: "STOP_ALARM",
            title: "Stop",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ALARM",
            title: "Snooze",
            options: []
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM",
            actions: [stopAction, snoozeAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}
