import Foundation
import SwiftUI
import Combine
import AlarmKit
import AppIntents
import ActivityKit // Required for LiveActivityIntent

// 1. Define a concrete Metadata type.
// The compiler requires this to know what 'T' is in AlarmAttributes<T>, even if it's nil.
struct QuiesMetadata: AlarmMetadata, Codable {
    // Leave empty if you don't need to pass data to widgets yet
}

@MainActor
class AlarmKitManager: ObservableObject {
    @Published var currentAlarm: AlarmData?
    @Published var isAlarmActive = false
    
    private var currentAlarmID: UUID?
    private let manager = AlarmManager.shared
    
    init() {
        Task {
            await monitorAlarmUpdates()
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            return state == .authorized
        } catch {
            print("AlarmKit Authorization Error: \(error)")
            return false
        }
    }
    
    func scheduleAlarm(_ alarm: AlarmData) async throws {
        let id = UUID()
        let schedule = Alarm.Schedule.fixed(alarm.wakeTime)
        
        let titleString = alarm.mode == .nap ? "Quies Nap" : "Quies Smart Alarm"
        
        // 2. Fix: Create AlarmPresentation with explicit Button init and LocalizedStringResource
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                // Error Fix: Convert String to LocalizedStringResource
                title: LocalizedStringResource(stringLiteral: titleString),
                // Error Fix: .stopButton static var doesn't exist; initialize manually
                stopButton: AlarmButton(text: "Stop",textColor: .black ,systemImageName: "stop.circle.fill"),
                secondaryButton: nil,
                secondaryButtonBehavior: nil
            )
        )
        
        // 3. Fix: Explicitly specialize with <QuiesMetadata> to fix "Generic parameter inference" error
        let attributes = AlarmAttributes<QuiesMetadata>(
            presentation: presentation,
            metadata: nil,
            tintColor: .cyan
        )
        
        // 4. Fix: Explicitly specialize Configuration and use correct Intent
        let configuration = AlarmManager.AlarmConfiguration<QuiesMetadata>(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopIntent(alarmID: id.uuidString)
        )
        
        // Schedule the alarm
        _ = try await manager.schedule(id: id, configuration: configuration)
        
        // Update local state
        self.currentAlarmID = id
        self.currentAlarm = alarm
        self.isAlarmActive = true
    }
    
    func cancelAlarm() async {
        guard let id = currentAlarmID else { return }
        
        do {
            try await manager.cancel(id: id)
            self.currentAlarmID = nil
            self.currentAlarm = nil
            self.isAlarmActive = false
        } catch {
            print("Error cancelling alarm: \(error)")
        }
    }
    
    private func monitorAlarmUpdates() async {
        // Listen for system updates (e.g. if the user stops the alarm from the Lock Screen)
        for await incomingAlarms in manager.alarmUpdates {
            if let currentID = currentAlarmID {
                let isStillScheduled = incomingAlarms.contains(where: { $0.id == currentID })
                if !isStillScheduled {
                    self.isAlarmActive = false
                    self.currentAlarm = nil
                    self.currentAlarmID = nil
                }
            }
        }
    }
}

// 5. Fix: Change AppIntent to LiveActivityIntent
// This fixes the "argument type does not conform" error in your screenshot.
struct StopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    init() {}
    init(alarmID: String) { self.alarmID = alarmID }
    
    func perform() async throws -> some IntentResult {
        // The system handles the audio stop.
        return .result()
    }
}
