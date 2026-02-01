
import Foundation
import WatchConnectivity
import SwiftUI
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var receivedAlarm: AlarmData?
    
    private var session: WCSession?
    var alarmManager: AlarmManager?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendAlarmTriggered(_ alarm: AlarmData) {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = [
            "action": "alarmTriggered",
            "alarm": alarm.toDictionary()
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Error sending to iPhone: \(error.localizedDescription)")
        })
    }
    
    func sendAlarmStopped() {
        guard let session = session, session.isReachable else { return }
        
        let message = ["action": "alarmStopped"]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated")
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let action = message["action"] as? String {
                switch action {
                case "setAlarm":
                    if let alarmDict = message["alarm"] as? [String: Any],
                       let alarm = AlarmData.fromDictionary(alarmDict) {
                        handleSetAlarm(alarm)
                    }
                case "stopAlarm":
                    alarmManager?.stop()
                case "wakeUp":
                    print("Wake up request from iPhone")
                default:
                    break
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let alarmDict = applicationContext["currentAlarm"] as? [String: Any],
               let alarm = AlarmData.fromDictionary(alarmDict) {
                receivedAlarm = alarm
            } else {
                receivedAlarm = nil
            }
        }
    }
    
    private func handleSetAlarm(_ alarm: AlarmData) {
        guard let alarmManager = alarmManager else { return }
        
        switch alarm.mode {
        case .nap:
            if let duration = alarm.napDuration {
                alarmManager.startNap(duration: duration)
            }
        case .smartAlarm:
            alarmManager.setSmartAlarm(at: alarm.wakeTime)
        }
    }
}
