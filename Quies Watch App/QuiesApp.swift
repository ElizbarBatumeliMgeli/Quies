//
//  QuiesApp.swift
//  Quies Watch App
//
//  Created by Elizbar Kheladze on 22/01/26.
//

import SwiftUI
import WatchKit
import UserNotifications

@main
struct Quies_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        appDelegate.requestNotificationPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions()
    }
    
    // MARK: - Request Notification Permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print("⚠️ Notification permissions denied by user")
            }
        }
    }
    
    // MARK: - Handle Background Tasks
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                handleAppRefresh(refreshTask)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    private func handleAppRefresh(_ task: WKApplicationRefreshBackgroundTask) {
        NotificationCenter.default.post(name: NSNotification.Name("HandleBackgroundTask"), object: task)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    // MARK: - Notification Delegate Methods
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Notification received while app is foreground: \(notification.request.identifier)")
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📬 Notification tapped: \(response.notification.request.identifier)")
        
        if response.notification.request.identifier == "BACKUP_ALARM" {
            NotificationCenter.default.post(name: NSNotification.Name("WakeUpFromNotification"), object: nil)
        }
        
        completionHandler()
    }
}
